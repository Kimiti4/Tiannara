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

  ## Integrity state

  `health/0` reports an explicit classification instead of an implicit flag:

  * `:verified` — the complete log was read and every frame verified;
  * `:empty_verified` — the log was opened and read as empty;
  * `:unavailable` — the log could not be opened or read (the reason is
    exposed as `read_error`);
  * `:truncated` — the final frame is incomplete;
  * `:integrity_failure` — a digest or chain check failed;
  * `:sequence_gap` — the sequence is not contiguous from 1;
  * `:legacy_unverified` — unverified legacy frames are present;
  * `:recovery_required` — several diagnostic categories are present at once;
  * `:poisoned` — a write or `fsync` failed with an uncertain file boundary.

  Append is permitted only for `:verified` and `:empty_verified`. A read
  failure is never represented as a clean empty history. A poisoned store
  refuses every subsequent append until it is restarted against the file and
  the complete history verifies again.

  ## Synchronisation limits

  A successful `:file.sync/1` means the write was handed to the operating
  system and the file was synchronised at the time of the call. It is not a
  proof that hardware, firmware or a remote filesystem will never lose or
  reorder data. `durability` here means "acknowledged only after write and
  sync succeeded", not "immune to every storage failure".
  """
  use GenServer

  require Logger

  defstruct [
    :file_path,
    :file_handle,
    :count,
    :last_digest,
    :last_sequence,
    :integrity_issues,
    :diagnostics,
    :read_error,
    :fault_injection,
    :created_on_start,
    integrity: :unavailable,
    degraded: true,
    append_permitted: false,
    poisoned: false
  ]

  @type integrity ::
          :verified
          | :empty_verified
          | :unavailable
          | :truncated
          | :integrity_failure
          | :sequence_gap
          | :legacy_unverified
          | :recovery_required
          | :poisoned

  @type t :: %__MODULE__{
          file_path: String.t(),
          file_handle: File.io_device() | nil,
          count: non_neg_integer(),
          last_digest: binary() | nil,
          last_sequence: non_neg_integer() | nil,
          integrity: integrity(),
          degraded: boolean(),
          append_permitted: boolean(),
          poisoned: boolean()
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
    fault_injection = Keyword.get(opts, :fault_injection)

    GenServer.start_link(__MODULE__, {file_path, name, fault_injection}, name: name)
  end

  @doc "Appends an event to the log."
  @spec append(term(), atom()) :: :ok | {:error, term()}
  def append(event, name \\ server()), do: GenServer.call(name, {:append, event})

  @doc "Streams all events since a given index."
  @spec stream(non_neg_integer(), atom()) :: [term()] | {:error, term()}
  def stream(since \\ 0, name \\ server()), do: GenServer.call(name, {:stream, since})

  @doc """
  Streams the log together with what could not be read.

  A truncated tail or a corrupted frame must not be presented as clean
  history: the diagnostics are reported so that a consumer can refuse to
  treat the recovered history as complete. An I/O failure is returned as
  `{:error, {:read_failed, reason}}` rather than as an empty history.
  """
  @spec stream_with_diagnostics(non_neg_integer(), atom()) ::
          {:ok, map()} | {:error, term()}
  def stream_with_diagnostics(since \\ 0, name \\ server()),
    do: GenServer.call(name, {:stream_with_diagnostics, since})

  @doc """
  Streams the log with per-record integrity and ordering metadata.

  Each record is returned as `%{event:, sequence:, digest:, previous_digest:,
  integrity: :verified | :unverified_legacy | :integrity_failure | :sequence_gap,
  detail:}`.

  A record whose integrity or ordering cannot be established is **not**
  returned as an event; it is reported as a failure so that a consumer cannot
  silently apply it.
  """
  @spec stream_verified(non_neg_integer(), atom()) :: {:ok, map()} | {:error, term()}
  def stream_verified(since \\ 0, name \\ server()),
    do: GenServer.call(name, {:stream_verified, since})

  @doc """
  Returns the complete framed history, including records that failed
  verification, together with the diagnostics.

  This is the diagnostic read used by storage consumers that must decide
  whether the *entire* history is trustworthy before publishing derived
  state.
  """
  @spec read_records(atom()) :: {:ok, map()} | {:error, term()}
  def read_records(name \\ server()), do: GenServer.call(name, :read_records)

  @doc "Returns events since a given timestamp."
  @spec since(DateTime.t(), atom()) :: [term()] | {:error, term()}
  def since(timestamp, name \\ server()), do: GenServer.call(name, {:since, timestamp})

  @doc "Returns the current verified event count."
  def count(name \\ server()), do: GenServer.call(name, :count)

  @doc """
  Returns the health and integrity state of the store.

  `durable` is deliberately absent: this call reports whether the history is
  verified and whether appends are permitted, not whether a particular record
  has reached stable storage.
  """
  @spec health(atom()) :: map()
  def health(name \\ server()), do: GenServer.call(name, :health)

  @impl true
  def init({file_path, _name, fault_injection}) do
    File.mkdir_p!(Path.dirname(file_path))
    created? = not File.exists?(file_path)

    case File.open(file_path, [:append, :read, :binary]) do
      {:ok, fh} ->
        case read_frames(file_path, 0, fault_injection) do
          {:ok, %{records: records, diagnostics: diagnostics}} ->
            verified = Enum.filter(records, &(&1.integrity == :verified))
            last = List.last(verified)
            integrity = classify(diagnostics, records)
            append_permitted = integrity in [:verified, :empty_verified]

            state = %__MODULE__{
              file_path: file_path,
              file_handle: fh,
              count: length(verified),
              last_digest: last && last.digest,
              last_sequence: last && last.sequence,
              integrity: integrity,
              degraded: not append_permitted,
              append_permitted: append_permitted,
              poisoned: false,
              integrity_issues: issues_for(integrity, diagnostics),
              diagnostics: diagnostics,
              read_error: nil,
              fault_injection: fault_injection,
              created_on_start: created?
            }

            Logger.info(
              "[ExecutiveMemory.EventStore] Started: #{file_path} " <>
                "(#{length(verified)} verified, integrity=#{integrity}, " <>
                "append_permitted=#{append_permitted})"
            )

            {:ok, state}

          {:error, {:read_failed, reason}} ->
            File.close(fh)
            Logger.error("[ExecutiveMemory.EventStore] Cannot read log: #{inspect(reason)}")
            {:ok, unavailable_state(file_path, reason, fault_injection, created?)}
        end

      {:error, reason} ->
        Logger.error("[ExecutiveMemory.EventStore] Cannot open log: #{inspect(reason)}")
        {:ok, unavailable_state(file_path, reason, fault_injection, created?)}
    end
  end

  @impl true
  def handle_call({:append, _event}, _from, %{poisoned: true} = state) do
    {:reply, {:error, :store_poisoned}, state}
  end

  def handle_call({:append, _event}, _from, %{append_permitted: false} = state) do
    {:reply, {:error, :store_not_appendable}, state}
  end

  def handle_call({:append, event}, _from, state) do
    case pre_append_integrity(state) do
      :ok ->
        do_append(event, state)

      {:error, reason} ->
        Logger.error("[ExecutiveMemory.EventStore] History no longer intact: #{inspect(reason)}")

        degraded = %{
          state
          | append_permitted: false,
            degraded: true,
            integrity: :integrity_failure,
            integrity_issues: [{:history_integrity_lost, reason} | state.integrity_issues]
        }

        {:reply, {:error, {:store_integrity_failure, reason}}, degraded}
    end
  end

  @impl true
  def handle_call({:stream, since}, _from, state) do
    case read_frames(state.file_path, 0, state.fault_injection) do
      {:ok, %{records: records}} ->
        events =
          records
          |> Enum.filter(&(&1.integrity in [:verified, :unverified_legacy]))
          |> Enum.filter(&(is_nil(&1.sequence) or &1.sequence > since))
          |> Enum.map(& &1.event)

        {:reply, events, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:stream_with_diagnostics, since}, _from, state) do
    case read_frames(state.file_path, 0, state.fault_injection) do
      {:ok, %{records: records, diagnostics: diagnostics}} ->
        events =
          records
          |> Enum.filter(&(&1.integrity in [:verified, :unverified_legacy]))
          |> Enum.filter(&(is_nil(&1.sequence) or &1.sequence > since))
          |> Enum.map(& &1.event)

        {:reply,
         {:ok,
          %{
            events: events,
            integrity: classify(diagnostics, records),
            diagnostics: diagnostics,
            unreadable: diagnostics.unreadable,
            truncated: diagnostics.truncated,
            integrity_failures: diagnostics.integrity_failures,
            sequence_gaps: diagnostics.sequence_gaps,
            unverified_legacy: diagnostics.unverified_legacy,
            verified: Enum.count(records, &(&1.integrity == :verified))
          }}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:stream_verified, since}, _from, state) do
    case read_frames(state.file_path, 0, state.fault_injection) do
      {:ok, %{records: records, diagnostics: diagnostics}} ->
        verified =
          records
          |> Enum.filter(&(&1.integrity == :verified))
          |> Enum.filter(&(is_nil(&1.sequence) or &1.sequence > since))

        {:reply,
         {:ok,
          %{
            records: verified,
            integrity: classify(diagnostics, records),
            diagnostics: diagnostics,
            unreadable: diagnostics.unreadable,
            truncated: diagnostics.truncated,
            integrity_failures: diagnostics.integrity_failures,
            sequence_gaps: diagnostics.sequence_gaps,
            unverified_legacy: diagnostics.unverified_legacy,
            verified: Enum.count(records, &(&1.integrity == :verified))
          }}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:read_records, _from, state) do
    case read_frames(state.file_path, 0, state.fault_injection) do
      {:ok, %{records: records, diagnostics: diagnostics}} ->
        {:reply,
         {:ok,
          %{
            records: records,
            diagnostics: diagnostics,
            integrity: classify(diagnostics, records)
          }}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:since, timestamp}, _from, state) do
    case read_frames(state.file_path, 0, state.fault_injection) do
      {:ok, %{records: records}} ->
        filtered =
          Enum.filter(records, fn r ->
            r.integrity == :verified and
              match?(%{timestamp: ts} when not is_nil(ts), r.event) and
              DateTime.compare(r.event.timestamp, timestamp) != :lt
          end)

        {:reply, Enum.map(filtered, & &1.event), state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:count, _from, state) do
    {:reply, state.count, state}
  end

  @impl true
  def handle_call(:health, _from, state) do
    complete? = state.integrity in [:verified, :empty_verified]

    {:reply,
     %{
       file_path: state.file_path,
       integrity: state.integrity,
       degraded: state.degraded,
       complete_history_verified: complete?,
       readable: state.integrity != :unavailable,
       append_permitted: state.append_permitted,
       writable: state.append_permitted,
       count: state.count,
       verified_count: state.count,
       last_sequence: state.last_sequence,
       last_digest: state.last_digest,
       diagnostics: state.diagnostics,
       integrity_issues: state.integrity_issues,
       poisoned: state.poisoned,
       read_error: state.read_error,
       created_on_start: state.created_on_start
     }, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.file_handle, do: File.close(state.file_handle)
    :ok
  end

  # ------------------------------------------------------------------ append

  defp do_append(event, state) do
    sequence = (state.last_sequence || 0) + 1
    previous_digest = state.last_digest || @zero_digest
    payload = Tiannara.Executive.Event.to_binary(event)
    digest = record_digest(sequence, previous_digest, payload)

    frame =
      <<@magic::binary, byte_size(payload)::32, sequence::64, digest::binary-size(@digest_size),
        previous_digest::binary-size(@digest_size), payload::binary>>

    case write_frame(state, frame) do
      :ok ->
        if fault(state, :kill_after_write) == true do
          # Simulated machine/process loss between write and sync. The caller
          # must not receive a successful acknowledgement.
          Process.exit(self(), :kill)
        end

        case sync_file(state) do
          :ok ->
            state = %{
              state
              | count: state.count + 1,
                last_digest: digest,
                last_sequence: sequence
            }

            {:reply, :ok, state}

          {:error, reason} ->
            Logger.error("[ExecutiveMemory.EventStore] sync failed: #{inspect(reason)}")
            {:reply, {:error, {:sync_failed, reason}}, poison(state, {:sync_failed, reason})}
        end

      {:error, reason} ->
        Logger.error("[ExecutiveMemory.EventStore] write failed: #{inspect(reason)}")
        {:reply, {:error, {:write_failed, reason}}, poison(state, {:write_failed, reason})}
    end
  end

  # Re-read the complete history before accepting another record. The cached
  # state is not evidence that the file on disk is still intact: another
  # process, a partial restore or a truncation can change it underneath us.
  defp pre_append_integrity(state) do
    case read_frames(state.file_path, 0, state.fault_injection) do
      {:ok, %{records: records, diagnostics: diagnostics}} ->
        verified = Enum.filter(records, &(&1.integrity == :verified))
        last = List.last(verified)

        cond do
          diagnostics_any?(diagnostics) ->
            {:error, storage_reason(diagnostics, records)}

          length(verified) != length(records) ->
            {:error, :unverified_history}

          length(verified) != state.count ->
            {:error, :history_changed}

          (last && last.digest) != state.last_digest ->
            {:error, :history_changed}

          true ->
            :ok
        end

      {:error, {:read_failed, reason}} ->
        {:error, {:read_failed, reason}}
    end
  end

  defp write_frame(state, frame) do
    case fault(state, :write) do
      nil ->
        IO.binwrite(state.file_handle, frame)

      {:error, reason} ->
        {:error, reason}

      {:partial, count} ->
        # Write a real prefix of the frame, then report failure. This leaves a
        # genuinely truncated frame on disk so that restart recovery is
        # exercised against a real partial write, not a simulated one.
        partial = binary_part(frame, 0, min(count, byte_size(frame)))
        _ = IO.binwrite(state.file_handle, partial)
        {:error, :partial_write}
    end
  end

  defp sync_file(state) do
    case fault(state, :sync) do
      nil -> :file.sync(state.file_handle)
      {:error, reason} -> {:error, reason}
    end
  end

  defp fault(state, key), do: Map.get(state.fault_injection || %{}, key)

  defp poison(state, detail) do
    %{
      state
      | poisoned: true,
        append_permitted: false,
        degraded: true,
        integrity: :poisoned,
        integrity_issues: [detail | state.integrity_issues]
    }
  end

  # ------------------------------------------------------------------ frames

  @doc false
  def record_digest(sequence, previous_digest, payload) do
    :crypto.hash(
      :sha256,
      :erlang.term_to_binary({:tiannara_event_v2, sequence, previous_digest, payload})
    )
  end

  defp read_frames(file_path, since_offset, fault_injection) do
    case Map.get(fault_injection || %{}, :read) do
      {:error, reason} ->
        {:error, {:read_failed, reason}}

      _ ->
        case File.read(file_path) do
          {:ok, data} ->
            {records, unreadable, truncated, failures, gaps, legacy} =
              parse_frames(data, since_offset, nil, [], 0, false, 0, 0, 0, 0)

            {:ok,
             %{
               records: records,
               diagnostics: %{
                 unreadable: unreadable,
                 truncated: truncated,
                 integrity_failures: failures,
                 sequence_gaps: gaps,
                 unverified_legacy: legacy
               }
             }}

          {:error, reason} ->
            {:error, {:read_failed, reason}}
        end
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

      {integrity, detail, new_prev, _new_sequence} =
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

      {_event, record} =
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

  # ------------------------------------------------------------------ state

  defp unavailable_state(file_path, reason, fault_injection, created?) do
    %__MODULE__{
      file_path: file_path,
      file_handle: nil,
      count: 0,
      last_digest: nil,
      last_sequence: nil,
      integrity: :unavailable,
      degraded: true,
      append_permitted: false,
      poisoned: false,
      integrity_issues: [:read_failed],
      diagnostics: empty_diagnostics(),
      read_error: reason,
      fault_injection: fault_injection,
      created_on_start: created?
    }
  end

  defp empty_diagnostics do
    %{
      unreadable: 0,
      truncated: false,
      integrity_failures: 0,
      sequence_gaps: 0,
      unverified_legacy: 0
    }
  end

  defp classify(diagnostics, records) do
    case diagnostic_categories(diagnostics) do
      [] -> if records == [], do: :empty_verified, else: :verified
      [single] -> single
      [_ | _] -> :recovery_required
    end
  end

  defp diagnostic_categories(diagnostics) do
    []
    |> maybe_category(:truncated, diagnostics.truncated)
    |> maybe_category(:integrity_failure, diagnostics.integrity_failures > 0)
    |> maybe_category(:sequence_gap, diagnostics.sequence_gaps > 0)
    |> maybe_category(:legacy_unverified, diagnostics.unverified_legacy > 0)
    |> Enum.reverse()
  end

  defp maybe_category(list, category, true), do: [category | list]
  defp maybe_category(list, _category, false), do: list

  defp diagnostics_any?(diagnostics) do
    diagnostics.unreadable > 0 or diagnostics.truncated or
      diagnostics.integrity_failures > 0 or diagnostics.sequence_gaps > 0 or
      diagnostics.unverified_legacy > 0
  end

  defp issues_for(integrity, _diagnostics) when integrity in [:verified, :empty_verified],
    do: []

  defp issues_for(_integrity, diagnostics), do: diagnostic_categories(diagnostics)

  @doc false
  def storage_reason(diagnostics, records) do
    cond do
      diagnostics.truncated -> :truncated_history
      diagnostics.integrity_failures > 0 -> failure_detail(records)
      diagnostics.sequence_gaps > 0 -> :sequence_gap
      diagnostics.unverified_legacy > 0 -> :unverified_legacy_record
      diagnostics.unreadable > 0 -> :unreadable_record
      true -> :unknown_history_integrity_failure
    end
  end

  @doc false
  def failure_detail(records) do
    case Enum.find(records, &(&1.integrity == :integrity_failure)) do
      %{detail: :chain_break} -> :chain_break
      %{detail: :digest_mismatch} -> :digest_mismatch
      _ -> :unreadable_record
    end
  end

  defp safe_event(bin) do
    {:ok, Tiannara.Executive.Event.from_binary(bin)}
  rescue
    _error -> :error
  end
end
