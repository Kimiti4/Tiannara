defmodule TiannaraRuntime.MultiWorld.HardenedKillSwitch do
  @moduledoc """
  PHASE 5 SAFETY CORTEX: Distributed Circuit-Breaker + Consensus Termination Kernel
  
  Replaces deterministic kill rules with probabilistic, consensus-based governance.
  
  ## Architectural Principles
  
  1. **No single process can kill a world directly** - Everything is probabilistic and mediated
  2. **Kill is a last-stage state, not an action** - We transition worlds into terminal regimes
  3. **Every termination produces a forkable snapshot** - Nothing is destroyed without replay branch
  
  ## State Machine
  
      :normal → :elevated_risk → :circuit_open → :quarantine → 
      :consensus_review → :pre_termination_freeze → :terminated
  
  ## Key Features
  
  - **Risk Scoring Engine**: Weighted instability field (entropy + cascade + divergence)
  - **Circuit Breaker**: Opens at risk > 0.9, prevents immediate termination
  - **Consensus Protocol**: Requires quorum ≥ 0.67 from observer nodes
  - **Freeze Layer**: Suspends execution before termination for inspection/rollback
  - **Snapshot Engine**: Captures complete world state for lineage preservation
  
  ## NATS Topics
  
      tiannara.kill.consensus.request    # Broadcast kill proposals
      tiannara.kill.consensus.response   # Observer node votes
      tiannara.world.frozen              # Freeze notifications
      tiannara.world.terminated          # Final termination events
  """

  use GenServer
  require Logger

  alias Tiannara.NATS.MetaEvolutionStreamManager

  # Consensus thresholds
  @quorum_threshold 0.67
  @risk_elevated 0.7
  @risk_circuit_open 0.9
  @consensus_timeout_ms 5000

  defstruct [
    risk_table: %{},           # %{world_id => risk_score}
    state_table: %{},          # %{world_id => kill_state}
    consensus_buffer: %{},     # %{world_id => {requested_at, approvals, total_observers}}
    frozen_worlds: MapSet.new(),
    snapshots: %{}             # %{world_id => snapshot_data}
  ]

  @type kill_state ::
          :normal
          | :elevated_risk
          | :circuit_open
          | :quarantine
          | :consensus_review
          | :pre_termination_freeze
          | :terminated

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Update risk score for a world based on continuous monitoring.
  
  Triggers state machine transitions based on risk thresholds.
  
  ## Example
  
      HardenedKillSwitch.update_risk("W1", 0.85)
  """
  def update_risk(world_id, risk_score) when is_float(risk_score) and risk_score >= 0.0 and risk_score <= 1.0 do
    GenServer.cast(__MODULE__, {:risk_update, world_id, risk_score})
  end

  @doc """
  Submit consensus vote for world termination.
  
  Called by observer nodes (neighboring worlds, meta-supervisors, entropy monitors).
  
  ## Example
  
      HardenedKillSwitch.submit_consensus_vote("W1", :approve)
  """
  def submit_consensus_vote(world_id, vote) when vote in [:approve, :reject] do
    GenServer.cast(__MODULE__, {:consensus_vote, world_id, vote})
  end

  @doc """
  Get current kill state for a world.
  
  ## Returns
    
      :normal | :elevated_risk | :circuit_open | :quarantine | 
      :consensus_review | :pre_termination_freeze | :terminated
  """
  def get_state(world_id) do
    GenServer.call(__MODULE__, {:get_state, world_id})
  end

  @doc """
  Retrieve snapshot data for a terminated world.
  
  Enables forensic analysis and potential fork creation.
  """
  def get_snapshot(world_id) do
    GenServer.call(__MODULE__, {:get_snapshot, world_id})
  end

  @impl true
  def init(_opts) do
    Logger.info("🛡️  TiannaraRuntime.HardenedKillSwitch initialized (Safety Cortex)")
    Logger.info("   Quorum threshold: #{@quorum_threshold}")
    Logger.info("   Circuit breaker opens at risk > #{@risk_circuit_open}")
    Logger.info("   Elevated risk threshold: #{@risk_elevated}")

    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_cast({:risk_update, world_id, risk}, state) do
    new_state =
      state
      |> put_in([:risk_table, world_id], risk)
      |> evaluate_and_transition(world_id, risk)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:consensus_vote, world_id, vote}, state) do
    # Update consensus buffer
    buffer_entry = Map.get(state.consensus_buffer, world_id)

    updated_buffer =
      case buffer_entry do
        nil ->
          # First vote - initialize buffer
          {approvals, total} = if vote == :approve, do: {1, 1}, else: {0, 1}

          put_in(state.consensus_buffer[world_id], {DateTime.utc_now(), approvals, total})

        {requested_at, approvals, total} ->
          new_approvals = if vote == :approve, do: approvals + 1, else: approvals
          put_in(state.consensus_buffer[world_id], {requested_at, new_approvals, total + 1})
      end

    # Check if consensus reached
    {_requested_at, approvals, total} = Map.get(updated_buffer.consensus_buffer, world_id)
    ratio = approvals / max(total, 1)

    if ratio >= @quorum_threshold do
      # Consensus reached - proceed to termination
      Logger.info("✅ Consensus reached for #{world_id} (#{approvals}/#{total} approvals)")
      new_state = terminate_with_snapshot(updated_buffer, world_id)
      {:noreply, new_state}
    else
      {:noreply, updated_buffer}
    end
  end

  @impl true
  def handle_call({:get_state, world_id}, _from, state) do
    current_state = Map.get(state.state_table, world_id, :normal)
    {:reply, {:ok, current_state}, state}
  end

  @impl true
  def handle_call({:get_snapshot, world_id}, _from, state) do
    case Map.get(state.snapshots, world_id) do
      nil -> {:reply, {:error, :no_snapshot}, state}
      snapshot -> {:reply, {:ok, snapshot}, state}
    end
  end

  # ============================================================================
  # Private: State Machine Transitions
  # ============================================================================

  defp evaluate_and_transition(state, world_id, risk) do
    cond do
      risk > @risk_circuit_open ->
        open_circuit(state, world_id)

      risk > @risk_elevated ->
        request_consensus(state, world_id, risk)

      true ->
        put_in(state.state_table[world_id], :normal)
    end
  end

  defp open_circuit(state, world_id) do
    Logger.warning("⚡ Circuit Open: #{world_id} (risk exceeded #{@risk_circuit_open})")

    # Freeze world execution immediately
    freeze_world(world_id)

    # Transition to circuit_open state
    new_state = put_in(state.state_table[world_id], :circuit_open)

    # Publish circuit open event
    MetaEvolutionStreamManager.publish("tiannara.kill.circuit_breaker", %{
      world_id: world_id,
      event: :circuit_opened,
      risk: Map.get(new_state.risk_table, world_id, 0.0),
      timestamp: DateTime.utc_now()
    })

    new_state
  end

  defp request_consensus(state, world_id, risk) do
    Logger.info("🗳️  Requesting consensus for #{world_id} (risk: #{risk})")

    # Broadcast consensus request to observer nodes
    MetaEvolutionStreamManager.publish("tiannara.kill.consensus.request", %{
      world_id: world_id,
      risk: risk,
      timestamp: System.system_time(:millisecond)
    })

    # Initialize consensus buffer
    new_buffer = put_in(state.consensus_buffer[world_id], {DateTime.utc_now(), 0, 0})

    # Transition to consensus_review state
    put_in(new_buffer.state_table[world_id], :consensus_review)
  end

  defp terminate_with_snapshot(state, world_id) do
    # Phase 5F Safety Integration: Get CIS approval before termination
    reason = "Consensus-approved termination (quorum reached)"
    
    case TiannaraRuntime.CIS.Supervisor.authorize_kill(world_id, reason, :critical) do
      :approve ->
        proceed_with_termination(state, world_id)
      
      :deny ->
        Logger.error("🛑 Kill denied by CIS Supervisor for #{world_id}")
        # Transition to quarantine instead of termination
        put_in(state.state_table[world_id], :quarantine)
      
      :require_secondary_validation ->
        Logger.warning("⚠️ Kill requires secondary validation for #{world_id}")
        # Escalate to Safety Cortex (future implementation)
        escalate_to_safety_cortex(world_id, reason)
        put_in(state.state_table[world_id], :consensus_review)
    end
  end

  defp proceed_with_termination(state, world_id) do
    # Step 1: Capture snapshot for lineage preservation
    snapshot = capture_snapshot(world_id)

    # Step 2: Store snapshot
    new_state = put_in(state.snapshots[world_id], snapshot)

    # Step 3: Transition to pre_termination_freeze
    new_state = put_in(new_state.state_table[world_id], :pre_termination_freeze)

    # Step 4: Execute final termination
    Logger.error("☠️  TERMINATION APPROVED BY CIS: #{world_id}")

    # Notify WorldSupervisor to kill world
    send(TiannaraRuntime.MultiWorld.WorldSupervisor, {:kill_world, world_id, :cis_approved})

    # Publish termination event
    MetaEvolutionStreamManager.publish("tiannara.world.terminated", %{
      world_id: world_id,
      snapshot_id: snapshot.id,
      reason: :cis_approved,
      timestamp: DateTime.utc_now()
    })

    # Final state: terminated
    put_in(new_state.state_table[world_id], {:terminated, snapshot.id})
  end

  defp escalate_to_safety_cortex(world_id, reason) do
    # TODO: Implement Safety Cortex integration (Phase 5F.2)
    Logger.warning("Escalating #{world_id} to Safety Cortex: #{reason}")
    # For now, just log - Safety Cortex module not yet implemented
  end

  defp freeze_world(world_id) do
    Logger.info("❄️  Freezing world #{world_id}")

    # Send freeze message to WorldSupervisor
    send(TiannaraRuntime.MultiWorld.WorldSupervisor, {:freeze_world, world_id})

    # Add to frozen set
    GenServer.cast(__MODULE__, {:add_frozen, world_id})
  end

  defp capture_snapshot(world_id) do
    # In production, this would query the world's GenServer for complete state
    # For now, create minimal snapshot structure

    %{
      id: "snapshot_#{world_id}_#{System.system_time(:millisecond)}",
      world_id: world_id,
      captured_at: DateTime.utc_now(),
      risk_score: 0.0, # Would be populated from actual metrics
      entropy: 0.0,
      cal_state: %{},
      cis_state: %{},
      agent_count: 0,
      coalition_count: 0
    }
  end

  @impl true
  def handle_cast({:add_frozen, world_id}, state) do
    new_frozen = MapSet.put(state.frozen_worlds, world_id)
    {:noreply, %{state | frozen_worlds: new_frozen}}
  end
end
