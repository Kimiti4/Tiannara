defmodule Tiannara.Meta.OPC.Runtime.RollbackManager do
  @moduledoc """
  Phase 5F.6 — Rollback Manager

  Manages snapshot-based rollback of observer manifold state when a GPU
  execution produces an unstable or paradox-generating result.

  Snapshots are stored in-process as an ETS table keyed by snapshot ID.
  In production this would persist to the Chronogram substrate.

  ## Usage

      {:ok, snap_id} = RollbackManager.snapshot("obs_001", state)
      {:ok, state}   = RollbackManager.rollback(snap_id)
  """

  use GenServer
  require Logger

  @table :opc_rollback_snapshots

  # ── Public API ────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Creates a snapshot of the given observer state.

  ## Returns
  - `{:ok, snapshot_id}` — Snapshot stored successfully
  """
  def snapshot(observer_id, state) do
    GenServer.call(__MODULE__, {:snapshot, observer_id, state})
  end

  @doc """
  Rolls back to a previously stored snapshot.

  ## Returns
  - `{:ok, state}` — Snapshot found and returned
  - `{:error, :not_found}` — No snapshot with that ID
  """
  def rollback(snapshot_id) do
    GenServer.call(__MODULE__, {:rollback, snapshot_id})
  end

  @doc "Lists all snapshot IDs currently held."
  def list_snapshots do
    GenServer.call(__MODULE__, :list_snapshots)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :set, :public])
    Logger.info("🔄 [RollbackManager] Initialized (ETS table: #{@table})")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:snapshot, observer_id, state}, _from, srv_state) do
    snap_id = "snap_#{observer_id}_#{System.unique_integer([:positive, :monotonic])}"
    record = %{observer_id: observer_id, state: state, created_at: System.system_time(:millisecond)}
    :ets.insert(@table, {snap_id, record})
    Logger.debug("📸 [RollbackManager] Snapshot #{snap_id} created")
    {:reply, {:ok, snap_id}, srv_state}
  end

  @impl true
  def handle_call({:rollback, snapshot_id}, _from, srv_state) do
    case :ets.lookup(@table, snapshot_id) do
      [{^snapshot_id, record}] ->
        Logger.info("⏪ [RollbackManager] Rolling back to #{snapshot_id}")
        {:reply, {:ok, record.state}, srv_state}

      [] ->
        Logger.warning("🛑 [RollbackManager] Snapshot #{snapshot_id} not found")
        {:reply, {:error, :not_found}, srv_state}
    end
  end

  @impl true
  def handle_call(:list_snapshots, _from, srv_state) do
    ids = :ets.tab2list(@table) |> Enum.map(fn {id, _} -> id end)
    {:reply, {:ok, ids}, srv_state}
  end
end
