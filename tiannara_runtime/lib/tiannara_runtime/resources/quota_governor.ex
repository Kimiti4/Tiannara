defmodule TiannaraRuntime.Resources.QuotaGovernor do
  @moduledoc """
  Phase 5F.3.5 — Resource Quota Governor (System Metabolism Boundary)
  
  Enforces global + per-world resource limits to prevent runaway growth.
  
  ## Role
  
  Acts as the "entropy brake" for the system:
  - Prevents worlds from consuming unlimited memory/CPU
  - Throttles observer spawning when approaching limits
  - Escalates to CIS Supervisor on hard limit violations
  - Triggers ExecutionController kill path on critical limits
  
  ## Resource Types Tracked
  
  - Memory usage (bytes)
  - CPU time (milliseconds)
  - Observer count (integer)
  - Event rate (events/second)
  - World count (integer)
  
  ## Limit Levels
  
  1. **Soft Limit** → Throttling (slow down operations)
  2. **Hard Limit** → CIS escalation (request approval to continue)
  3. **Critical Limit** → ExecutionController kill path (immediate termination)
  
  ## Usage
  
      # Check quota before creating world
      case QuotaGovernor.check_world_creation_quota() do
        :approved -> create_world()
        :throttled -> delay_and_retry()
        :denied -> reject_creation()
      end
      
      # Update resource usage
      QuotaGovernor.update_usage(world_id, :memory, bytes_used)
      
      # Set custom limits for a world
      QuotaGovernor.set_world_limits(world_id, %{memory: 100_000_000, observers: 50})
  """

  use GenServer
  require Logger

  alias TiannaraRuntime.CIS.Supervisor, as: CISSup
  alias TiannaraRuntime.CIS.ExecutionController

  # ── Configuration ─────────────────────────────────────────────────────────

  @default_global_limits %{
    max_memory_bytes: 1_000_000_000,  # 1 GB total
    max_cpu_ms: 60_000,                # 60 seconds CPU time
    max_observers: 1000,               # Total observers across all worlds
    max_worlds: 100,                   # Maximum concurrent worlds
    max_event_rate: 10_000             # Events per second
  }

  @default_world_limits %{
    memory_bytes: 100_000_000,         # 100 MB per world
    cpu_ms: 5_000,                     # 5 seconds CPU per tick
    observers: 50,                     # Observers per world
    event_rate: 1_000                  # Events per second per world
  }

  # Threshold percentages
  @soft_limit_threshold 0.80    # 80% → throttling
  @hard_limit_threshold 0.95    # 95% → CIS escalation
  @critical_limit_threshold 1.0 # 100% → kill path

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    global_limits: @default_global_limits,
    world_limits: %{},              # %{world_id => limits}
    current_usage: %{               # Current resource usage
      memory_bytes: 0,
      cpu_ms: 0,
      observers: 0,
      worlds: 0,
      event_rate: 0
    },
    world_usage: %{},               # %{world_id => usage}
    throttle_flags: MapSet.new(),   # Worlds currently throttled
    violation_log: []               # Recent limit violations
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the QuotaGovernor GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Checks if a new world can be created within global quotas.
  
  Returns:
  - `:approved` — Within limits, proceed
  - `:throttled` — Approaching limits, slow down
  - `:denied` — Hard limit reached, reject
  """
  def check_world_creation_quota do
    GenServer.call(__MODULE__, :check_world_creation_quota)
  end

  @doc """
  Checks if an observer can be spawned in a specific world.
  """
  def check_observer_spawn_quota(world_id) do
    GenServer.call(__MODULE__, {:check_observer_quota, world_id})
  end

  @doc """
  Updates resource usage for a world.
  
  Triggers automatic limit checking and enforcement.
  """
  def update_usage(world_id, resource_type, amount) do
    GenServer.cast(__MODULE__, {:update_usage, world_id, resource_type, amount})
  end

  @doc """
  Sets custom limits for a specific world.
  """
  def set_world_limits(world_id, limits) do
    GenServer.cast(__MODULE__, {:set_world_limits, world_id, limits})
  end

  @doc """
  Gets current resource usage statistics.
  """
  def get_usage_stats do
    GenServer.call(__MODULE__, :get_usage_stats)
  end

  @doc """
  Gets quota status for a specific world.
  """
  def get_world_quota_status(world_id) do
    GenServer.call(__MODULE__, {:get_world_quota_status, world_id})
  end

  @doc """
  Resets usage counters (for testing/maintenance).
  """
  def reset_usage do
    GenServer.cast(__MODULE__, :reset_usage)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("⚖️  QuotaGovernor initialized (Phase 5F.3.5 Resource Thermodynamic Boundary)")

    state = %__MODULE__{
      global_limits: @default_global_limits,
      world_limits: %{},
      current_usage: %{
        memory_bytes: 0,
        cpu_ms: 0,
        observers: 0,
        worlds: 0,
        event_rate: 0
      },
      world_usage: %{},
      throttle_flags: MapSet.new(),
      violation_log: []
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:check_world_creation_quota, _from, state) do
    world_count = state.current_usage.worlds
    max_worlds = state.global_limits.max_worlds

    decision = evaluate_quota_decision(world_count, max_worlds, :worlds)

    case decision do
      :approved ->
        # Increment world count
        new_usage = put_in(state.current_usage.worlds, world_count + 1)
        {:reply, :approved, %{state | current_usage: new_usage}}

      :throttled ->
        Logger.warning("⚠️  World creation throttled (#{world_count}/#{max_worlds})")
        {:reply, :throttled, state}

      :denied ->
        Logger.error("🛑 World creation DENIED (limit reached: #{world_count}/#{max_worlds})")
        {:reply, :denied, state}
    end
  end

  @impl true
  def handle_call({:check_observer_quota, world_id}, _from, state) do
    world_limits = Map.get(state.world_limits, world_id, @default_world_limits)
    world_usage = Map.get(state.world_usage, world_id, default_world_usage())

    observer_count = world_usage.observers
    max_observers = world_limits.observers

    decision = evaluate_quota_decision(observer_count, max_observers, :observers)

    case decision do
      :approved ->
        new_usage = put_in(world_usage.observers, observer_count + 1)
        new_state = put_in(state.world_usage[world_id], new_usage)
        
        # Also update global observer count
        new_global = put_in(state.current_usage.observers, state.current_usage.observers + 1)
        final_state = %{new_state | current_usage: new_global}
        
        {:reply, :approved, final_state}

      :throttled ->
        Logger.warning("⚠️  Observer spawn throttled in #{world_id}")
        {:reply, :throttled, state}

      :denied ->
        Logger.error("🛑 Observer spawn DENIED in #{world_id} (limit reached)")
        {:reply, :denied, state}
    end
  end

  @impl true
  def handle_call(:get_usage_stats, _from, state) do
    stats = %{
      global_limits: state.global_limits,
      current_usage: state.current_usage,
      world_count: map_size(state.world_usage),
      throttled_worlds: MapSet.to_list(state.throttle_flags),
      recent_violations: Enum.take(state.violation_log, 10)
    }

    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_call({:get_world_quota_status, world_id}, _from, state) do
    world_limits = Map.get(state.world_limits, world_id, @default_world_limits)
    world_usage = Map.get(state.world_usage, world_id, default_world_usage())

    status = %{
      world_id: world_id,
      limits: world_limits,
      usage: world_usage,
      utilization: calculate_utilization(world_usage, world_limits)
    }

    {:reply, {:ok, status}, state}
  end

  @impl true
  def handle_cast({:update_usage, world_id, resource_type, amount}, state) do
    # Update world-specific usage
    world_usage = Map.get(state.world_usage, world_id, default_world_usage())
    updated_world_usage = update_resource_usage(world_usage, resource_type, amount)

    new_state = put_in(state.world_usage[world_id], updated_world_usage)

    # Check if limits exceeded
    world_limits = Map.get(new_state.world_limits, world_id, @default_world_limits)
    violation_level = check_violation_level(updated_world_usage, world_limits)

    final_state =
      case violation_level do
        :none ->
          new_state

        :soft ->
          Logger.warning("⚠️  Soft limit exceeded in #{world_id} for #{resource_type}")
          throttle_world(new_state, world_id)

        :hard ->
          Logger.error("🚨 Hard limit exceeded in #{world_id} for #{resource_type}")
          escalate_to_cis(world_id, resource_type, updated_world_usage, world_limits)
          new_state

        :critical ->
          Logger.error("☠️  CRITICAL limit exceeded in #{world_id} - initiating kill")
          trigger_kill_path(world_id, resource_type)
          new_state
      end

    {:noreply, final_state}
  end

  @impl true
  def handle_cast({:set_world_limits, world_id, limits}, state) do
    merged_limits = Map.merge(@default_world_limits, limits)
    new_limits = put_in(state.world_limits[world_id], merged_limits)

    Logger.info("Updated limits for #{world_id}: #{inspect(merged_limits)}")

    {:noreply, %{state | world_limits: new_limits}}
  end

  @impl true
  def handle_cast(:reset_usage, state) do
    Logger.info("Resetting all usage counters")

    reset_state = %{
      state
      | current_usage: %{
          memory_bytes: 0,
          cpu_ms: 0,
          observers: 0,
          worlds: 0,
          event_rate: 0
        },
        world_usage: %{},
        throttle_flags: MapSet.new()
    }

    {:noreply, reset_state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp evaluate_quota_decision(current, max, resource_type) do
    utilization = current / max

    cond do
      utilization >= @critical_limit_threshold ->
        :denied

      utilization >= @hard_limit_threshold ->
        :denied

      utilization >= @soft_limit_threshold ->
        :throttled

      true ->
        :approved
    end
  end

  defp default_world_usage do
    %{
      memory_bytes: 0,
      cpu_ms: 0,
      observers: 0,
      event_rate: 0
    }
  end

  defp update_resource_usage(usage, resource_type, amount) do
    case resource_type do
      :memory ->
        put_in(usage.memory_bytes, usage.memory_bytes + amount)

      :cpu ->
        put_in(usage.cpu_ms, usage.cpu_ms + amount)

      :observers ->
        put_in(usage.observers, usage.observers + amount)

      :event_rate ->
        put_in(usage.event_rate, amount)  # Replace, not add

      _ ->
        usage
    end
  end

  defp check_violation_level(usage, limits) do
    # Check each resource type for violations
    checks = [
      check_single_resource(usage.memory_bytes, limits.memory_bytes),
      check_single_resource(usage.observers, limits.observers),
      check_single_resource(usage.cpu_ms, limits.cpu_ms)
    ]

    # Return highest violation level
    cond do
      :critical in checks -> :critical
      :hard in checks -> :hard
      :soft in checks -> :soft
      true -> :none
    end
  end

  defp check_single_resource(current, max) do
    utilization = current / max

    cond do
      utilization >= @critical_limit_threshold -> :critical
      utilization >= @hard_limit_threshold -> :hard
      utilization >= @soft_limit_threshold -> :soft
      true -> :none
    end
  end

  defp calculate_utilization(usage, limits) do
    %{
      memory: usage.memory_bytes / limits.memory_bytes,
      observers: usage.observers / limits.observers,
      cpu: usage.cpu_ms / limits.cpu_ms
    }
  end

  defp throttle_world(state, world_id) do
    new_throttled = MapSet.put(state.throttle_flags, world_id)
    %{state | throttle_flags: new_throttled}
  end

  defp escalate_to_cis(world_id, resource_type, usage, limits) do
    reason = "Hard limit exceeded: #{resource_type} (#{inspect(usage)} / #{inspect(limits)})"

    # Request CIS approval to continue or terminate
    case CISSup.authorize_resource_termination(world_id, reason, :elevated) do
      :approve ->
        Logger.info("CIS approved continued operation for #{world_id} despite hard limit")

      :deny ->
        Logger.error("CIS denied operation for #{world_id} - triggering termination")
        trigger_kill_path(world_id, resource_type)

      :require_secondary_validation ->
        Logger.warning("CIS requires validation for #{world_id} - monitoring closely")
    end
  end

  defp trigger_kill_path(world_id, resource_type) do
    reason = "Critical resource limit exceeded: #{resource_type}"

    # Execute kill via ExecutionController (single authority chain)
    case ExecutionController.execute_kill(world_id, reason, :critical) do
      :executed ->
        Logger.error("☠️  World #{world_id} terminated due to critical resource violation")

      result ->
        Logger.error("Failed to terminate #{world_id}: #{inspect(result)}")
    end
  end
end
