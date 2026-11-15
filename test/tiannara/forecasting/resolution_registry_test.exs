defmodule Tiannara.Forecasting.ResolutionRegistryTest do
  @moduledoc """
  Adversarial recovery tests for TCP-002.7-R3.

  Every test uses an isolated EventStore instance, an isolated registry
  instance and a temporary file. Nothing here touches the application-wide
  durable log.

  The tests cover four contracts:

    * EventStore read failures never look like clean empty history;
    * uncertain write/sync failures poison the store and refuse appends;
    * registry recovery is transactional (candidate index, then publish);
    * lookups cannot claim durability from a degraded or stale index.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Executive.Event
  alias Tiannara.Executive.EventStore
  alias Tiannara.Forecasting.ResolutionRegistry

  @magic "EFD2"
  @digest_size 32
  @zero <<0::256>>
  @event_type "efdi.forecast.resolved"
  @index_key :__resolution_index__

  setup do
    dir = Path.join(System.tmp_dir!(), "tcp0027r3_#{System.unique_integer([:positive])}")
    File.rm_rf!(dir)
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    %{
      dir: dir,
      log: Path.join(dir, "events.log"),
      store: :"tcp0027r3_store_#{System.unique_integer([:positive])}",
      registry: :"tcp0027r3_registry_#{System.unique_integer([:positive])}"
    }
  end

  # ------------------------------------------------------------------
  # Test helpers
  # ------------------------------------------------------------------

  defp start_store(ctx, opts \\ []) do
    name = Keyword.get(opts, :name, ctx.store)
    options = Keyword.merge([name: name, file_path: ctx.log], Keyword.delete(opts, :name))
    start_supervised!(Supervisor.child_spec({EventStore, options}, id: name))
  end

  defp start_registry(ctx, opts \\ []) do
    name = Keyword.get(opts, :name, ctx.registry)

    options =
      Keyword.merge([name: name, event_store_name: ctx.store], Keyword.delete(opts, :name))

    start_supervised!(Supervisor.child_spec({ResolutionRegistry, options}, id: name))
  end

  defp event(text), do: Event.new("test.event", %{text: text})

  defp resolution(overrides \\ %{}) do
    base = %{
      resolution_id: "res-#{System.unique_integer([:positive])}",
      forecast_id: "f-#{System.unique_integer([:positive])}",
      forecast_version: "v1",
      forecast_digest: :crypto.hash(:sha256, "forecast"),
      outcome_definition_digest: :crypto.hash(:sha256, "definition"),
      horizon_digest: :crypto.hash(:sha256, "horizon"),
      model_ref: "model-1",
      forecast_created_at: ~U[2026-09-01 00:00:00Z],
      observation_id: "obs-1",
      evidence_digest: :crypto.hash(:sha256, "evidence"),
      observed_outcome: "yes",
      observed_at: ~U[2026-09-02 00:00:00Z],
      event_at: ~U[2026-09-02 00:00:00Z],
      published_at: ~U[2026-09-02 00:00:00Z],
      acquired_at: ~U[2026-09-02 00:00:00Z],
      verified_at: ~U[2026-09-02 00:00:00Z],
      verification_status: :source_verified,
      verification_policy_version: "v1",
      verification_record_digest: :crypto.hash(:sha256, "record"),
      resolution_source: :external_public,
      scores: %{brier: 0.09},
      evidence: %{},
      evidence_status: :real_observation,
      status: :resolved_not_certified,
      model_update: :requires_independent_review
    }

    Map.merge(base, overrides)
  end

  defp resolution_event(resolution), do: Event.new(@event_type, %{resolution: resolution})

  defp frame(event, sequence, previous_digest) do
    payload = Event.to_binary(event)
    frame_from_payload(payload, sequence, previous_digest)
  end

  defp frame_from_payload(payload, sequence, previous_digest) do
    digest = EventStore.record_digest(sequence, previous_digest, payload)

    <<@magic::binary, byte_size(payload)::32, sequence::64, digest::binary-size(@digest_size),
      previous_digest::binary-size(@digest_size), payload::binary>>
  end

  defp history_frames(events) do
    {frames, _last_digest} =
      Enum.reduce(Enum.with_index(events, 1), {[], @zero}, fn {event, sequence},
                                                              {acc, previous_digest} ->
        frame = frame(event, sequence, previous_digest)
        payload = Event.to_binary(event)
        {[acc, frame], EventStore.record_digest(sequence, previous_digest, payload)}
      end)

    frames
  end

  defp write_history(path, events), do: write_frames(path, history_frames(events))

  defp write_frames(path, frames) do
    File.write!(path, IO.iodata_to_binary(frames))
  end

  defp legacy_frame(event) do
    payload = Event.to_binary(event)
    <<byte_size(payload)::32, payload::binary>>
  end

  defp truncate_file!(path, bytes) do
    contents = File.read!(path)
    File.write!(path, binary_part(contents, 0, byte_size(contents) - bytes))
  end

  defp corrupt_digest!(path) do
    <<head::binary-size(12), _digest::binary-size(32), tail::binary>> = File.read!(path)
    File.write!(path, <<head::binary, 255::256, tail::binary>>)
  end

  defp index_published(ctx) do
    :ets.lookup(ResolutionRegistry.table(ctx.registry), @index_key)
  end

  defp wait_for_store(name, attempts \\ 100) do
    try do
      EventStore.health(name)
    catch
      :exit, _reason ->
        if attempts > 0 do
          Process.sleep(20)
          wait_for_store(name, attempts - 1)
        else
          flunk("EventStore did not restart")
        end
    end
  end

  # ------------------------------------------------------------------
  # A. EventStore startup and read failures
  # ------------------------------------------------------------------

  describe "EventStore startup integrity" do
    test "a genuinely new file starts empty-verified and appendable", ctx do
      start_store(ctx)

      health = EventStore.health(ctx.store)

      assert health.integrity == :empty_verified
      assert health.degraded == false
      assert health.complete_history_verified == true
      assert health.readable == true
      assert health.append_permitted == true
      assert health.count == 0
      assert health.last_sequence == nil
      assert health.last_digest == nil
      assert health.created_on_start == true
      assert health.poisoned == false
      assert File.exists?(ctx.log)

      assert :ok = EventStore.append(event("a"), ctx.store)

      health = EventStore.health(ctx.store)
      assert health.integrity == :empty_verified
      assert health.count == 1
      assert health.last_sequence == 1
      assert is_binary(health.last_digest)
    end

    test "an existing valid empty file is empty-verified, not newly created", ctx do
      File.write!(ctx.log, "")
      start_store(ctx)

      health = EventStore.health(ctx.store)
      assert health.integrity == :empty_verified
      assert health.created_on_start == false
      assert health.append_permitted == true
    end

    test "a populated valid history is verified and append continues the chain", ctx do
      write_history(ctx.log, [event("one"), event("two")])
      start_store(ctx)

      health = EventStore.health(ctx.store)
      assert health.integrity == :verified
      assert health.degraded == false
      assert health.count == 2
      assert health.last_sequence == 2
      assert is_binary(health.last_digest)

      assert :ok = EventStore.append(event("three"), ctx.store)

      {:ok, %{records: records}} = EventStore.read_records(ctx.store)
      assert Enum.map(records, & &1.sequence) == [1, 2, 3]
      assert Enum.all?(records, &(&1.integrity == :verified))
    end

    test "a read failure is unavailable, never a clean empty history", ctx do
      start_store(ctx, fault_injection: %{read: {:error, :eacces}})

      health = EventStore.health(ctx.store)

      assert health.integrity == :unavailable
      assert health.degraded == true
      assert health.complete_history_verified == false
      assert health.readable == false
      assert health.append_permitted == false
      assert health.count == 0
      assert health.read_error == :eacces

      assert {:error, :store_not_appendable} = EventStore.append(event("a"), ctx.store)
      assert {:error, {:read_failed, :eacces}} = EventStore.stream(0, ctx.store)
      assert {:error, {:read_failed, :eacces}} = EventStore.stream_verified(0, ctx.store)
      assert {:error, {:read_failed, :eacces}} = EventStore.read_records(ctx.store)
    end

    test "a file that cannot be opened is unavailable and not appendable", ctx do
      File.mkdir_p!(ctx.log)
      start_store(ctx)

      health = EventStore.health(ctx.store)
      assert health.integrity == :unavailable
      assert health.read_error == :eisdir
      assert health.append_permitted == false

      assert {:error, :store_not_appendable} = EventStore.append(event("a"), ctx.store)
    end

    test "a truncated final frame is degraded and refuses append", ctx do
      binary = IO.iodata_to_binary(history_frames([event("one")]))
      File.write!(ctx.log, binary_part(binary, 0, byte_size(binary) - 10))
      start_store(ctx)

      health = EventStore.health(ctx.store)
      assert health.integrity == :truncated
      assert health.degraded == true
      assert health.complete_history_verified == false
      assert health.append_permitted == false
      assert health.count == 0

      assert {:error, :store_not_appendable} = EventStore.append(event("a"), ctx.store)

      {:ok, result} = EventStore.stream_verified(0, ctx.store)
      assert result.truncated == true
      assert result.records == []
    end

    test "a modified digest is an integrity failure and refuses append", ctx do
      write_history(ctx.log, [event("one")])
      corrupt_digest!(ctx.log)
      start_store(ctx)

      health = EventStore.health(ctx.store)
      assert health.integrity == :integrity_failure
      assert health.append_permitted == false

      assert {:error, :store_not_appendable} = EventStore.append(event("a"), ctx.store)

      {:ok, result} = EventStore.stream_verified(0, ctx.store)
      assert result.integrity_failures == 1
      assert result.records == []
    end

    test "a broken chain is an integrity failure and refuses append", ctx do
      f1 = frame(event("one"), 1, @zero)
      wrong_previous = :crypto.hash(:sha256, "wrong-previous")
      f2 = frame(event("two"), 2, wrong_previous)
      write_frames(ctx.log, [f1, f2])
      start_store(ctx)

      health = EventStore.health(ctx.store)
      assert health.integrity == :integrity_failure
      assert health.append_permitted == false
      assert health.count == 1

      assert {:error, :store_not_appendable} = EventStore.append(event("a"), ctx.store)
    end

    test "a sequence gap is a sequence gap and refuses append", ctx do
      {f1, d1} = chained_frame(event("one"), 1, @zero)
      f3 = frame(event("three"), 3, d1)
      write_frames(ctx.log, [f1, f3])
      start_store(ctx)

      health = EventStore.health(ctx.store)
      assert health.integrity == :sequence_gap
      assert health.append_permitted == false
      assert health.count == 1

      assert {:error, :store_not_appendable} = EventStore.append(event("a"), ctx.store)
    end

    test "a legacy record is unverified and refuses append", ctx do
      write_frames(ctx.log, [legacy_frame(event("legacy"))])
      start_store(ctx)

      health = EventStore.health(ctx.store)
      assert health.integrity == :legacy_unverified
      assert health.complete_history_verified == false
      assert health.append_permitted == false
      assert health.count == 0

      assert {:error, :store_not_appendable} = EventStore.append(event("a"), ctx.store)

      # Legacy history remains readable, but never verified.
      assert [legacy] = EventStore.stream(0, ctx.store)
      assert legacy.data.text == "legacy"

      {:ok, result} = EventStore.stream_verified(0, ctx.store)
      assert result.unverified_legacy == 1
      assert result.records == []
    end

    test "multiple diagnostic categories require recovery", ctx do
      f1 = frame(event("one"), 1, @zero)
      <<head::binary-size(12), _digest::binary-size(32), tail::binary>> = f1
      corrupt = <<head::binary, 7::256, tail::binary>>
      write_frames(ctx.log, [legacy_frame(event("legacy")), corrupt])
      start_store(ctx)

      health = EventStore.health(ctx.store)
      assert health.integrity == :recovery_required
      assert health.append_permitted == false

      assert {:error, :store_not_appendable} = EventStore.append(event("a"), ctx.store)
    end

    test "append is refused when the file changes underneath a running store", ctx do
      start_store(ctx)
      assert :ok = EventStore.append(event("a"), ctx.store)
      assert EventStore.health(ctx.store).count == 1

      truncate_file!(ctx.log, 5)

      assert {:error, {:store_integrity_failure, :truncated_history}} =
               EventStore.append(event("b"), ctx.store)

      health = EventStore.health(ctx.store)
      assert health.integrity == :integrity_failure
      assert health.append_permitted == false
      assert health.count == 1
    end
  end

  # ------------------------------------------------------------------
  # B. Write and synchronisation failures
  # ------------------------------------------------------------------

  describe "EventStore write and sync failures" do
    test "a write failure poisons the store before any bytes are written", ctx do
      start_store(ctx, fault_injection: %{write: {:error, :enospc}})

      assert {:error, {:write_failed, :enospc}} = EventStore.append(event("a"), ctx.store)

      health = EventStore.health(ctx.store)
      assert health.poisoned == true
      assert health.integrity == :poisoned
      assert health.append_permitted == false
      assert health.count == 0
      assert File.stat!(ctx.log).size == 0

      assert {:error, :store_poisoned} = EventStore.append(event("b"), ctx.store)

      # The preceding history is empty and still verifies after a restart.
      stop_supervised(ctx.store)
      start_store(ctx)

      recovered = EventStore.health(ctx.store)
      assert recovered.integrity == :empty_verified
      assert recovered.count == 0
    end

    test "a failed append preserves and exposes the preceding verified history", ctx do
      write_history(ctx.log, [event("one")])
      start_store(ctx, fault_injection: %{write: {:error, :enospc}})

      assert {:error, {:write_failed, :enospc}} = EventStore.append(event("two"), ctx.store)
      assert EventStore.health(ctx.store).poisoned == true
      assert EventStore.health(ctx.store).count == 1

      stop_supervised(ctx.store)
      start_store(ctx)

      recovered = EventStore.health(ctx.store)
      assert recovered.integrity == :verified
      assert recovered.count == 1
      assert recovered.append_permitted == true

      {:ok, %{records: [record]}} = EventStore.read_records(ctx.store)
      assert record.event.data.text == "one"
    end

    test "a partial write leaves a truncated file and poisons the store", ctx do
      start_store(ctx, fault_injection: %{write: {:partial, 10}})

      assert {:error, {:write_failed, :partial_write}} = EventStore.append(event("a"), ctx.store)

      health = EventStore.health(ctx.store)
      assert health.poisoned == true
      assert health.append_permitted == false
      assert health.count == 0
      assert File.stat!(ctx.log).size == 10

      stop_supervised(ctx.store)
      start_store(ctx)

      recovered = EventStore.health(ctx.store)
      assert recovered.integrity == :truncated
      assert recovered.append_permitted == false
      assert {:error, :store_not_appendable} = EventStore.append(event("b"), ctx.store)
    end

    test "a sync failure poisons the store and is never acknowledged", ctx do
      start_store(ctx, fault_injection: %{sync: {:error, :eio}})

      assert {:error, {:sync_failed, :eio}} = EventStore.append(event("a"), ctx.store)

      health = EventStore.health(ctx.store)
      assert health.poisoned == true
      assert health.append_permitted == false
      assert health.count == 0
      assert health.last_sequence == nil
      assert File.stat!(ctx.log).size > 0

      assert {:error, :store_poisoned} = EventStore.append(event("b"), ctx.store)

      # Restarting against the actual file exposes the complete, verified
      # record as durable history. The earlier call still never acknowledged it.
      stop_supervised(ctx.store)
      start_store(ctx)

      recovered = EventStore.health(ctx.store)
      assert recovered.integrity == :verified
      assert recovered.count == 1
      assert recovered.append_permitted == true

      assert :ok = EventStore.append(event("b"), ctx.store)
      assert EventStore.health(ctx.store).count == 2
    end

    test "termination between write and sync never acknowledges success", ctx do
      start_store(ctx, fault_injection: %{kill_after_write: true})

      assert catch_exit(EventStore.append(event("crash"), ctx.store))

      health = wait_for_store(ctx.store)
      assert health.integrity == :verified
      assert health.count == 1
      assert health.append_permitted == true

      {:ok, %{records: [record]}} = EventStore.read_records(ctx.store)
      assert record.integrity == :verified
      assert record.event.data.text == "crash"
    end
  end

  # ------------------------------------------------------------------
  # C. Transactional registry replay
  # ------------------------------------------------------------------

  describe "transactional registry replay" do
    test "a complete valid history is recovered", ctx do
      first = resolution()
      second = resolution()
      write_history(ctx.log, [resolution_event(first), resolution_event(second)])

      start_store(ctx)
      start_registry(ctx)

      health = ResolutionRegistry.health(ctx.registry)
      assert health.integrity == :verified
      assert health.published == true
      assert health.durable == true
      assert health.resolution_count == 2

      assert {:ok, 2} = ResolutionRegistry.recover(ctx.registry)
      assert ResolutionRegistry.count(ctx.registry) == 2
      assert {:ok, ^first} = ResolutionRegistry.get(first.forecast_id, ctx.registry)
      assert {:ok, ^second} = ResolutionRegistry.get(second.forecast_id, ctx.registry)
    end

    test "an invalid first event rejects the entire history", ctx do
      bad = resolution_event(%{})

      write_history(ctx.log, [bad, resolution_event(resolution())])
      start_store(ctx)
      start_registry(ctx)

      health = ResolutionRegistry.health(ctx.registry)
      assert health.integrity == :degraded
      assert health.published == false
      assert health.durable == false
      assert health.recovery_error == :missing_forecast_identity
      assert health.resolution_count == 0

      assert {:error, :missing_forecast_identity} = ResolutionRegistry.recover(ctx.registry)
      assert {:error, :registry_not_verified} = ResolutionRegistry.count(ctx.registry)
      assert index_published(ctx) == []
    end

    test "an invalid middle event rejects the entire history", ctx do
      invalid = resolution(%{scores: "not-a-map"})

      write_history(ctx.log, [
        resolution_event(resolution()),
        resolution_event(invalid),
        resolution_event(resolution())
      ])

      start_store(ctx)
      start_registry(ctx)

      assert ResolutionRegistry.health(ctx.registry).recovery_error ==
               :malformed_resolution_event

      assert {:error, :malformed_resolution_event} = ResolutionRegistry.recover(ctx.registry)
    end

    test "an invalid final event rejects the entire history", ctx do
      write_history(ctx.log, [
        resolution_event(resolution()),
        resolution_event(%{})
      ])

      start_store(ctx)
      start_registry(ctx)

      assert {:error, :missing_forecast_identity} = ResolutionRegistry.recover(ctx.registry)
      assert ResolutionRegistry.health(ctx.registry).published == false
    end

    test "a truncated history is rejected", ctx do
      write_history(ctx.log, [resolution_event(resolution())])
      truncate_file!(ctx.log, 5)

      start_store(ctx)
      start_registry(ctx)

      assert {:error, :truncated_history} = ResolutionRegistry.recover(ctx.registry)
      assert {:error, :registry_not_verified} = ResolutionRegistry.get("f-any", ctx.registry)
    end

    test "an unreadable record is rejected", ctx do
      write_frames(ctx.log, [frame_from_payload("not-an-event", 1, @zero)])

      start_store(ctx)
      start_registry(ctx)

      assert {:error, :unreadable_record} = ResolutionRegistry.recover(ctx.registry)
      assert ResolutionRegistry.health(ctx.registry).published == false
    end

    test "a malformed resolution payload is rejected", ctx do
      malformed = Event.new(@event_type, %{resolution: "not-a-map"})
      write_history(ctx.log, [resolution_event(resolution()), malformed])

      start_store(ctx)
      start_registry(ctx)

      assert {:error, :malformed_resolution_event} = ResolutionRegistry.recover(ctx.registry)
      assert index_published(ctx) == []
    end

    test "a missing forecast identity is rejected", ctx do
      for missing <- [nil, ""] do
        dir =
          Path.join(System.tmp_dir!(), "tcp0027r3_missing_#{System.unique_integer([:positive])}")

        File.rm_rf!(dir)
        File.mkdir_p!(dir)
        log = Path.join(dir, "events.log")

        store = :"tcp0027r3_store_#{System.unique_integer([:positive])}"
        registry = :"tcp0027r3_registry_#{System.unique_integer([:positive])}"

        write_history(log, [resolution_event(resolution(%{forecast_id: missing}))])

        start_supervised!(
          Supervisor.child_spec({EventStore, [name: store, file_path: log]}, id: store)
        )

        start_supervised!(
          Supervisor.child_spec(
            {ResolutionRegistry, [name: registry, event_store_name: store]},
            id: registry
          )
        )

        assert {:error, :missing_forecast_identity} = ResolutionRegistry.recover(registry)

        stop_supervised(store)
        stop_supervised(registry)
        File.rm_rf!(dir)
      end
    end

    test "identical duplicate resolution events are rejected", ctx do
      duplicate = resolution()
      write_history(ctx.log, [resolution_event(duplicate), resolution_event(duplicate)])

      start_store(ctx)
      start_registry(ctx)

      assert {:error, :duplicate_identical_resolution_event} =
               ResolutionRegistry.recover(ctx.registry)

      assert ResolutionRegistry.count(ctx.registry) == {:error, :registry_not_verified}
      assert EventStore.count(ctx.store) == 2
      assert index_published(ctx) == []
    end

    test "conflicting duplicate resolution events are rejected", ctx do
      base = resolution()
      conflicting = Map.put(base, :scores, %{brier: 0.5})
      write_history(ctx.log, [resolution_event(base), resolution_event(conflicting)])

      start_store(ctx)
      start_registry(ctx)

      assert {:error, :conflicting_forecast_resolutions} =
               ResolutionRegistry.recover(ctx.registry)

      assert EventStore.count(ctx.store) == 2
      assert index_published(ctx) == []
    end

    test "an unavailable EventStore is rejected", ctx do
      start_registry(ctx)

      health = ResolutionRegistry.health(ctx.registry)
      assert health.integrity == :degraded
      assert health.published == false
      assert health.eventstore_available == false
      assert health.recovery_error == :eventstore_unavailable

      assert {:error, :eventstore_unavailable} = ResolutionRegistry.recover(ctx.registry)
    end

    test "a file read failure is reported precisely", ctx do
      start_store(ctx, fault_injection: %{read: {:error, :eacces}})
      start_registry(ctx)

      assert {:error, {:file_read_failure, :eacces}} = ResolutionRegistry.recover(ctx.registry)
    end

    test "an EventStore health-call failure is rejected", ctx do
      start_store(ctx)
      start_registry(ctx)

      assert ResolutionRegistry.health(ctx.registry).durable == true

      stop_supervised(ctx.store)

      assert {:error, :eventstore_unavailable} =
               ResolutionRegistry.get("f-any", ctx.registry)

      assert {:error, :eventstore_unavailable} = ResolutionRegistry.recover(ctx.registry)

      health = ResolutionRegistry.health(ctx.registry)
      assert health.published == false
      assert health.durable == false
    end

    test "a poisoned EventStore history is rejected", ctx do
      start_store(ctx, fault_injection: %{sync: {:error, :eio}})
      assert {:error, {:sync_failed, :eio}} = EventStore.append(event("a"), ctx.store)
      start_registry(ctx)

      assert ResolutionRegistry.health(ctx.registry).recovery_error == :eventstore_poisoned
      assert {:error, :eventstore_poisoned} = ResolutionRegistry.recover(ctx.registry)
    end
  end

  # ------------------------------------------------------------------
  # D. Preservation of a prior index
  # ------------------------------------------------------------------

  describe "prior index preservation" do
    test "a failed recovery invalidates the previous index and can be retried", ctx do
      write_history(ctx.log, [resolution_event(resolution()), resolution_event(resolution())])
      start_store(ctx)
      start_registry(ctx)

      assert ResolutionRegistry.count(ctx.registry) == 2

      # Corrupt the history underneath the running store.
      truncate_file!(ctx.log, 5)

      assert {:error, :truncated_history} = ResolutionRegistry.recover(ctx.registry)

      health = ResolutionRegistry.health(ctx.registry)
      assert health.integrity == :degraded
      assert health.published == false
      assert health.durable == false
      assert health.resolution_count == 0
      assert index_published(ctx) == []

      assert {:error, :registry_not_verified} = ResolutionRegistry.count(ctx.registry)
      assert {:error, :registry_not_verified} = ResolutionRegistry.all_ids(ctx.registry)

      # Repair the file and retry the same registry instance.
      File.rm!(ctx.log)
      write_history(ctx.log, [resolution_event(resolution()), resolution_event(resolution())])

      assert {:ok, 2} = ResolutionRegistry.recover(ctx.registry)

      health = ResolutionRegistry.health(ctx.registry)
      assert health.integrity == :verified
      assert health.published == true
      assert health.durable == true
      assert ResolutionRegistry.count(ctx.registry) == 2
    end

    test "a publication failure leaves no authoritative index and can be retried", ctx do
      write_history(ctx.log, [resolution_event(resolution())])
      start_store(ctx)
      start_registry(ctx)

      assert ResolutionRegistry.count(ctx.registry) == 1
      assert [_] = index_published(ctx)

      # Simulated ETS publication failure: point the registry at a table that
      # does not exist. The durable history is intact, so only publication fails.
      :sys.replace_state(ctx.registry, fn state ->
        %{state | table: :tcp0027r3_missing_table}
      end)

      assert {:error, :publication_failure} = ResolutionRegistry.recover(ctx.registry)

      health = ResolutionRegistry.health(ctx.registry)
      assert health.published == false
      assert health.durable == false
      assert health.recovery_error == :publication_failure
      assert health.ets_available == false
      assert {:error, :registry_not_verified} = ResolutionRegistry.count(ctx.registry)
      assert {:error, :registry_not_verified} = ResolutionRegistry.all_ids(ctx.registry)

      # Restore the real table and recover: the durable history is still valid.
      :sys.replace_state(ctx.registry, fn state ->
        %{state | table: ResolutionRegistry.table(ctx.registry)}
      end)

      assert {:ok, 1} = ResolutionRegistry.recover(ctx.registry)
      assert ResolutionRegistry.count(ctx.registry) == 1
      assert ResolutionRegistry.health(ctx.registry).durable == true
    end
  end

  # ------------------------------------------------------------------
  # E. Duplicate and conflict semantics
  # ------------------------------------------------------------------

  describe "duplicate and conflict semantics" do
    test "commit rejects a conflicting resolution for the same forecast", ctx do
      start_store(ctx)
      start_registry(ctx)

      base = resolution()
      assert {:ok, ^base} = ResolutionRegistry.commit(base, ctx.registry)

      conflicting = Map.put(base, :scores, %{brier: 0.4})
      assert {:error, :resolution_conflict} = ResolutionRegistry.commit(conflicting, ctx.registry)

      assert ResolutionRegistry.count(ctx.registry) == 1
      assert EventStore.count(ctx.store) == 1
    end

    test "an exact retry is idempotent and appends nothing", ctx do
      start_store(ctx)
      start_registry(ctx)

      base = resolution()
      assert {:ok, ^base} = ResolutionRegistry.commit(base, ctx.registry)
      assert {:ok, ^base} = ResolutionRegistry.commit(base, ctx.registry)

      assert ResolutionRegistry.count(ctx.registry) == 1
      assert EventStore.count(ctx.store) == 1
      assert ResolutionRegistry.health(ctx.registry).durable == true
    end

    test "an invalid commit payload is rejected without touching the store", ctx do
      start_store(ctx)
      start_registry(ctx)

      assert {:error, :invalid_resolution_payload} =
               ResolutionRegistry.commit(%{forecast_id: "f-1"}, ctx.registry)

      assert EventStore.count(ctx.store) == 0
      assert ResolutionRegistry.count(ctx.registry) == 0
    end

    test "commit is refused while the registry is not verified", ctx do
      write_history(ctx.log, [resolution_event(resolution())])
      truncate_file!(ctx.log, 5)
      start_store(ctx)
      start_registry(ctx)

      assert {:error, :registry_not_verified} =
               ResolutionRegistry.commit(resolution(), ctx.registry)

      assert EventStore.count(ctx.store) == 0
    end

    test "commit is refused when the EventStore disappears", ctx do
      start_store(ctx)
      start_registry(ctx)

      stop_supervised(ctx.store)

      assert {:error, :eventstore_unavailable} =
               ResolutionRegistry.commit(resolution(), ctx.registry)

      # The registry has entered a degraded state; later lookups cannot claim
      # verified durability.
      assert {:error, :registry_not_verified} = ResolutionRegistry.get("f-any", ctx.registry)

      health = ResolutionRegistry.health(ctx.registry)
      assert health.published == false
      assert health.durable == false
    end

    test "conflicting durable history is rejected for each identity field", ctx do
      fields = [
        observation_id: "obs-2",
        evidence_digest: :crypto.hash(:sha256, "other-evidence"),
        observed_at: ~U[2026-09-03 00:00:00Z],
        verification_status: :unverified,
        resolution_source: :simulation,
        scores: %{brier: 0.3}
      ]

      for {field, value} <- fields do
        dir =
          Path.join(System.tmp_dir!(), "tcp0027r3_conflict_#{System.unique_integer([:positive])}")

        File.rm_rf!(dir)
        File.mkdir_p!(dir)
        log = Path.join(dir, "events.log")
        store = :"tcp0027r3_store_#{System.unique_integer([:positive])}"
        registry = :"tcp0027r3_registry_#{System.unique_integer([:positive])}"

        base = resolution()

        write_history(log, [
          resolution_event(base),
          resolution_event(Map.put(base, field, value))
        ])

        start_supervised!(
          Supervisor.child_spec({EventStore, [name: store, file_path: log]}, id: store)
        )

        start_supervised!(
          Supervisor.child_spec(
            {ResolutionRegistry, [name: registry, event_store_name: store]},
            id: registry
          )
        )

        assert {:error, :conflicting_forecast_resolutions} =
                 ResolutionRegistry.recover(registry)

        stop_supervised(store)
        stop_supervised(registry)
        File.rm_rf!(dir)
      end
    end
  end

  # ------------------------------------------------------------------
  # F. Actual persistence-boundary restart
  # ------------------------------------------------------------------

  describe "persistence-boundary restart" do
    test "a resolution survives store and registry restart without duplication", ctx do
      start_store(ctx)
      start_registry(ctx)

      base = resolution()
      assert {:ok, ^base} = ResolutionRegistry.commit(base, ctx.registry)
      assert EventStore.count(ctx.store) == 1
      assert ResolutionRegistry.count(ctx.registry) == 1

      stop_supervised(ctx.registry)
      stop_supervised(ctx.store)

      start_store(ctx)
      start_registry(ctx)

      assert {:ok, 1} = ResolutionRegistry.recover(ctx.registry)
      assert ResolutionRegistry.count(ctx.registry) == 1
      assert {:ok, ^base} = ResolutionRegistry.get(base.forecast_id, ctx.registry)
      assert {:ok, ^base} = ResolutionRegistry.commit(base, ctx.registry)

      assert EventStore.count(ctx.store) == 1
      assert ResolutionRegistry.count(ctx.registry) == 1

      health = ResolutionRegistry.health(ctx.registry)
      assert health.integrity == :verified
      assert health.published == true
      assert health.durable == true
      assert health.resolution_count == 1
      assert health.recovered_count == 1
    end

    test "an append that happened before registry indexing is recovered", ctx do
      start_store(ctx)
      start_registry(ctx)

      first = resolution()
      assert {:ok, ^first} = ResolutionRegistry.commit(first, ctx.registry)

      # Simulated crash point: the durable append succeeded, but the registry
      # process died before it could index the record.
      second = resolution()

      assert :ok =
               EventStore.append(resolution_event(second), ctx.store)

      assert ResolutionRegistry.count(ctx.registry) == 1

      stop_supervised(ctx.registry)
      start_registry(ctx)

      assert ResolutionRegistry.count(ctx.registry) == 2
      assert {:ok, ^second} = ResolutionRegistry.get(second.forecast_id, ctx.registry)
      assert EventStore.count(ctx.store) == 2
    end

    test "lookups are exact while verified", ctx do
      start_store(ctx)
      start_registry(ctx)

      assert ResolutionRegistry.get("f-missing", ctx.registry) == :error
      assert ResolutionRegistry.all_ids(ctx.registry) == []

      first = resolution()
      second = resolution()

      assert {:ok, ^first} = ResolutionRegistry.commit(first, ctx.registry)
      assert {:ok, ^second} = ResolutionRegistry.commit(second, ctx.registry)

      assert ResolutionRegistry.all_ids(ctx.registry) ==
               Enum.sort([first.forecast_id, second.forecast_id])
    end
  end

  # A helper that returns both the frame and its digest.
  defp chained_frame(event, sequence, previous_digest) do
    payload = Event.to_binary(event)
    digest = EventStore.record_digest(sequence, previous_digest, payload)

    frame =
      <<@magic::binary, byte_size(payload)::32, sequence::64, digest::binary-size(@digest_size),
        previous_digest::binary-size(@digest_size), payload::binary>>

    {frame, digest}
  end
end
