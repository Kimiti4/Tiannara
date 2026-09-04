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

  Resilience:
    - Opens DETS in strict mode first (repair: false) to detect corruption.
    - On corruption: archives the damaged file, attempts repair, or starts fresh.
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
  @file_path ~c"./council_audit_log.dets"
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

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    case open_dets_safely() do
      {:ok, _table} ->
        tip = load_chain_tip()
        schedule_merkle()
        Logger.info("AuditLog: opened successfully. Chain tip seq=#{tip.seq}")

        {:ok, %{
          tip: tip, merkle_root: nil, degraded: false,
          degradation_reason: nil, storage_available: true
        }}

      {:error, reason} ->
        Logger.error("AuditLog: storage unavailable (#{inspect(reason)}). Starting in degraded mode.")

        {:ok, %{
          tip: genesis_tip(), merkle_root: nil, degraded: true,
          degradation_reason: reason, storage_available: false
        }}
    end
  end

  @impl true
  def handle_call({:append, _action, _actor, _payload}, _from, %{degraded: true} = state) do
    {:reply, {:error, :storage_degraded}, state}
  end

  def handle_call({:append, action, actor, payload}, _from, state) do
    new_seq = state.tip.seq + 1

    entry = %{
      seq: new_seq, prev_hash: state.tip.hash, action: action, actor: actor,
      payload: payload, timestamp: DateTime.utc_now(), hash: nil
    }

    hash = compute_hash(entry)
    entry = %{entry | hash: hash}

    case :dets.insert(@table, {new_seq, entry}) do
      :ok ->
        :telemetry.execute([:tiannara, :council, :audit, :appended], %{seq: new_seq}, %{
          action: action, actor: actor
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
    {:reply, %{
      degraded: state.degraded, degradation_reason: state.degradation_reason,
      storage_available: state.storage_available,
      chain_tip_seq: state.tip.seq, merkle_root: state.merkle_root
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

    reply = case result do
      {:error, _} = e -> e
      _ -> :ok
    end

    {:reply, reply, state}
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
      root: Base.encode16(root, case: :lower), entry_count: length(hashes)
    })

    schedule_merkle()
    {:noreply, %{state | merkle_root: root}}
  end

  # ---------- Private: Resilient DETS Startup ----------

  defp open_dets_safely do
    case :dets.open_file(@table, type: :set, file: @file_path, repair: false) do
      {:ok, table} ->
        {:ok, table}

      {:error, {:needs_repair, _}} ->
        Logger.warning("AuditLog: DETS file requires repair. Archiving corrupted file.")
        archive_corrupted_file()

        case :dets.open_file(@table, type: :set, file: @file_path, repair: true) do
          {:ok, table} ->
            Logger.info("AuditLog: repaired successfully. Previous file archived for forensics.")
            record_corruption_event(:repaired)
            {:ok, table}

          {:error, repair_reason} ->
            Logger.error("AuditLog: repair failed (#{inspect(repair_reason)}). Removing and starting fresh.")
            File.rm(@file_path)
            record_corruption_event(:repair_failed_and_removed)

            case :dets.open_file(@table, type: :set, file: @file_path, repair: true) do
              {:ok, table} -> {:ok, table}
              {:error, fresh_reason} -> {:error, fresh_reason}
            end
        end

      {:error, :no_such_file} ->
        :dets.open_file(@table, type: :set, file: @file_path, repair: true)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp archive_corrupted_file do
    timestamp =
      DateTime.utc_now()
      |> DateTime.to_iso8601()
      |> String.replace(":", "-")
      |> String.replace(".", "-")

    archive_path = "#{@file_path}.corrupted.#{timestamp}"

    case File.cp(to_string(@file_path), archive_path) do
      :ok ->
        Logger.info("AuditLog: corrupted file archived to #{archive_path}")

      {:error, reason} ->
        Logger.error("AuditLog: failed to archive corrupted file: #{inspect(reason)}")
    end
  end

  defp record_corruption_event(outcome) do
    Logger.info("AuditLog: corruption event outcome=#{outcome} path=#{@file_path}")

    spawn(fn ->
      try do
        Tiannara.CEL.Services.ExecutiveMemory.record_decision(
          "audit_log_corruption_#{DateTime.utc_now() |> DateTime.to_unix()}",
          :audit_log_corruption_detected,
          %{original_path: to_string(@file_path), outcome: outcome, detected_at: DateTime.utc_now()}
        )
      rescue
        _ -> :ok
      catch
        :exit, _ -> :ok
      end
    end)

    :telemetry.execute([:tiannara, :council, :audit, :corruption_detected], %{}, %{
      outcome: outcome, path: to_string(@file_path)
    })
  end

  # ---------- Private: Chain & Merkle ----------

  defp genesis_tip do
    %{seq: 0, hash: <<0::256>>, action: :genesis, actor: :system, payload: %{},
      timestamp: ~U[2026-07-24 00:00:00Z]}
  end

  defp load_chain_tip do
    case :dets.traverse(@table, fn {_seq, e} -> {:continue, e} end) do
      [] -> genesis_tip()
      entries -> entries |> Enum.sort_by(& &1.seq) |> List.last()
    end
  end

  defp compute_hash(%{hash: nil} = e) do
    :crypto.hash(:sha256, :erlang.term_to_binary({e.seq, e.prev_hash, e.action, e.actor, e.timestamp, e.payload}))
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
