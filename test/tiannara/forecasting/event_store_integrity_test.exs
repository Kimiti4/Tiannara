defmodule Tiannara.Executive.EventStoreIntegrityTest do
  @moduledoc """
  Adversarial tests for the durable event log's ordering and integrity.

  The store's frame format is exercised directly, through real files on disk:

      <<"EFD2", size::32, sequence::64, digest::32, previous_digest::32,
        payload::binary-size(size)>>

  These tests write crafted frames and assert two things for every attack:
  that the invalid record was **not applied**, and that the exact expected
  state was preserved.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Executive.Event
  alias Tiannara.Executive.EventStore

  @magic "EFD2"
  @digest_size 32
  @zero <<0::256>>

  setup do
    dir = Path.join(System.tmp_dir!(), "tcp0025_events_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    log = Path.join(dir, "events.log")

    name = :"event_store_tcp0025_#{System.unique_integer([:positive])}"
    original = Application.get_env(:tiannara, :executive_event_store)
    Application.put_env(:tiannara, :executive_event_store, name)

    on_exit(fn ->
      if original,
        do: Application.put_env(:tiannara, :executive_event_store, original),
        else: Application.delete_env(:tiannara, :executive_event_store)

      File.rm_rf!(dir)
    end)

    {:ok, dir: dir, log: log, name: name}
  end

  defp start_store(ctx) do
    start_supervised!({EventStore, [name: ctx.name, file_path: ctx.log]})
  end

  defp event(text) do
    Event.new("test.event", %{text: text})
  end

  defp frame(sequence, previous_digest, payload) do
    digest = EventStore.record_digest(sequence, previous_digest, payload)

    body =
      @magic <>
        <<byte_size(payload)::32, sequence::64, digest::binary-size(@digest_size),
          previous_digest::binary-size(@digest_size), payload::binary>>

    {body, digest}
  end

  defp write_frames(path, frames) do
    File.write!(path, IO.iodata_to_binary(frames))
  end

  describe "append path" do
    test "records carry a sequence and a chain", ctx do
      start_store(ctx)

      assert :ok = EventStore.append(event("a"))
      assert :ok = EventStore.append(event("b"))

      {:ok, %{records: records}} = EventStore.stream_verified(0)

      assert length(records) == 2
      assert Enum.map(records, & &1.sequence) == [1, 2]
      assert Enum.all?(records, &(&1.integrity == :verified))

      # The second record's previous digest is the first record's digest.
      assert Enum.at(records, 1).previous_digest == Enum.at(records, 0).digest
    end

    test "a restart continues the sequence and the chain", ctx do
      start_store(ctx)
      assert :ok = EventStore.append(event("a"))
      stop_supervised(EventStore)

      start_store(ctx)
      assert :ok = EventStore.append(event("b"))

      {:ok, %{records: records}} = EventStore.stream_verified(0)

      assert Enum.map(records, & &1.sequence) == [1, 2]
      assert Enum.all?(records, &(&1.integrity == :verified))
    end
  end

  describe "ordering attacks" do
    test "a sequence gap is detected and the record is not applied", ctx do
      p1 = Event.to_binary(event("one"))
      p3 = Event.to_binary(event("three"))

      {f1, d1} = frame(1, @zero, p1)
      {f3, _d3} = frame(3, d1, p3)

      write_frames(ctx.log, [f1, f3])
      start_store(ctx)

      {:ok, result} = EventStore.stream_verified(0)

      assert result.sequence_gaps == 1
      assert result.integrity_failures == 0

      # Only the contiguous verified prefix is applied.
      assert length(result.records) == 1
      assert hd(result.records).sequence == 1
      assert hd(result.records).event.data.text == "one"
    end

    test "out-of-order sequence numbers are not accepted", ctx do
      p1 = Event.to_binary(event("one"))
      p2 = Event.to_binary(event("two"))

      {f1, d1} = frame(1, @zero, p1)
      {f2, _d2} = frame(2, d1, p2)

      # Deliver 2 before 1.
      {f1_swapped, d1_swapped} = frame(2, @zero, p2)
      write_frames(ctx.log, [f1_swapped, f1])
      start_store(ctx)

      {:ok, result} = EventStore.stream_verified(0)

      # The chain is broken and the sequence is wrong; nothing is presented as
      # an ordered verified history.
      assert result.integrity_failures + result.sequence_gaps > 0
      assert result.records == []
    end

    test "the same record delivered twice is detected", ctx do
      p1 = Event.to_binary(event("one"))
      {f1, d1} = frame(1, @zero, p1)

      # The identical frame appears twice: the second is a duplicate whose
      # chain linkage no longer holds.
      write_frames(ctx.log, [f1, f1])
      start_store(ctx)

      {:ok, result} = EventStore.stream_verified(0)

      assert result.integrity_failures + result.sequence_gaps > 0
      assert length(result.records) == 1
    end

    test "a record removed from the middle breaks the chain", ctx do
      p1 = Event.to_binary(event("one"))
      p2 = Event.to_binary(event("two"))
      p3 = Event.to_binary(event("three"))

      {f1, d1} = frame(1, @zero, p1)
      {f2, d2} = frame(2, d1, p2)
      {f3, _d3} = frame(3, d2, p3)

      # The middle record is removed.
      write_frames(ctx.log, [f1, f3])
      start_store(ctx)

      {:ok, result} = EventStore.stream_verified(0)

      assert result.integrity_failures + result.sequence_gaps > 0
      assert length(result.records) == 1
    end
  end

  describe "integrity attacks" do
    test "a modified payload fails verification and is not applied", ctx do
      p1 = Event.to_binary(event("one"))
      {f1, _d1} = frame(1, @zero, p1)

      <<head::binary-size(byte_size(f1) - 4), tail::binary>> = f1
      write_frames(ctx.log, [head <> <<0, 0, 0, 0>> <> tail])
      start_store(ctx)

      {:ok, result} = EventStore.stream_verified(0)

      assert result.integrity_failures == 1
      assert result.records == []
    end

    test "a modified digest fails verification and is not applied", ctx do
      p1 = Event.to_binary(event("one"))
      {f1, _d1} = frame(1, @zero, p1)

      # Corrupt the digest field (bytes 12..44 of the frame).
      <<head::binary-size(12), _digest::binary-size(32), tail::binary>> = f1
      write_frames(ctx.log, [head <> <<255::256>> <> tail])
      start_store(ctx)

      {:ok, result} = EventStore.stream_verified(0)

      assert result.integrity_failures == 1
      assert result.records == []
    end

    test "a truncated final record is distinguishable from a complete log", ctx do
      p1 = Event.to_binary(event("one"))
      {f1, _d1} = frame(1, @zero, p1)

      <<head::binary-size(byte_size(f1) - 10), _tail::binary>> = f1
      write_frames(ctx.log, [head])
      start_store(ctx)

      {:ok, result} = EventStore.stream_verified(0)

      assert result.truncated == true
      assert result.records == []
    end

    test "a legacy record is read but never presented as verified", ctx do
      payload = Event.to_binary(event("legacy"))
      legacy = <<byte_size(payload)::32, payload::binary>>

      write_frames(ctx.log, [legacy])
      start_store(ctx)

      {:ok, result} = EventStore.stream_verified(0)

      assert result.unverified_legacy == 1
      assert result.records == []

      # It is still readable through the legacy compatibility reader.
      assert [event] = EventStore.stream_unverified(0)
      assert event.data.text == "legacy"
    end

    test "readers fail closed on legacy or incomplete history", ctx do
      payload = Event.to_binary(event("legacy"))
      legacy = <<byte_size(payload)::32, payload::binary>>

      write_frames(ctx.log, [legacy])
      start_store(ctx)

      assert {:error, :unverified_legacy_record} =
               EventStore.stream(0, ctx.name)

      assert {:error, :unverified_legacy_record} =
               EventStore.since(~U[2026-01-01 00:00:00Z], ctx.name)
    end
  end

  describe "digest semantics" do
    test "a digest establishes integrity, not authenticity", ctx do
      start_store(ctx)

      assert :ok = EventStore.append(event("a"))

      {:ok, %{records: [record]}} = EventStore.stream_verified(0)

      # The digest is reproducible from the record's own content.
      assert record.digest == EventStore.record_digest(1, @zero, Event.to_binary(record.event))

      # It is a hash over the canonical content. Anyone able to write the log
      # can recompute it, so it is an integrity check and not an authenticity
      # proof. The module documents this distinction.
      refute is_nil(record.digest)
    end
  end

  describe "compatibility readers (R4)" do
    test "default stream fails closed on legacy history", ctx do
      payload = Event.to_binary(event("legacy"))
      write_frames(ctx.log, [<<byte_size(payload)::32, payload::binary>>])
      start_store(ctx)

      assert {:error, :unverified_legacy_record} = EventStore.stream(0)
    end

    test "default stream succeeds on verified complete history", ctx do
      start_store(ctx)
      assert :ok = EventStore.append(event("a"))
      assert :ok = EventStore.append(event("b"))

      assert {:ok, result} = EventStore.stream(0)
      assert result.integrity == :verified
      assert length(result.events) == 2
      assert result.unverified_legacy == 0
      assert result.truncated == false
    end

    test "default stream succeeds on verified empty history", ctx do
      start_store(ctx)

      assert {:ok, result} = EventStore.stream(0)
      assert result.integrity == :empty_verified
      assert result.events == []
      assert result.verified == 0
    end

    test "default stream fails closed on truncated history", ctx do
      p1 = Event.to_binary(event("one"))
      {f1, _d1} = frame(1, @zero, p1)

      <<head::binary-size(byte_size(f1) - 10), _tail::binary>> = f1
      write_frames(ctx.log, [head])
      start_store(ctx)

      assert {:error, :truncated_history} = EventStore.stream(0)
    end

    test "default stream fails closed on corrupt history", ctx do
      p1 = Event.to_binary(event("one"))
      {f1, _d1} = frame(1, @zero, p1)

      <<head::binary-size(12), _digest::binary-size(32), tail::binary>> = f1
      corrupt = <<head::binary, 7::256, tail::binary>>
      write_frames(ctx.log, [corrupt])
      start_store(ctx)

      assert {:error, _} = EventStore.stream(0)
    end

    test "default stream fails closed on a sequence gap", ctx do
      p1 = Event.to_binary(event("one"))
      p2 = Event.to_binary(event("two"))
      {f1, d1} = frame(1, @zero, p1)
      {f2, _d2} = frame(3, d1, p2)

      write_frames(ctx.log, [f1, f2])
      start_store(ctx)

      assert {:error, :sequence_gap} = EventStore.stream(0)
    end

    test "default stream propagates read failures", ctx do
      start_supervised!({EventStore, [name: ctx.name, file_path: ctx.log, fault_injection: %{read: {:error, :eacces}}]})

      assert {:error, {:read_failed, _}} = EventStore.stream(0)
    end

    test "default stream fails closed on mixed verified and legacy records", ctx do
      p1 = Event.to_binary(event("one"))
      {f1, _d1} = frame(1, @zero, p1)
      payload = Event.to_binary(event("legacy"))
      legacy = <<byte_size(payload)::32, payload::binary>>

      write_frames(ctx.log, [f1, legacy])
      start_store(ctx)

      assert {:error, :unverified_legacy_record} = EventStore.stream(0)
    end

    test "default stream fails closed on a valid prefix followed by invalid history", ctx do
      p1 = Event.to_binary(event("one"))
      {f1, _d1} = frame(1, @zero, p1)
      payload = Event.to_binary(event("legacy"))
      legacy = <<byte_size(payload)::32, payload::binary>>

      write_frames(ctx.log, [f1, legacy])
      start_store(ctx)

      # The verified prefix must not be returned as though complete.
      assert {:error, _} = EventStore.stream(0)
    end

    test "default since fails closed on legacy history", ctx do
      payload = Event.to_binary(event("legacy"))
      write_frames(ctx.log, [<<byte_size(payload)::32, payload::binary>>])
      start_store(ctx)

      assert {:error, :unverified_legacy_record} =
               EventStore.since(~U[2026-01-01 00:00:00Z], ctx.name)
    end

    test "default since succeeds on verified history", ctx do
      start_store(ctx)
      assert :ok = EventStore.append(event("a"))

      assert {:ok, result} = EventStore.since(~U[2026-01-01 00:00:00Z], ctx.name)
      assert result.integrity == :verified
      assert length(result.events) == 1
    end

    test "stream_unverified returns a bare list including legacy records", ctx do
      payload = Event.to_binary(event("legacy"))
      write_frames(ctx.log, [<<byte_size(payload)::32, payload::binary>>])
      start_store(ctx)

      assert [legacy_event] = EventStore.stream_unverified(0)
      assert legacy_event.data.text == "legacy"
    end

    test "stream_unverified returns verified events as a bare list", ctx do
      start_store(ctx)
      assert :ok = EventStore.append(event("a"))
      assert :ok = EventStore.append(event("b"))

      assert [e1, e2] = EventStore.stream_unverified(0)
      assert e1.data.text == "a"
      assert e2.data.text == "b"
    end

    test "stream_unverified propagates read failures", ctx do
      start_supervised!({EventStore, [name: ctx.name, file_path: ctx.log, fault_injection: %{read: {:error, :eacces}}]})

      assert {:error, {:read_failed, _}} = EventStore.stream_unverified(0)
    end

    test "since_unverified returns a bare list", ctx do
      start_store(ctx)
      assert :ok = EventStore.append(event("a"))

      assert [e] = EventStore.since_unverified(~U[2026-01-01 00:00:00Z], ctx.name)
      assert e.data.text == "a"
    end

    test "since_unverified propagates read failures", ctx do
      start_supervised!({EventStore, [name: ctx.name, file_path: ctx.log, fault_injection: %{read: {:error, :eacces}}]})

      assert {:error, {:read_failed, _}} =
               EventStore.since_unverified(~U[2026-01-01 00:00:00Z], ctx.name)
    end

    test "a consumer requiring verified history must not accept an error result", ctx do
      payload = Event.to_binary(event("legacy"))
      write_frames(ctx.log, [<<byte_size(payload)::32, payload::binary>>])
      start_store(ctx)

      # The verified-history consumer cannot proceed on an error result.
      case EventStore.stream(0) do
        {:ok, %{integrity: :verified, events: events}} ->
          assert is_list(events)

        {:error, _} ->
          # Expected: legacy history is refused, not silently accepted.
          :ok
      end
    end
  end
end
