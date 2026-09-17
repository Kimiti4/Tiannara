defmodule TiannaraRuntime.Legacy.CIS.Supervisor do
  @moduledoc """
  Cognitive Immune System Supervisor (CIS-SUP)
  
  Phase 5F safety arbitration kernel.
  All destructive or structural mutations must pass through here.
  
  ## Purpose
  
  Acts as:
  - 🧠 Central safety arbitration layer
  - 🔒 Only system allowed to approve kills, resource termination, world suspension
  - 📡 Bridges KillSwitch, ResourceQuota, WorldSupervisor, Safety Cortex
  
  ## Architecture
  
  BEFORE (broken):
    KillSwitch → direct world/resource termination (god module, dangerous)
  
  AFTER (Phase 5F compliant):
    KillSwitch → CIS Supervisor (arbitration) → execute if approved
  
  ## Safety Modes
  
  - `:normal` — Standard operations
  - `:elevated` — Heightened monitoring
  - `:critical` — Restrictive approvals
  - `:lockdown` — Deny all destructive operations
  
  ## Usage
  
      # Authorize a kill operation
      case CIS.Supervisor.authorize_kill(world_id, reason, :critical) do
        :approve -> execute_kill(world_id)
        :require_secondary_validation -> escalate()
        :deny -> log_denial()
      end
      
      # Set safety mode
      CIS.Supervisor.set_safety_mode(:critical)
  """

  use GenServer
  require Logger

  # ── Configuration ─────────────────────────────────────────────────────────

  @default_safety_mode :normal
  @max_arbitration_log_size 1000

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    safety_mode: @default_safety_mode,
    kill_authority_enabled: true,
    arbitration_log: [],
    total_approvals: 0,
    total_denials: 0,
    total_escalations: 0
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the CIS Supervisor GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Authorizes a kill operation for a world.
  
  Returns one of:
  - `:approve` — Kill is authorized
  - `:deny` — Kill is denied (lockdown mode or policy violation)
  - `:require_secondary_validation` — Needs escalation (critical severity in critical mode)
  
  ## Parameters
  - `world_id`: The world to kill
  - `reason`: Human-readable reason for the kill
  - `severity`: `:normal`, `:elevated`, `:critical`, `:emergency`
  """
  def authorize_kill(world_id, reason, severity \\ :normal) do
    GenServer.call(__MODULE__, {:authorize_kill, world_id, reason, severity}, 5_000)
  end

  @doc """
  Authorizes resource termination.
  
  Similar to authorize_kill but for resource quota enforcement.
  """
  def authorize_resource_termination(resource_id, reason, severity \\ :normal) do
    GenServer.call(__MODULE__, {:authorize_resource_termination, resource_id, reason, severity}, 5_000)
  end

  @doc """
  Authorizes world suspension (temporary pause, not deletion).
  """
  def authorize_world_suspension(world_id, reason, duration_ms \\ 60_000) do
    GenServer.call(__MODULE__, {:authorize_world_suspension, world_id, reason, duration_ms}, 5_000)
  end

  @doc """
  Sets the global safety mode.
  
  Modes:
  - `:normal` — Standard operations
  - `:elevated` — Heightened monitoring
  - `:critical` — Restrictive approvals
  - `:lockdown` — Deny all destructive operations
  """
  def set_safety_mode(mode) when mode in [:normal, :elevated, :critical, :lockdown] do
    GenServer.cast(__MODULE__, {:set_mode, mode})
    :ok
  end

  @doc """
  Gets current safety mode.
  """
  def get_safety_mode do
    GenServer.call(__MODULE__, :get_mode)
  end

  @doc """
  Gets arbitration statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @doc """
  Clears arbitration log (for maintenance).
  """
  def clear_log do
    GenServer.cast(__MODULE__, :clear_log)
    :ok
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("🧠 CIS Supervisor initialized (Phase 5F Safety Kernel)")

    state = %__MODULE__{
      safety_mode: @default_safety_mode,
      kill_authority_enabled: true,
      arbitration_log: [],
      total_approvals: 0,
      total_denials: 0,
      total_escalations: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:authorize_kill, world_id, reason, severity}, _from, state) do
    decision = make_arbitration_decision(state.safety_mode, severity, :kill)

    log_entry = %{
      operation: :kill,
      target_id: world_id,
      reason: reason,
      severity: severity,
      decision: decision,
      timestamp: DateTime.utc_now(),
      safety_mode: state.safety_mode
    }

    new_state = update_stats_and_log(state, decision, log_entry)

    log_arbitration_event(decision, world_id, reason, severity)

    {:reply, decision, new_state}
  end

  @impl true
  def handle_call({:authorize_resource_termination, resource_id, reason, severity}, _from, state) do
    decision = make_arbitration_decision(state.safety_mode, severity, :resource_termination)

    log_entry = %{
      operation: :resource_termination,
      target_id: resource_id,
      reason: reason,
      severity: severity,
      decision: decision,
      timestamp: DateTime.utc_now(),
      safety_mode: state.safety_mode
    }

    new_state = update_stats_and_log(state, decision, log_entry)

    log_arbitration_event(decision, resource_id, reason, severity)

    {:reply, decision, new_state}
  end

  @impl true
  def handle_call({:authorize_world_suspension, world_id, reason, _duration_ms}, _from, state) do
    # Suspension is less severe than kill, default to approve unless lockdown
    decision =
      if state.safety_mode == :lockdown do
        :deny
      else
        :approve
      end

    log_entry = %{
      operation: :world_suspension,
      target_id: world_id,
      reason: reason,
      severity: :elevated,
      decision: decision,
      timestamp: DateTime.utc_now(),
      safety_mode: state.safety_mode
    }

    new_state = update_stats_and_log(state, decision, log_entry)

    log_arbitration_event(decision, world_id, reason, :elevated)

    {:reply, decision, new_state}
  end

  @impl true
  def handle_call(:get_mode, _from, state) do
    {:reply, {:ok, state.safety_mode}, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      safety_mode: state.safety_mode,
      kill_authority_enabled: state.kill_authority_enabled,
      total_approvals: state.total_approvals,
      total_denials: state.total_denials,
      total_escalations: state.total_escalations,
      log_size: length(state.arbitration_log),
      recent_decisions: Enum.take(state.arbitration_log, 10)
    }

    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_cast({:set_mode, mode}, state) do
    Logger.warning("🧠 CIS safety mode changed: #{state.safety_mode} → #{mode}")

    {:noreply, %{state | safety_mode: mode}}
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state |
      safety_mode: :normal,
      arbitration_log: [],
      total_approvals: 0,
      total_denials: 0,
      total_escalations: 0
    }}
  end

  @impl true
  def handle_cast(:clear_log, state) do
    Logger.info("🧠 CIS arbitration log cleared")
    {:noreply, %{state | arbitration_log: []}}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp make_arbitration_decision(safety_mode, severity, _operation) do
    case {safety_mode, severity} do
      # Lockdown denies everything
      {:lockdown, _} ->
        :deny

      # Critical mode + normal severity requires validation
      {:critical, :normal} ->
        :require_secondary_validation

      # Normal mode + critical severity auto-approves (trust system)
      {:normal, :critical} ->
        :approve

      # Elevated mode + emergency requires validation
      {:elevated, :emergency} ->
        :require_secondary_validation

      # Default: approve
      _ ->
        :approve
    end
  end

  defp update_stats_and_log(state, decision, log_entry) do
    # Update counters
    new_state =
      case decision do
        :approve ->
          %{state | total_approvals: state.total_approvals + 1}

        :deny ->
          %{state | total_denials: state.total_denials + 1}

        :require_secondary_validation ->
          %{state | total_escalations: state.total_escalations + 1}
      end

    # Append to log (with size limit)
    updated_log = [log_entry | new_state.arbitration_log]
    trimmed_log = Enum.take(updated_log, @max_arbitration_log_size)

    %{new_state | arbitration_log: trimmed_log}
  end

  defp log_arbitration_event(decision, target_id, reason, severity) do
    case decision do
      :approve ->
        Logger.info("✅ CIS approved #{severity} operation on #{target_id}: #{reason}")

      :deny ->
        Logger.error("🛑 CIS denied #{severity} operation on #{target_id}: #{reason}")

      :require_secondary_validation ->
        Logger.warning("⚠️ CIS requires validation for #{severity} operation on #{target_id}: #{reason}")
    end
  end
end
