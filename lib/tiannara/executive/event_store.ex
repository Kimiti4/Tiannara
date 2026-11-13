defmodule Tiannara.Executive.EventStore do
  @moduledoc """
  Append-only event log for the Executive Memory subsystem.

  Events are persisted as a framed binary log file, streamed sequentially for
  replay, and managed via a GenServer.

  ## Record envelope (version 2)

      <<"EFD2", size::32, sequence::64, digest::32, previous_digest::32,
        payload::binary-size(size)>>

  * `sequence` — the record's position in the durable append order. It is
    assigned by the store at append time; it is **not** delivery order.
  * `digest` — SHA-256 over the canonical representation of the record
    (sequence, previous digest and payload). It establishes **integrity**, not
    authenticity: anyone with write access can recompute it.
  * `previous_digest` — the digest of the preceding record, which binds the
    history into a chain. A record removed or reordered from the middle breaks
    the chain and is detected.

  ## Legacy records

  A legacy frame is `<<size::32, payload::binary-size(size)>>` with no
  sequence and no digest. Legacy records are read and reported as
  `unverified_legacy`: they are **never** presented as integrity-verified.
  A legacy frame whose declared size equals the magic prefix would be
  misread; frames of that size (~1.16 GB) are not supported.
  """
  use GenServer

  require Logger

  defstruct [:file_path, :file_handle, :count, :last_digest, :last_sequence]

  @type t :: %__MODULE__{
          file_path: String.t(),
          file_handle: File.io_device() | nil,
          count: non_neg_integer(),
          last_digest: binary() | nil,
          last_sequence: non_neg_integer()
        }

  @magic "EFD2"
  @digest_size 32
  @zero_digest <<0::256>>

  @doc """
  The registered name of the event store.

  Configurable so that an isolated durable log can be used where the
  application-wide log would conflict — in tests, and where two logs must not
  share a file.
  """
  def server, do: Application.get_env(:tiannara, :executive_event_store) || __MODULE__

  @doc "Starts the EventStore GenServer."
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, server())
    file_path = Keyword.get(opts, :file_path, "/tmp/tiannara_executive_events.log")
    GenServer.start_link(__MODULE__, {file_path, name}, name: name)
  end

  @doc "Appends an event to the log."
  def append(event), do: GenServer.call(server(), {:append, event})

  @doc "Streams all events since a given index."
  def stream(since \\ 0), do: GenServer.call(server(), {:stream, since})

  @doc """
  Streams the log together with what could not be read.

  A truncated tail or a corrupted frame must not be presented as clean
  history: the unreadable count is reported so that a consumer can refuse to
  treat the recovered history as complete.
  """
  @spec stream_with_diagnostics(non_neg_integer()) :: {:ok, map()}
  def stream_with_diagnostics(since \\ 0),
    do: GenServer.call(server(), {:stream_with_diagnostics, since})

  @doc """
  Streams the log with per-record integrity and ordering metadata.

  Each record is returned as `%{event:, sequence:, digest:, previous_digest:,
  integrity: :verified | :unverified_legacy | :integrity_failure | :sequence_gap,
  detail:}`.

  A record whose integrity or ordering cannot be established is **not**
  returned as an event; it is reported as a failure so that a consumer cannot
  silently apply it.
  """
  @spec stream_verified(non_neg_integer()) :: {:ok, map()}
  def stream_verified(since \\ 0), do: GenServer.call(server(), {:stream_verified, since})

  @doc "Returns events since a given timestamp."
  def since(timestamp), do: GenServer.call(server(), {:since, timestamp})

  @doc "Returns the current event count."
  def count, do: GenServer.call(server(), :count)

  @impl true
  def init({file_path, _name}) do
    File.mkdir_p!(Path.dirname(file_path))
    {:ok, fh} = File.open(file_path, [:append, :read, :binary])

    {records, _unreadable, _truncated, _failures, _gaps, _legacy} = read_frames(file_path, 0)

    verified =
      records
      |> Enum.filter(&(&1.integrity == :verified))
      |> List.last()

    count =
      records
      |> Enum.map(& &1.sequence)
      |> Enum.reject(&is_nil/1)
      |> Enum.max(fn -> 0 end)

    state = %__MODULE__{
      file_path: file_path,
      file_handle: fh,
      count: count,
      last_digest: verified && verified.digest,
      last_sequence: verified && verified.sequence
    }

    Logger.info(
      "[ExecutiveMemory.EventStore] Started: #{file_path} (#{count} sequenced records, " <>
        "#{Enum.count(records, &(&1.integrity == :verified))} verified)"
    )

    {:ok, state}
  end

  @impl true
  def handle_call({:append, event}, _from, state) do
    sequence = (state.last_sequence || 0) + 1
    previous_digest = state.last_digest || @zero_digest
    payload = Tiannara.Executive.Event.to_binary(event)
    digest = record_digest(sequence, previous_digest, payload)

    frame =
      <<@magic::binary, byte_size(payload)::32, sequence::64, digest::binary-size(@digest_size),
        previous_digest::binary-size(@digest_size), payload::binary>>

    IO.binwrite(state.file_handle, frame)

    state = %{
      state
      | count: state.count + 1,
        last_digest: digest,
        last_sequence: sequence
    }

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:stream, since}, _from, state) do
    {records, _unreadable, _truncated, _failures, _gaps, _legacy} = read_frames(state.file_path, 0)

    events =
      records
      |> Enum.filter(&(&1.integrity in [:verified, :unverified_legacy]))
      |> Enum.filter(&(is_nil(&1.sequence) or &1.sequence > since))
      |> Enum.map(& &1.event)

    {:reply, events, state}
  end

  def handle_call({:stream_with_diagnostics, since}, _from, state) do
    {records, unreadable, truncated, failures, gaps, legacy} = read_frames(state.file_path, 0)

    events =
      records
      |> Enum.filter(&(&1.integrity in [:verified, :unverified_legacy]))
      |> Enum.filter(&(is_nil(&1.sequence) or &1.sequence > since))
      |> Enum.map(& &1.event)

    {:reply,
     {:ok,
      %{
        events: events,
        unreadable: unreadable,
        truncated: truncated,
        integrity_failures: failures,
        sequence_gaps: gaps,
        unverified_legacy: legacy,
        verified: Enum.count(records, &(&1.integrity == :verified))
      }}, state}
  end

  def handle_call({:stream_verified, since}, _from, state) do
    {records, unreadable, truncated, failures, gaps, legacy} = read_frames(state.file_path, 0)

    verified =
      records
      |> Enum.filter(&(&1.integrity == :verified))
      |> Enum.filter(&(is_nil(&1.sequence) or &1.sequence > since))

    {:reply,
     {:ok,
      %{
        records: verified,
        unreadable: unreadable,
        truncated: truncated,
        integrity_failures: failures,
        sequence_gaps: gaps,
        unverified_legacy: legacy
      }}, state}
  end

  @impl true
  def handle_call({:since, timestamp}, _from, state) do
    {records, _unreadable, _truncated, _failures, _gaps, _legacy} = read_frames(state.file_path, 0)

    filtered =
      Enum.filter(records, fn r ->
        r.integrity == :verified and
          match?(%{timestamp: ts} when not is_nil(ts), r.event) and
          DateTime.compare(r.event.timestamp, timestamp) != :lt
      end)

    {:reply, Enum.map(filtered, & &1.event), state}
  end

  @impl true
  def handle_call(:count, _from, state) do
    {:reply, state.count, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.file_handle, do: File.close(state.file_handle)
    :ok
  end

  # ------------------------------------------------------------------ frames

  @doc false
  def record_digest(sequence, previous_digest, payload) do
    :crypto.hash(
      :sha256,
      :erlang.term_to_binary({:tiannara_event_v2, sequence, previous_digest, payload})
    )
  end

  defp read_frames(file_path, since_offset) do
    case File.read(file_path) do
      {:ok, data} ->
        parse_frames(data, since_offset, nil, [], 0, false, 0, 0, 0, 0)

      _ ->
        {[], 0, false, 0, 0, 0}
    end
  end

  # The accumulator carries: the previous verified record's digest and
  # sequence, so that the chain and the sequence can be checked as the log is
  # read, rather than after the fact.
  defp parse_frames(
         <<@magic::binary, size::32, sequence::64, digest::binary-size(@digest_size),
           previous_digest::binary-size(@digest_size), rest::binary>>,
         since_offset,
         prev,
         acc,
         unreadable,
         truncated,
         failures,
         gaps,
         legacy,
         seen
       ) do
    if byte_size(rest) < size do
      # The declared payload is incomplete: a truncated tail.
      parse_frames(
        <<>>,
        since_offset,
        prev,
        acc,
        unreadable + 1,
        true,
        failures,
        gaps,
        legacy,
        seen
      )
    else
      <<payload::binary-size(size), tail::binary>> = rest

      expected = record_digest(sequence, previous_digest, payload)

      {integrity, detail, new_prev, new_sequence} =
        cond do
          digest != expected ->
            {:integrity_failure, :digest_mismatch, prev, prev && prev.sequence}

          is_nil(prev) and (sequence != 1 or seen > 0) ->
            # The log does not begin at a known origin. Once the origin is
            # wrong, no later record can establish one either: the ordering
            # of the whole log is unestablished.
            {:sequence_gap, :unexpected_initial_sequence, prev, prev && prev.sequence}

          not is_nil(prev) and previous_digest != prev.digest ->
            {:integrity_failure, :chain_break, prev, prev && prev.sequence}

          not is_nil(prev) and sequence != prev.sequence + 1 ->
            {:sequence_gap, :sequence_gap, prev, prev && prev.sequence}

          true ->
            {:verified, :ok, %{digest: digest, sequence: sequence}, sequence}
        end

      case safe_event(payload) do
        {:ok, event} ->
          record = %{
            event: event,
            sequence: sequence,
            digest: digest,
            previous_digest: previous_digest,
            integrity: integrity,
            detail: detail
          }

          {failures, gaps, legacy} =
            case integrity do
              :verified -> {failures, gaps, legacy}
              :sequence_gap -> {failures, gaps + 1, legacy}
              :integrity_failure -> {failures + 1, gaps, legacy}
            end

          acc = [record | acc]

          parse_frames(
            tail,
            since_offset,
            new_prev,
            acc,
            unreadable,
            truncated,
            failures,
            gaps,
            legacy,
            seen + 1
          )

        :error ->
          parse_frames(
            tail,
            since_offset,
            prev,
            acc,
            unreadable + 1,
            truncated,
            failures + 1,
            gaps,
            legacy,
            seen + 1
          )
      end
    end
  end

  # A legacy frame: no sequence, no digest. It is read, and reported as
  # unverified. It is never presented as integrity-verified.
  defp parse_frames(
         <<size::32, rest::binary>>,
         since_offset,
         prev,
         acc,
         unreadable,
         truncated,
         failures,
         gaps,
         legacy,
         seen
       ) do
    if byte_size(rest) < size do
      parse_frames(
        <<>>,
        since_offset,
        prev,
        acc,
        unreadable + 1,
        true,
        failures,
        gaps,
        legacy,
        seen
      )
    else
      <<payload::binary-size(size), tail::binary>> = rest

      {event, record} =
        case safe_event(payload) do
          {:ok, event} ->
            {event,
             %{
               event: event,
               sequence: nil,
               digest: nil,
               previous_digest: nil,
               integrity: :unverified_legacy,
               detail: :legacy_record
             }}

          :error ->
            {nil, nil}
        end

      acc = if record, do: [record | acc], else: acc

      parse_frames(
        tail,
        since_offset,
        prev,
        acc,
        unreadable + if(record, do: 0, else: 1),
        truncated,
        failures + if(record, do: 0, else: 1),
        gaps,
        legacy + 1,
        seen + 1
      )
    end
  end

  defp parse_frames(
         _,
         _since_offset,
         _prev,
         acc,
         unreadable,
         truncated,
         failures,
         gaps,
         legacy,
         _seen
       ) do
    {Enum.reverse(acc), unreadable, truncated, failures, gaps, legacy}
  end

  defp safe_event(bin) do
    {:ok, Tiannara.Executive.Event.from_binary(bin)}
  rescue
    _error -> :error
  end
end
