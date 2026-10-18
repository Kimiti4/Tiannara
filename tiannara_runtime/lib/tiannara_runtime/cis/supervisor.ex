defmodule TiannaraRuntime.CIS.Supervisor do
  @moduledoc """
  Cognitive Immune System Supervisor (CIS-SUP) — Phase 5F safety arbitration kernel.

  ## Authority path (single documented chain)

      KillSwitch → ExecutionController → CIS Supervisor (arbitration) → execute if approved

  CIS Supervisor is the only system allowed to approve kills, resource
  termination, or world suspension. Direct KillSwitch → WorldSupervisor
  termination bypasses this chain and is forbidden.

  ## Safety modes

  `:normal`, `:elevated`, `:critical`, `:lockdown` — `:lockdown` denies all
  destructive operations.

  ## 5F-P0 restoration note (2026-10-19)

  Commit `8610c558` removed `authorize_kill/3`,
  `authorize_resource_termination/3`, `authorize_world_suspension/3`,
  `get_stats/0`, `clear_log/0` and all arbitration state from this module
  while callers kept calling them — producing UndefinedFunctionError on the
  safety-authorization chain (audit P0). This restoration re-adds that
  public surface with the original decision contract (verbatim from
  `51847461`), additively, WITHOUT any supervision-tree changes (wiring is
  a separate, explicitly approved step).

  Deliberate compat divergences from `51847461`, kept because live callers
  and tests depend on these shapes: `set_safety_mode/1` stays a `call`
  (original was a cast) and `get_safety_mode/0` returns the bare mode atom
  (original returned `{:ok, mode}`). The original shapes remain available
  on `TiannaraRuntime.Legacy.CIS.Supervisor`.

  Fail-closed property: when this process is not running, every
  `authorize_*` call exits (`:noproc`) and no caller rescues it — a missing
  arbitration kernel halts the destructive operation.

  ## Usage

      case TiannaraRuntime.CIS.Supervisor.authorize_kill(world_id, reason, :critical) do
        :approve -> execute_kill(world_id)
        :require_secondary_validation -> escalate()
        :deny -> log_denial()
      end
  """

  use GenServer
  require Logger

  @default_safety_mode :normal
  @max_arbitration_log_size 1000
  @valid_safety_modes [:normal, :elevated, :critical, :lockdown]

  defstruct [
    safety_mode: @default_safety_mode,
    kill_authority_enabled: true,
    arbitration_log: [],
    total_approvals: 0,
    total_denials: 0,
    total_escalations: 0
  ]

  @doc """
  Starts the CIS Supervisor GenServer (arbitration kernel).
  """
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @doc """
  Authorizes a kill operation for a world.

  Returns one of:
  - `:approve` — kill is authorized
  - `:deny` — kill is denied (lockdown mode)
  - `:require_secondary_validation` — needs escalation
  """
  def authorize_kill(world_id, reason, severity \\ :normal) do
    GenServer.call(__MODULE__, {:authorize_kill, world_id, reason, severity}, 5_000)
  end

  @doc """
  Authorizes resource termination (resource quota enforcement path).
  """
  def authorize_resource_termination(resource_id, reason, severity \\ :normal) do
    GenServer.call(__MODULE__, {:authorize_resource_termination, resource_id, reason, severity}, 5_000)
  end

  @doc """
  Authorizes world suspension (temporary pause, not deletion).
  Never escalates: `:approve` unless lockdown, otherwise `:deny`.
  """
  def authorize_world_suspension(world_id, reason, duration_ms \\ 60_000) do
    GenServer.call(__MODULE__, {:authorize_world_suspension, world_id, reason, duration_ms}, 5_000)
  end

  @doc """
  Sets the global safety mode (`:normal | :elevated | :critical | :lockdown`).
  """
  def set_safety_mode(mode) when mode in @valid_safety_modes do
    GenServer.call(__MODULE__, {:set_safety_mode, mode})
  end

  @doc """
  Gets the current safety mode (bare atom — live-caller compat, see moduledoc).
  """
  def get_safety_mode do
    GenServer.call(__MODULE__, :get_safety_mode)
  end

  @doc """
  Gets arbitration statistics (counters + recent decisions).
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @doc """
  Clears the arbitration log (for maintenance).
  """
  def clear_log do
    GenServer.cast(__MODULE__, :clear_log)
    :ok
  end

  @impl true
  def init(state), do: {:ok, state}

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
    # Suspension is less severe than kill: deny only under lockdown.
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
  def handle_call({:set_safety_mode, mode}, _from, state) do
    {:reply, :ok, %{state | safety_mode: mode}}
  end

  @impl true
  def handle_call(:get_safety_mode, _from, state) do
    {:reply, state.safety_mode, state}
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
  def handle_cast(:clear_log, state) do
    Logger.info("CIS arbitration log cleared")
    {:noreply, %{state | arbitration_log: []}}
  end

  @impl true
  def handle_cast(:reset, _state) do
    # Restored with the 5F-P0 contract: integration-test helpers cast :reset
    # between tests (the pre-restoration stub had no handle_cast at all and
    # crashed on it).
    {:noreply, %__MODULE__{}}
  end

  # ── Original decision contract (verbatim from 51847461) ──────────────────

  defp make_arbitration_decision(safety_mode, severity, _operation) do
    case {safety_mode, severity} do
      {:lockdown, _} -> :deny
      {:critical, :normal} -> :require_secondary_validation
      {:normal, :critical} -> :approve
      {:elevated, :emergency} -> :require_secondary_validation
      _ -> :approve
    end
  end

  defp update_stats_and_log(state, decision, log_entry) do
    new_state =
      case decision do
        :approve ->
          %{state | total_approvals: state.total_approvals + 1}

        :deny ->
          %{state | total_denials: state.total_denials + 1}

        :require_secondary_validation ->
          %{state | total_escalations: state.total_escalations + 1}
      end

    updated_log = [log_entry | new_state.arbitration_log]
    trimmed_log = Enum.take(updated_log, @max_arbitration_log_size)

    %{new_state | arbitration_log: trimmed_log}
  end

  defp log_arbitration_event(decision, target_id, reason, severity) do
    case decision do
      :approve ->
        Logger.info("CIS approved #{severity} operation on #{target_id}: #{reason}")

      :deny ->
        Logger.error("CIS denied #{severity} operation on #{target_id}: #{reason}")

      :require_secondary_validation ->
        Logger.warning("CIS requires validation for #{severity} operation on #{target_id}: #{reason}")
    end
  end
end
