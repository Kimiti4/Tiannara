defmodule Tiannara.OPC.RollbackManager do
  @moduledoc """
  Stage 7: OPC Rollback Manager
  
  Provides ontological reversibility.
  Before a new law is introduced to a topology (even a sandboxed one),
  this module takes a strict state snapshot. If the law causes catastrophic
  resonance, recursive instability, or topological inflation, this module
  evaporates the law and restores the branch to its precise pre-law state.
  """
  
  use GenServer
  require Logger
  
  # ── State ─────────────────────────────────────────────────────────────────
  
  defstruct [
    snapshots: %{} # %{tier_id => %{snapshot_id => state_dump}}
  ]
  
  # ── Public API ────────────────────────────────────────────────────────────
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Takes a snapshot of a given topology state before a law is applied.
  Returns `{:ok, snapshot_id}`.
  """
  def create_snapshot(tier_id, current_state) do
    GenServer.call(__MODULE__, {:create_snapshot, tier_id, current_state})
  end
  
  @doc """
  Evaporates a failed law by restoring the topology to a previous snapshot.
  """
  def rollback_to_snapshot(tier_id, snapshot_id) do
    GenServer.call(__MODULE__, {:rollback, tier_id, snapshot_id})
  end
  
  # ── GenServer Callbacks ───────────────────────────────────────────────────
  
  @impl true
  def init(_opts) do
    Logger.info("🛡️ [OPC Rollback] Manager initialized. Ontological reversibility active.")
    {:ok, %__MODULE__{snapshots: %{}}}
  end
  
  @impl true
  def handle_call({:create_snapshot, tier_id, current_state}, _from, state) do
    snapshot_id = Base.encode16(:crypto.strong_rand_bytes(8))
    
    tier_snapshots = Map.get(state.snapshots, tier_id, %{})
    updated_tier = Map.put(tier_snapshots, snapshot_id, current_state)
    updated_snapshots = Map.put(state.snapshots, tier_id, updated_tier)
    
    Logger.debug("[OPC Rollback] Created snapshot #{snapshot_id} for Tier #{tier_id}.")
    
    {:reply, {:ok, snapshot_id}, %{state | snapshots: updated_snapshots}}
  end
  
  @impl true
  def handle_call({:rollback, tier_id, snapshot_id}, _from, state) do
    Logger.warning("🚨 [OPC Rollback] Initiating catastrophic rollback for Tier #{tier_id} -> #{snapshot_id}!")
    
    tier_snapshots = Map.get(state.snapshots, tier_id, %{})
    
    case Map.get(tier_snapshots, snapshot_id) do
      nil ->
        Logger.error("[OPC Rollback] FATAL: Snapshot #{snapshot_id} not found! Rollback failed.")
        {:reply, {:error, :snapshot_not_found}, state}
        
      restored_state ->
        Logger.info("[OPC Rollback] ✅ Rollback successful. Law evaporated. Topology restored.")
        {:reply, {:ok, restored_state}, state}
    end
  end
end
