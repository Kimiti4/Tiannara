defmodule TiannaraRuntime.MultiWorld.KillSwitch do
  @moduledoc """
  Phase 5F.3.5 — Unified KillSwitch (Execution Layer Only)
  
  Consolidates HardenedKillSwitch + KillSwitchCausal into single module.
  
  ## Architecture Change
  
  BEFORE (fragmented):
  - HardenedKillSwitch → direct termination (bypasses CIS)
  - KillSwitchCausal → causal-based termination (separate logic)
  
  AFTER (unified):
  - KillSwitch → ExecutionController → CIS Supervisor → WorldSupervisor
  
  ## Role
  
  KillSwitch is now ONLY an execution layer:
  - Receives kill requests from various sources
  - Delegates ALL decisions to ExecutionController
  - No autonomous authority
  
  ## Authority Chain
  
      Monitoring Systems → KillSwitch → ExecutionController → CIS → WorldSupervisor
  
  NOT:
      KillSwitch → WorldSupervisor ❌ (bypasses entire safety chain)
  
  ## Usage
  
      # Request world termination
      KillSwitch.request_termination(world_id, reason, :critical)
      
      # Emergency kill (still goes through ExecutionController)
      KillSwitch.emergency_kill(world_id, "catastrophic failure")
      
      # Check kill status
      {:ok, status} = KillSwitch.get_kill_status(world_id)
  """

  use GenServer
  require Logger

  alias TiannaraRuntime.CIS.ExecutionController

  # ── Configuration ─────────────────────────────────────────────────────────

  @kill_request_timeout_ms 10_000

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    kill_requests: %{},              # %{world_id => {requested_at, reason, severity}}
    total_requests: 0,
    total_executed: 0,
    total_denied: 0
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the unified KillSwitch GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Requests world termination (delegates to ExecutionController).
  
  This is the ONLY entry point for kill operations.
  
  ## Parameters
  - `world_id`: World to terminate
  - `reason`: Human-readable reason
  - `severity`: `:normal`, `:elevated`, `:critical`, `:emergency`
  
  ## Returns
  - `:request_accepted` — Request forwarded to ExecutionController
  """
  def request_termination(world_id, reason, severity \\ :critical) do
    GenServer.cast(__MODULE__, {:request_termination, world_id, reason, severity})
    :requested
  end

  @doc """
  Emergency kill (immediate request, still requires ExecutionController approval).
  
  Used in catastrophic failure scenarios.
  """
  def emergency_kill(world_id, reason) do
    Logger.error("🚨 EMERGENCY KILL REQUESTED for #{world_id}: #{reason}")
    request_termination(world_id, reason, :emergency)
  end

  @doc """
  Emergency shutdown from the unified KillSwitch.
  
  This routes the emergency path through the ExecutionController.
  """
  def emergency_shutdown(world_id, reason) do
    Logger.error("🚨 EMERGENCY SHUTDOWN REQUESTED for #{world_id}: #{reason}")
    ExecutionController.execute_emergency_shutdown(reason)
    :initiated
  end

  @doc """
  Gets kill status for a world.
  """
  def get_kill_status(world_id) do
    GenServer.call(__MODULE__, {:get_status, world_id})
  end

  @doc """
  Gets KillSwitch statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @doc """
  Cancels pending kill request.
  """
  def cancel_request(world_id) do
    GenServer.cast(__MODULE__, {:cancel_request, world_id})
    :cancelled
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("🔪 Unified KillSwitch initialized (Phase 5F.3.5 Execution Layer)")

    state = %__MODULE__{
      kill_requests: %{},
      total_requests: 0,
      total_executed: 0,
      total_denied: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:request_termination, world_id, reason, severity}, state) do
    Logger.info("Kill request received for #{world_id}: #{reason} (severity: #{severity})")

    # Track request
    new_requests = put_in(state.kill_requests[world_id], {DateTime.utc_now(), reason, severity})
    new_state = %{state | kill_requests: new_requests, total_requests: state.total_requests + 1}

    # Delegate to ExecutionController (single authority chain)
    Task.async(fn ->
      execute_via_controller(world_id, reason, severity)
    end)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:cancel_request, world_id}, state) do
    new_requests = Map.delete(state.kill_requests, world_id)
    Logger.info("Kill request cancelled for #{world_id}")

    {:noreply, %{state | kill_requests: new_requests}}
  end

  @impl true
  def handle_call({:get_status, world_id}, _from, state) do
    status =
      case Map.get(state.kill_requests, world_id) do
        nil ->
          %{status: :no_request, world_id: world_id}

        {requested_at, reason, severity} ->
          %{
            status: :pending,
            world_id: world_id,
            requested_at: requested_at,
            reason: reason,
            severity: severity
          }
      end

    {:reply, {:ok, status}, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_requests: state.total_requests,
      total_executed: state.total_executed,
      total_denied: state.total_denied,
      pending_requests: map_size(state.kill_requests),
      recent_requests: Enum.take(Map.keys(state.kill_requests), 5)
    }

    {:reply, {:ok, stats}, state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp execute_via_controller(world_id, reason, severity) do
    Logger.info("Forwarding kill request to ExecutionController for #{world_id}")

    # Execute via ExecutionController (which requests CIS approval)
    result = ExecutionController.execute_kill(world_id, reason, severity)

    # Update stats based on result
    GenServer.cast(__MODULE__, {:update_result, world_id, result})

    case result do
      :executed ->
        Logger.info("✅ Kill executed for #{world_id}")

      :denied ->
        Logger.error("🛑 Kill denied for #{world_id}")

      :escalated ->
        Logger.warning("⚠️ Kill escalated for #{world_id}")
    end
  end

  @impl true
  def handle_cast({:update_result, world_id, result}, state) do
    # Remove from pending requests
    new_requests = Map.delete(state.kill_requests, world_id)

    # Update counters
    new_state =
      case result do
        :executed ->
          %{state | total_executed: state.total_executed + 1, kill_requests: new_requests}

        :denied ->
          %{state | total_denied: state.total_denied + 1, kill_requests: new_requests}

        _ ->
          %{state | kill_requests: new_requests}
      end

    {:noreply, new_state}
  end
end
