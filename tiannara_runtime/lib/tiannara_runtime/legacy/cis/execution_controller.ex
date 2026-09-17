defmodule TiannaraRuntime.Legacy.CIS.ExecutionController do
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
  alias TiannaraRuntime.WorldSupervisor
  alias Tiannara.Meta.ChronogramMatrix
  alias Tiannara.GCK.ChronogramGate

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
  Executes a generic action through the ExecutionController.

  Supported actions:
  - `:kill_world` — execute a CIS-approved world termination
  - `:terminate_resource` — execute resource cleanup
  - `:emergency_shutdown` — immediately trigger emergency shutdown
  """
  def execute(:kill_world, target_id, reason, severity) do
    case execute_kill(target_id, reason, severity) do
      :executed -> :ok
      :denied -> {:error, :denied_by_cis}
      :escalated -> {:error, :escalated_to_safety_cortex}
      other -> other
    end
  end

  def execute(:terminate_resource, target_id, reason, severity) do
    case terminate_resource(target_id, reason, severity) do
      :executed -> :ok
      :denied -> {:error, :denied}
      :escalated -> {:error, :escalated_to_safety_cortex}
      other -> other
    end
  end

  def execute(:emergency_shutdown, _target_id, reason, _severity), do: execute_emergency_shutdown(reason)
  def execute(_action, _target_id, _reason, _severity), do: {:error, :unsupported_action}

  # ── Phase 5F.4 Memory Pipeline ────────────────────────────────────────────

  @doc """
  Executes chronogram memory write with GCK validation.
  
  ## Flow
  
  1. Validate via GCK.ChronogramGate
  2. If approved → write to ChronogramMatrix
  3. If denied → log rejection and return error
  
  ## Returns
  
  - `{:ok, :written}` — Memory successfully written
  - `{:error, :gck_rejected, reason}` — GCK blocked the write
  
  ## Example
  
      state = %{
        coordinate: "world_event_001",
        data: "Important observation",
        entropy: 0.3,
        drift: 0.2
      }
      
      case ExecutionController.execute_memory_write("obs_001", state) do
        {:ok, :written} -> IO.puts("Memory stored")
        {:error, :gck_rejected, _reason} -> IO.puts("Blocked by GCK")
      end
  """
  def execute_memory_write(observer_id, causal_state) do
    GenServer.call(__MODULE__, {:execute_memory_write, observer_id, causal_state}, @execution_timeout_ms)
  end

  @doc """
  Executes chronogram memory read with GCK validation.
  
  ## Returns
  
  - `{:ok, {payload, amplitude}}` — Decoded memory with confidence
  - `{:empty, 0.0}` — No memory at coordinate
  - `{:error, :gck_rejected, reason}` — Read denied by GCK
  """
  def execute_memory_read(observer_id, coordinate) do
    GenServer.call(__MODULE__, {:execute_memory_read, observer_id, coordinate}, @execution_timeout_ms)
  end

  @doc """
  Registers a new observer in the chronogram system.
  
  ## Returns
  
  - `{:ok, mei}` — Observer registered with MEI frequency
  """
  def register_chronogram_observer(observer_id, parent_id \\ nil) do
    GenServer.call(__MODULE__, {:register_chronogram_observer, observer_id, parent_id}, @execution_timeout_ms)
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
        
        _execution_result = execute_world_termination(world_id, reason)
        
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
        
        _cleanup_result = execute_resource_cleanup(resource_id, reason)
        
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
  def handle_cast(:reset, state) do
    {:noreply, %{state |
      execution_log: [],
      total_executions: 0,
      total_denials: 0,
      active_operations: %{}
    }}
  end

  @impl true
  def handle_cast({:emergency_shutdown, reason}, state) do
    Logger.error("🚨 EMERGENCY SHUTDOWN INITIATED: #{reason}")

    # Broadcast shutdown to all supervisors
    broadcast_shutdown(reason)

    {:noreply, state}
  end

  # ── Phase 5F.4 Memory Pipeline Handlers ───────────────────────────────────

  @impl true
  def handle_call({:execute_memory_write, observer_id, causal_state}, _from, state) do
    # Step 1: Validate via GCK ChronogramGate
    case ChronogramGate.validate_write(observer_id, causal_state) do
      {:allow, :ok} ->
        Logger.debug("✅ GCK approved chronogram write for observer #{observer_id}")
        
        # Step 2: Write to ChronogramMatrix
        ChronogramMatrix.write(observer_id, causal_state)
        
        # Step 3: Log execution
        updated_state = log_execution(state, :memory_write, observer_id)
        
        {:reply, {:ok, :written}, updated_state}
      
      {:reject, reason} ->
        Logger.warning("🛑 GCK rejected chronogram write: #{reason}")
        {:reply, {:error, :gck_rejected, reason}, state}
    end
  end

  @impl true
  def handle_call({:execute_memory_read, observer_id, coordinate}, _from, state) do
    # Step 1: Validate via GCK ChronogramGate
    case ChronogramGate.validate_read(observer_id, coordinate) do
      {:allow, :ok} ->
        Logger.debug("✅ GCK approved chronogram read for observer #{observer_id}")
        
        # Step 2: Read from ChronogramMatrix
        result = ChronogramMatrix.read(observer_id, coordinate)
        
        # Step 3: Log execution
        updated_state = log_execution(state, :memory_read, observer_id)
        
        {:reply, result, updated_state}
      
      {status, reason} when status != :allow ->
        Logger.warning("🛑 GCK rejected chronogram read: #{inspect(reason)}")
        {:reply, {:error, :gck_rejected, reason}, state}
    end
  end

  @impl true
  def handle_call({:register_chronogram_observer, observer_id, parent_id}, _from, state) do
    # Register observer in ChronogramMatrix
    {:ok, mei} = ChronogramMatrix.register_observer(observer_id, parent_id)
    
    Logger.info("👁️ Chronogram observer registered: id=#{observer_id}, mei=#{:erlang.float_to_binary(mei, decimals: 6)}")
    
    # Log execution
    updated_state = log_execution(state, :observer_registration, observer_id)
    
    {:reply, {:ok, mei}, updated_state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp log_execution(state, operation_type, target_id) do
    # Simple logging for memory operations (lighter than full kill flow)
    Logger.debug("📝 ExecutionController logged: #{operation_type} for #{target_id}")
    
    # Update counters
    %{state | total_executions: state.total_executions + 1}
  end

  defp execute_world_termination(world_id, _reason) do
    case WorldSupervisor.stop_world(world_id) do
      :ok ->
        Logger.info("☠️  World #{world_id} termination command sent to WorldSupervisor")
        :ok

      {:error, :not_found} ->
        Logger.warning("World #{world_id} not found in WorldRegistry; assuming termination acknowledged")
        :ok

      {:error, reason} ->
        Logger.error("Failed to execute world termination: #{inspect(reason)}")
        :error
    end
  rescue
    e ->
      Logger.error("Failed to execute world termination: #{inspect(e)}")
      :error
  end

  defp execute_resource_cleanup(resource_id, _reason) do
    try do
      # TODO: Integrate with ResourceQuota module (to be implemented)
      Logger.info("🗑️  Resource #{resource_id} cleanup initiated")
      :ok
    rescue
      e ->
        Logger.error("Failed to execute resource cleanup: #{inspect(e)}")
        :error
    end
  end

  defp escalate_to_safety_cortex(target_id, _reason, _severity) do
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
