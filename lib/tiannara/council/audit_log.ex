defmodule Tiannara.Council.AuditLog do
  @moduledoc """
  Append-only, cryptographically chained audit log with Merkle root.

  Every entry contains:
    - A monotonic sequence number
    - The SHA-256 hash of the previous entry (chain integrity)
    - The action type (:amendment_proposed, :amendment_approved, :emergency_invoked, etc.)
    - The actor (human id, subsystem id, or :council)
    - The payload
    - A timestamp

  Periodic Merkle root is computed over all entries for distributed
  integrity verification.

  Storage: DETS (bootstrap). Migration path: Postgres WAL + Merkle tree.

  Resilience (D-A6/B5 fail-closed):
    - Single-writer lock file (exclusive create) blocks cross-process DETS open.
    - Opens DETS in strict mode first (repair: false) to detect corruption.
    - On corruption: archives (must succeed), attempts repair, verifies chain.
    - Never removes the authoritative file; unrecoverable cases stay degraded.
    - Operates in degraded mode if storage is unavailable (never crashes the app).
    - All corruption events are logged and recorded for forensic analysis.

  Constitutional Alignment (rules.md):
    - Hard invariant: audit_log_immutability
    - "Every architectural decision should remain traceable"
    - "Maintain audit trails"
    - "Recover gracefully" — degraded mode instead of crash
    - "Preserve previous stable states" — corrupted files are archived, not deleted
    - "Detect anomalies" — corruption is detected and reported explicitly
    - "Support reproducibility" — archived files enable forensic reconstruction
  """

  use GenServer
  require Logger

  @table :council_audit_log
  @merkle_interval :timer.minutes(5)

  # ---------- Client API ----------

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Appends an entry to the audit log.
  Returns {:ok, entry} or {:error, reason}.
  In degraded mode, returns {:error, :storage_degraded} without crashing.
  """
  def append(action, actor, payload) when is_atom(action) and not is_nil(actor) do
    GenServer.call(__MODULE__, {:append, action, actor, payload})
  end

  @doc "Returns the most recent N entries (newest first). Returns [] in degraded mode."
  def recent(n \\ 50), do: GenServer.call(__MODULE__, {:recent, n})

  @doc "Returns the chain tip. Returns genesis sentinel in degraded mode."
  def chain_tip, do: GenServer.call(__MODULE__, :chain_tip)

  @doc "Returns the current Merkle root. Returns nil in degraded mode."
  def merkle_root, do: GenServer.call(__MODULE__, :merkle_root)

  @doc """
  Verifies the entire hash chain.
  Returns :ok, {:error, broken_at_seq}, or {:error, :storage_degraded}.
  """
  def verify_integrity, do: GenServer.call(__MODULE__, :verify_integrity)

  @doc "Returns true if the audit log is operating in degraded mode."
  def degraded?, do: GenServer.call(__MODULE__, :degraded?)

  @doc "Returns the current storage status for observability dashboards."
  def storage_status, do: GenServer.call(__MODULE__, :storage_status)

  @doc "Returns the context-resolved DETS path used by the audit log."
  def dets_path, do: Tiannara.Storage.Paths.dets("council_audit_log")

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    case open_dets_safely() do
      {:ok, _table, lock_path} ->
        tip = load_chain_tip()
        schedule_merkle()
        Logger.info("AuditLog: opened successfully. Chain tip seq=#{tip.seq}")

        {:ok,
         %{
           tip: tip,
           merkle_root: nil,
           degraded: false,
           degradation_reason: nil,
           storage_available: true,
           lock_path: lock_path
         }}

      {:error, reason, lock_path} ->
        Logger.error(
          "AuditLog: storage unavailable (#{inspect(reason)}). Starting in degraded mode."
        )

        {:ok,
         %{
           tip: genesis_tip(),
           merkle_root: nil,
           degraded: true,
           degradation_reason: reason,
           storage_available: false,
           lock_path: lock_path
         }}

      {:error, reason} ->
        Logger.error(
          "AuditLog: storage unavailable (#{inspect(reason)}). Starting in degraded mode."
        )

        {:ok,
         %{
           tip: genesis_tip(),
           merkle_root: nil,
           degraded: true,
           degradation_reason: reason,
           storage_available: false,
           lock_path: nil
         }}
    end
  end

  @impl true
  def terminate(_reason, state) do
    case :dets.info(@table) do
      :undefined ->
        :ok

      _info ->
        :dets.sync(@table)
        :dets.close(@table)
    end

    if lock_path = state[:lock_path] do
      _ = File.rm(lock_path)
    end

    :ok
  rescue
    _ -> :ok
  end

  @impl true
  def handle_call({:append, _action, _actor, _payload}, _from, %{degraded: true} = state) do
    {:reply, {:error, :storage_degraded}, state}
  end

  def handle_call({:append, action, actor, payload}, _from, state) do
    new_seq = state.tip.seq + 1

    entry = %{
      seq: new_seq,
      prev_hash: state.tip.hash,
      action: action,
      actor: actor,
      payload: payload,
      timestamp: DateTime.utc_now(),
      hash: nil
    }

    hash = compute_hash(entry)
    entry = %{entry | hash: hash}

    case :dets.insert(@table, {new_seq, entry}) do
      :ok ->
        _ = :dets.sync(@table)

        :telemetry.execute([:tiannara, :council, :audit, :appended], %{seq: new_seq}, %{
          action: action,
          actor: actor
        })

        {:reply, {:ok, entry}, %{state | tip: entry}}

      {:error, reason} ->
        Logger.error("AuditLog: failed to insert entry seq=#{new_seq}: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:recent, _n}, _from, %{degraded: true} = state) do
    {:reply, [], state}
  end

  def handle_call({:recent, n}, _from, state) do
    entries =
      :dets.traverse(@table, fn {_seq, entry} -> {:continue, entry} end)
      |> Enum.sort_by(& &1.seq, :desc)
      |> Enum.take(n)

    {:reply, entries, state}
  end

  @impl true
  def handle_call(:chain_tip, _from, state), do: {:reply, state.tip, state}

  @impl true
  def handle_call(:merkle_root, _from, state), do: {:reply, state.merkle_root, state}

  @impl true
  def handle_call(:degraded?, _from, state), do: {:reply, state.degraded, state}

  @impl true
  def handle_call(:storage_status, _from, state) do
    {:reply,
     %{
       degraded: state.degraded,
       degradation_reason: state.degradation_reason,
       storage_available: state.storage_available,
       chain_tip_seq: state.tip.seq,
       merkle_root: state.merkle_root
     }, state}
  end

  @impl true
  def handle_call(:verify_integrity, _from, %{degraded: true} = state) do
    {:reply, {:error, :storage_degraded}, state}
  end

  def handle_call(:verify_integrity, _from, state) do
    entries =
      :dets.traverse(@table, fn {_seq, e} -> {:continue, e} end)
      |> Enum.sort_by(& &1.seq)

    {:reply, verify_chain_entries(entries), state}
  end

  @impl true
  def handle_info(:compute_merkle, %{degraded: true} = state) do
    schedule_merkle()
    {:noreply, state}
  end

  def handle_info(:compute_merkle, state) do
    hashes =
      :dets.traverse(@table, fn {_seq, e} -> {:continue, e.hash} end)
      |> Enum.sort()

    root = compute_merkle_root(hashes)

    :telemetry.execute([:tiannara, :council, :audit, :merkle_computed], %{}, %{
      root: Base.encode16(root, case: :lower),
      entry_count: length(hashes)
    })

    schedule_merkle()
    {:noreply, %{state | merkle_root: root}}
  end

  # ---------- Private: Resilient DETS Startup (D-A6/B5) ----------

  defp open_dets_safely do
    path = dets_path()
    File.mkdir_p!(Path.dirname(path))

    case acquire_writer_lock(path) do
      {:error, reason} ->
        {:error, {:writer_locked, reason}}

      {:ok, lock_path} ->
        case open_recovering(path) do
          {:ok, table} -> {:ok, table, lock_path}
          {:error, reason} -> {:error, reason, lock_path}
        end
    end
  end

  defp open_recovering(path) do
    case :dets.open_file(@table, type: :set, file: String.to_charlist(path), repair: false) do
      {:ok, table} ->
        case verify_table_chain(table) do
          :ok ->
            {:ok, table}

          {:error, seq} ->
            :dets.close(table)
            Logger.error("AuditLog: clean open but chain broken at seq=#{seq}. Recovering.")
            recover_after_detect(path, {:chain_broken, seq})
        end

      {:error, {:needs_repair, _}} ->
        Logger.warning("AuditLog: DETS file requires repair. Archiving corrupted file.")
        recover_after_detect(path, :needs_repair)

      {:error, :no_such_file} ->
        :dets.open_file(@table, type: :set, file: String.to_charlist(path), repair: true)

      {:error, reason} ->
        recover_after_detect(path, {:open_failed, reason})
    end
  end

  # Archive must succeed before any mutation. Never File.rm the original.
  # After repair, chain must verify or we fail closed to degraded.
  defp recover_after_detect(path, cause) do
    case archive_corrupted_file(path) do
      {:ok, archive_path} ->
        case :dets.open_file(@table, type: :set, file: String.to_charlist(path), repair: true) do
          {:ok, table} ->
            case verify_table_chain(table) do
              :ok ->
                Logger.info("AuditLog: repaired and chain-verified. Archive=#{archive_path}")
                record_corruption_event({:repaired, cause, archive_path})
                {:ok, table}

              {:error, seq} ->
                _ = :dets.close(table)
                record_corruption_event({:repair_integrity_failed, cause, archive_path, seq})
                {:error, {:repair_integrity_failed, cause, seq, archive_path}}
            end

          {:error, repair_reason} ->
            record_corruption_event(
              {:repair_failed_preserved, cause, archive_path, repair_reason}
            )

            {:error, {:repair_failed, cause, repair_reason, archive_path}}
        end

      {:error, archive_error} ->
        record_corruption_event({:archive_failed, cause, archive_error})
        {:error, {:archive_failed, cause, archive_error}}
    end
  end

  defp writer_lock_path(path), do: path <> ".lock"

  defp acquire_writer_lock(path, attempts \\ 0)

  defp acquire_writer_lock(_path, attempts) when attempts > 3 do
    {:error, :lock_steal_exhausted}
  end

  defp acquire_writer_lock(path, attempts) do
    lock_path = writer_lock_path(path)

    payload =
      "#{:os.getpid()} #{node()} #{:erlang.pid_to_list(self())} #{System.system_time(:second)}"

    case File.open(lock_path, [:write, :exclusive]) do
      {:ok, io} ->
        IO.binwrite(io, payload)
        File.close(io)
        {:ok, lock_path}

      {:error, :eexist} ->
        case stale_writer_lock?(lock_path) do
          true ->
            _ = File.rm(lock_path)
            acquire_writer_lock(path, attempts + 1)

          false ->
            {:error, {:held, File.read(lock_path) |> elem(1)}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Stale only when the OS pid is dead (holder BEAM gone) or the holder
  # pid was written by THIS node and that process is dead (same-VM restart
  # after a brutal kill). A live foreign-node lock is never stolen.
  defp stale_writer_lock?(lock_path) do
    case File.read(lock_path) do
      {:ok, data} ->
        case String.split(String.trim(data), " ") do
          [os_pid, owner_node, epid_str | _] ->
            cond do
              os_pid_dead?(os_pid) ->
                true

              owner_node == Atom.to_string(node()) and local_epid_dead?(epid_str) ->
                true

              true ->
                false
            end

          _ ->
            true
        end

      _ ->
        true
    end
  end

  defp os_pid_dead?(pid_str) when is_binary(pid_str) and pid_str != "" do
    case :os.type() do
      {:win32, _} ->
        {out, _} =
          System.cmd("tasklist", ["/FI", "PID eq #{pid_str}", "/NH"], stderr_to_stdout: true)

        not (String.contains?(out, pid_str) and not String.contains?(out, "No tasks"))

      _ ->
        case System.cmd("kill", ["-0", pid_str], stderr_to_stdout: true) do
          {_out, 0} -> false
          _ -> true
        end
    end
  rescue
    _ -> false
  end

  defp os_pid_dead?(_), do: true

  defp local_epid_dead?(epid_str) when is_binary(epid_str) and epid_str != "" do
    formatted =
      case String.trim(epid_str) do
        <<"<", _::binary>> = s -> s
        s -> "<" <> s <> ">"
      end

    pid =
      try do
        :erlang.list_to_pid(String.to_charlist(formatted))
      rescue
        _ -> nil
      end

    cond do
      is_nil(pid) -> false
      :erlang.node(pid) != node() -> false
      true -> not Process.alive?(pid)
    end
  end

  defp local_epid_dead?(_), do: false

  defp verify_table_chain(table) do
    entries =
      :dets.traverse(table, fn {_seq, e} -> {:continue, e} end)
      |> Enum.sort_by(& &1.seq)

    verify_chain_entries(entries)
  end

  defp verify_chain_entries(entries) do
    result =
      Enum.reduce_while(entries, %{genesis: true, prev_hash: nil}, fn entry, acc ->
        chain_ok =
          if acc.genesis do
            is_nil(entry.prev_hash) or entry.prev_hash == <<0::256>>
          else
            entry.prev_hash == acc.prev_hash
          end

        recomputed = compute_hash(%{entry | hash: nil})
        hash_matches = recomputed == entry.hash

        if chain_ok and hash_matches do
          {:cont, %{genesis: false, prev_hash: entry.hash}}
        else
          {:halt, {:error, entry.seq}}
        end
      end)

    case result do
      {:error, _} = e -> e
      _ -> :ok
    end
  end

  defp archive_corrupted_file(path) do
    timestamp =
      DateTime.utc_now()
      |> DateTime.to_iso8601()
      |> String.replace(":", "-")
      |> String.replace(".", "-")

    archive_path = "#{path}.corrupted.#{timestamp}"

    case File.cp(path, archive_path) do
      :ok ->
        Logger.info("AuditLog: corrupted file archived to #{archive_path}")
        {:ok, archive_path}

      {:error, reason} ->
        Logger.error("AuditLog: failed to archive corrupted file: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp record_corruption_event(outcome) do
    Logger.info("AuditLog: corruption event outcome=#{inspect(outcome)} path=#{dets_path()}")

    spawn(fn ->
      try do
        Tiannara.CEL.Services.ExecutiveMemory.record_decision(
          "audit_log_corruption_#{DateTime.utc_now() |> DateTime.to_unix()}",
          :audit_log_corruption_detected,
          %{original_path: dets_path(), outcome: outcome, detected_at: DateTime.utc_now()}
        )
      rescue
        _ -> :ok
      catch
        :exit, _ -> :ok
      end
    end)

    :telemetry.execute([:tiannara, :council, :audit, :corruption_detected], %{}, %{
      outcome: outcome,
      path: dets_path()
    })
  end

  # ---------- Private: Chain & Merkle ----------

  defp genesis_tip do
    %{
      seq: 0,
      hash: <<0::256>>,
      action: :genesis,
      actor: :system,
      payload: %{},
      timestamp: ~U[2026-07-24 00:00:00Z]
    }
  end

  defp load_chain_tip do
    case :dets.traverse(@table, fn {_seq, e} -> {:continue, e} end) do
      [] -> genesis_tip()
      entries -> entries |> Enum.sort_by(& &1.seq) |> List.last()
    end
  end

  defp compute_hash(%{hash: nil} = e) do
    :crypto.hash(
      :sha256,
      :erlang.term_to_binary({e.seq, e.prev_hash, e.action, e.actor, e.timestamp, e.payload})
    )
  end

  defp compute_merkle_root([]), do: <<0::256>>
  defp compute_merkle_root([single]), do: single

  defp compute_merkle_root(hashes) do
    hashes
    |> Enum.chunk_every(2)
    |> Enum.map(fn
      [a, b] -> :crypto.hash(:sha256, a <> b)
      [a] -> :crypto.hash(:sha256, a <> a)
    end)
    |> compute_merkle_root()
  end

  defp schedule_merkle, do: Process.send_after(self(), :compute_merkle, @merkle_interval)
end
