defmodule TiannaraRuntime.CIS.ExecutionController do
  @moduledoc """
  Phase 5F.3.5 — Execution Controller (Single Execution Authority)
  
  The ONLY allowed pathway for destructive operations.
  
  ## Authority Chain
  
      CIS Supervisor → ExecutionController → WorldSupervisor/ResourceQuota
  
  NOT:
      KillSwitch → WorldSupervisor ❌ (bypasses authority)
  
  ## Role
  
  Becomes the single decision lineage for:
  - Kill requests
  - World termination
  - Emergency shutdown
  - Resource destruction
  - Observer collapse enforcement
  
  ## Architecture Principle
  
  > CIS decides → ExecutionController executes → Systems comply
  
  This eliminates the "distributed cognition without central nervous system" problem.
  
  ## Usage
  
      # Approve and execute kill
      case ExecutionController.execute_kill(world_id, reason, :critical) do
        :executed -> Logger.info("World terminated")
        :denied -> Logger.error("Kill denied by CIS")
        :escalated -> Logger.warning("Escalated to Safety Cortex")
      end
      
      # Execute resource termination
      ExecutionController.terminate_resource(resource_id, :memory_limit_exceeded)
  """

  use GenServer
  require Logger

  alias TiannaraRuntime.CIS.Supervisor, as: CISSup
  alias TiannaraRuntime.MultiWorld.WorldSupervisor

  # ── Configuration ─────────────────────────────────────────────────────────

  @execution_timeout_ms 10_000
  @max_execution_log_size 500

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    execution_log: [],
    total_executions: 0,
    total_denials: 0,
    active_operations: %{}  # %{operation_id => {started_at, operation_type, target_id}}
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the ExecutionController GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Executes a kill operation (CIS-approved only).
  
  ## Flow
  
  1. Request CIS authorization
  2. If approved → execute termination via WorldSupervisor
  3. If denied → log and return
  4. If escalation needed → route to Safety Cortex
  
  ## Returns
  
  - `:executed` — Kill was authorized and executed
  - `:denied` — CIS denied the kill request
  - `:escalated` — Requires Safety Cortex review
  """
  def execute_kill(world_id, reason, severity \\ :critical) do
    GenServer.call(__MODULE__, {:execute_kill, world_id, reason, severity}, @execution_timeout_ms)
  end

  @doc """
  Executes resource termination (CIS-approved only).
  
  Used when ResourceQuota detects hard limit violations.
  """
  def terminate_resource(resource_id, reason, severity \\ :elevated) do
    GenServer.call(__MODULE__, {:terminate_resource, resource_id, reason, severity}, @execution_timeout_ms)
  end

  @doc """
  Executes emergency shutdown (immediate, no approval needed).
  
  ONLY used in catastrophic failure scenarios.
  """
  def execute_emergency_shutdown(reason) do
    GenServer.cast(__MODULE__, {:emergency_shutdown, reason})
    :shutdown_initiated
  end

  @doc """
  Gets execution statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @doc """
  Gets active operations (in-flight executions).
  """
  def get_active_operations do
    GenServer.call(__MODULE__, :get_active_operations)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("🎯 ExecutionController initialized (Phase 5F.3.5 Single Execution Authority)")

    state = %__MODULE__{
      execution_log: [],
      total_executions: 0,
      total_denials: 0,
      active_operations: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:execute_kill, world_id, reason, severity}, _from, state) do
    operation_id = generate_operation_id()
    started_at = DateTime.utc_now()

    # Track active operation
    new_state = put_in(state.active_operations[operation_id], {started_at, :kill, world_id})

    # Step 1: Request CIS authorization
    case CISSup.authorize_kill(world_id, reason, severity) do
      :approve ->
        # Step 2: Execute via WorldSupervisor
        Logger.info("✅ EXECUTING kill for #{world_id} (CIS approved)")
        
        result = execute_world_termination(world_id, reason)
        
        # Log execution
        log_entry = create_log_entry(operation_id, :kill, world_id, reason, :executed)
        final_state = update_execution_log(new_state, log_entry, :execution)
        
        {:reply, :executed, final_state}

      :deny ->
        Logger.error("🛑 KILL DENIED by CIS for #{world_id}: #{reason}")
        
        log_entry = create_log_entry(operation_id, :kill, world_id, reason, :denied)
        final_state = update_execution_log(new_state, log_entry, :denial)
        
        {:reply, :denied, final_state}

      :require_secondary_validation ->
        Logger.warning("⚠️ KILL ESCALATED for #{world_id}: #{reason}")
        
        # Escalate to Safety Cortex (future implementation)
        escalate_to_safety_cortex(world_id, reason, severity)
        
        log_entry = create_log_entry(operation_id, :kill, world_id, reason, :escalated)
        final_state = update_execution_log(new_state, log_entry, :escalation)
        
        {:reply, :escalated, final_state}
    end
  end

  @impl true
  def handle_call({:terminate_resource, resource_id, reason, severity}, _from, state) do
    operation_id = generate_operation_id()
    started_at = DateTime.utc_now()

    new_state = put_in(state.active_operations[operation_id], {started_at, :resource_termination, resource_id})

    # Request CIS authorization for resource termination
    case CISSup.authorize_resource_termination(resource_id, reason, severity) do
      :approve ->
        Logger.info("✅ EXECUTING resource termination for #{resource_id}")
        
        result = execute_resource_cleanup(resource_id, reason)
        
        log_entry = create_log_entry(operation_id, :resource_termination, resource_id, reason, :executed)
        final_state = update_execution_log(new_state, log_entry, :execution)
        
        {:reply, :executed, final_state}

      :deny ->
        Logger.error("🛑 RESOURCE TERMINATION DENIED for #{resource_id}")
        
        log_entry = create_log_entry(operation_id, :resource_termination, resource_id, reason, :denied)
        final_state = update_execution_log(new_state, log_entry, :denial)
        
        {:reply, :denied, final_state}

      :require_secondary_validation ->
        Logger.warning("⚠️ RESOURCE TERMINATION ESCALATED for #{resource_id}")
        
        escalate_to_safety_cortex(resource_id, reason, severity)
        
        log_entry = create_log_entry(operation_id, :resource_termination, resource_id, reason, :escalated)
        final_state = update_execution_log(new_state, log_entry, :escalation)
        
        {:reply, :escalated, final_state}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_executions: state.total_executions,
      total_denials: state.total_denials,
      active_operations: map_size(state.active_operations),
      recent_executions: Enum.take(state.execution_log, 10)
    }

    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_call(:get_active_operations, _from, state) do
    {:reply, {:ok, state.active_operations}, state}
  end

  @impl true
  def handle_cast({:emergency_shutdown, reason}, state) do
    Logger.error("🚨 EMERGENCY SHUTDOWN INITIATED: #{reason}")

    # Broadcast shutdown to all supervisors
    broadcast_shutdown(reason)

    {:noreply, state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp execute_world_termination(world_id, reason) do
    try do
      # Notify WorldSupervisor to terminate world
      send(WorldSupervisor, {:kill_world, world_id, :execution_controller_approved})

      Logger.info("☠️  World #{world_id} termination command sent to WorldSupervisor")
      :ok
    rescue
      e ->
        Logger.error("Failed to execute world termination: #{inspect(e)}")
        :error
    end
  end

  defp execute_resource_cleanup(resource_id, reason) do
    try do
      # TODO: Integrate with ResourceQuota module (to be implemented)
      Logger.info("🗑️  Resource #{resource_id} cleanup initiated: #{reason}")
      :ok
    rescue
      e ->
        Logger.error("Failed to execute resource cleanup: #{inspect(e)}")
        :error
    end
  end

  defp escalate_to_safety_cortex(target_id, reason, severity) do
    # TODO: Implement Safety Cortex integration (Phase 5F.2)
    Logger.warning("Escalating #{target_id} to Safety Cortex (not yet implemented)")
    
    # For now, just log the escalation
    # In production, this would send to Safety Cortex GenServer
  end

  defp broadcast_shutdown(reason) do
    # Send shutdown signal to all critical supervisors
    supervisors = [
      WorldSupervisor
      # Add more supervisors as system grows
    ]

    Enum.each(supervisors, fn supervisor ->
      try do
        send(supervisor, {:emergency_shutdown, reason})
      catch
        _, _ -> Logger.error("Failed to send shutdown to #{inspect(supervisor)}")
      end
    end)
  end

  defp create_log_entry(operation_id, operation_type, target_id, reason, outcome) do
    %{
      operation_id: operation_id,
      operation_type: operation_type,
      target_id: target_id,
      reason: reason,
      outcome: outcome,
      timestamp: DateTime.utc_now()
    }
  end

  defp update_execution_log(state, log_entry, outcome_type) do
    # Update counters
    new_state =
      case outcome_type do
        :execution ->
          %{state | total_executions: state.total_executions + 1}

        :denial ->
          %{state | total_denials: state.total_denials + 1}

        :escalation ->
          state  # Escalations tracked separately if needed
      end

    # Append to log (with size limit)
    updated_log = [log_entry | new_state.execution_log]
    trimmed_log = Enum.take(updated_log, @max_execution_log_size)

    # Remove from active operations
    operation_id = log_entry.operation_id
    cleaned_active = Map.delete(new_state.active_operations, operation_id)

    %{new_state | execution_log: trimmed_log, active_operations: cleaned_active}
  end

  defp generate_operation_id do
    "exec_#{System.unique_integer([:positive])}_#{System.system_time(:millisecond)}"
  end
end
