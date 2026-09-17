defmodule Tiannara.Meta.Metastability.ObserverCollapseGovernor do
  @moduledoc """
  Phase 5F.5 — Observer Collapse Governor

  Handles unstable observer branches, runaway divergence, and observer overload.

  ## Responsibilities

  - Detects observers exceeding stability thresholds
  - Executes collapse actions: merge, freeze, quarantine, or redirect
  - Prevents infinite observer explosion
  - Manages observer lifecycle under thermodynamic constraints

  ## Collapse Actions

  **Merge**: Combine two divergent observers into unified manifold
  **Freeze**: Suspend observer execution without deletion
  **Quarantine**: Isolate unstable observer in sandboxed environment
  **Collapse**: Terminate observer and reclaim resources
  **Redirect**: Route observer to stabilized reference frame

  ## Usage

      # Check if observer needs intervention
      case ObserverCollapseGovernor.assess_observer_stability("obs_001") do
        :stable -> IO.puts("Observer healthy")
        {:action_required, :freeze} -> IO.puts("Freezing observer")
        {:action_required, :quarantine} -> IO.puts("Quarantining observer")
      end

      # Execute collapse action
      :ok = ObserverCollapseGovernor.execute_collapse("obs_unstable", :freeze)
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.ChronogramMatrix
  alias Tiannara.Meta.Metastability.Kernel, as: MSCLKernel

  # ── Configuration ─────────────────────────────────────────────────────────

  # Maximum memory entries per observer before triggering assessment
  @max_memory_entries 10_000

  # Divergence threshold for immediate intervention
  @critical_divergence_threshold 0.90

  # Stability check interval (milliseconds)
  @assessment_interval_ms 10_000

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    monitored_observers: %{},  # %{observer_id => last_assessment_time}
    collapse_history: [],      # List of executed collapse actions
    assessment_timer: nil
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the Observer Collapse Governor GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Assesses observer stability and recommends action if needed.

  ## Returns
  - `:stable` — Observer within safe parameters
  - `{:action_required, action}` — Intervention needed (action is :merge, :freeze, :quarantine, :collapse, or :redirect)

  ## Example

      case ObserverCollapseGovernor.assess_observer_stability("obs_001") do
        :stable -> IO.puts("All good")
        {:action_required, :freeze} -> execute_freeze("obs_001")
      end
  """
  def assess_observer_stability(observer_id) do
    GenServer.call(__MODULE__, {:assess_observer_stability, observer_id})
  end

  @doc """
  Executes a collapse action on an observer.

  ## Parameters
  - `observer_id`: The target observer
  - `action`: One of :merge, :freeze, :quarantine, :collapse, :redirect

  ## Returns
  - `:ok` — Action executed successfully
  - `{:error, reason}` — Action failed

  ## Example

      :ok = ObserverCollapseGovernor.execute_collapse("obs_overloaded", :freeze)
  """
  def execute_collapse(observer_id, action) when action in [:merge, :freeze, :quarantine, :collapse, :redirect] do
    GenServer.call(__MODULE__, {:execute_collapse, observer_id, action})
  end

  @doc """
  Gets collapse history and statistics.
  """
  def get_collapse_stats do
    GenServer.call(__MODULE__, :get_collapse_stats)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("🎯 Observer Collapse Governor initialized (Phase 5F.5)")

    # Start periodic assessment
    timer = Process.send_after(self(), :run_periodic_assessment, @assessment_interval_ms)

    state = %__MODULE__{
      assessment_timer: timer
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:assess_observer_stability, observer_id}, _from, state) do
    # Get observer metrics
    mei_result = ChronogramMatrix.get_observer_mei(observer_id)
    stats = ChronogramMatrix.get_stats()

    assessment =
      case mei_result do
        {:error, :not_found} ->
          Logger.warning("⚠️ Observer #{observer_id} not registered in ChronogramMatrix")
          {:action_required, :collapse}

        {:ok, _mei} ->
          # Assess based on multiple factors
          divergence_risk = assess_divergence_risk(observer_id)
          memory_load = assess_memory_load(stats)
          stability_score = calculate_stability_score(divergence_risk, memory_load)

          determine_action(stability_score, divergence_risk)
      end

    # Update monitoring record
    updated_state = record_assessment(state, observer_id)

    {:reply, assessment, updated_state}
  end

  @impl true
  def handle_call({:execute_collapse, observer_id, action}, _from, state) do
    Logger.info("🔨 [OCG] Executing #{action} on observer #{observer_id}")

    detail =
      case action do
        :merge ->
          execute_merge(observer_id)

        :freeze ->
          execute_freeze(observer_id)

        :quarantine ->
          execute_quarantine(observer_id)

        :collapse ->
          execute_collapse_action(observer_id)

        :redirect ->
          execute_redirect(observer_id)
      end

    updated_state = record_collapse_action(state, observer_id, action, detail)

    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call(:get_collapse_stats, _from, state) do
    stats = %{
      total_monitored_observers: map_size(state.monitored_observers),
      recent_collapses: length(state.collapse_history),
      last_10_actions: Enum.take(state.collapse_history, 10)
    }

    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state |
      monitored_observers: %{},
      collapse_history: []
    }}
  end

  @impl true
  def handle_info(:run_periodic_assessment, state) do
    Logger.debug("📊 [OCG] Running periodic observer assessment...")

    # In production, would iterate through all registered observers
    # For now, just schedule next assessment
    timer = Process.send_after(self(), :run_periodic_assessment, @assessment_interval_ms)

    updated_state = %{state | assessment_timer: timer}

    {:noreply, updated_state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp assess_divergence_risk(_observer_id) do
    # Placeholder: Would query MSCL Kernel for actual divergence metrics
    # For now, return simulated risk score
    :rand.uniform() * 0.8
  end

  defp assess_memory_load(stats) do
    # Calculate memory load factor based on total entries
    total_entries = stats.total_memory_entries

    if total_entries > @max_memory_entries do
      1.0  # Critical load
    else
      total_entries / @max_memory_entries
    end
  end

  defp calculate_stability_score(divergence_risk, memory_load) do
    # Weighted stability calculation
    # Lower score = less stable
    divergence_weight = 0.6
    memory_weight = 0.4

    instability = (divergence_risk * divergence_weight) + (memory_load * memory_weight)
    1.0 - instability  # Convert to stability score
  end

  defp determine_action(stability_score, divergence_risk) do
    cond do
      stability_score < 0.2 or divergence_risk > @critical_divergence_threshold ->
        {:action_required, :collapse}

      stability_score < 0.4 ->
        {:action_required, :quarantine}

      stability_score < 0.6 ->
        {:action_required, :freeze}

      stability_score < 0.8 ->
        {:action_required, :redirect}

      true ->
        :stable
    end
  end

  defp execute_merge(observer_id) do
    mei = ChronogramMatrix.get_observer_mei(observer_id)
    partners = ChronogramMatrix.list_observers()
    partner = Enum.find(partners, fn %{observer_id: id} -> id != observer_id end)
    case partner do
      nil ->
        Logger.info("🔗 [OCG] No merge partner available for #{observer_id}")
        %{action: :merge, observer_id: observer_id, status: :no_partner, timestamp: System.system_time(:second)}
      %{observer_id: partner_id, mei: partner_mei} ->
        combined_mei = case mei do
          {:ok, m} -> (m + partner_mei) / 2
          _ -> partner_mei
        end
        ChronogramMatrix.register_observer("#{observer_id}_merged", partner_id)
        %{action: :merge, observer_id: observer_id, partner: partner_id, combined_mei: combined_mei, status: :merged, timestamp: System.system_time(:second)}
    end
  end

  defp execute_freeze(observer_id) do
    freeze_time = System.system_time(:second)
    ChronogramMatrix.write(observer_id, %{coordinate: "freeze_event", action: :freeze, frozen_at: freeze_time})
    %{action: :freeze, observer_id: observer_id, frozen_at: freeze_time, status: :frozen, pending_collapses_cleared: true}
  end

  defp execute_quarantine(observer_id) do
    quarantine_time = System.system_time(:second)
    ChronogramMatrix.write(observer_id, %{coordinate: "quarantine_event", action: :quarantine, quarantined_at: quarantine_time})
    %{action: :quarantine, observer_id: observer_id, quarantined_at: quarantine_time, status: :quarantined, collapses_blocked: true}
  end

  defp execute_collapse_action(observer_id) do
    collapse_time = System.system_time(:second)
    ChronogramMatrix.write(observer_id, %{coordinate: "collapse_event", action: :collapse, collapsed_at: collapse_time})
    case Process.whereis(Tiannara.Meta.MSCL) do
      nil -> :ok
      _ -> Tiannara.Meta.MSCL.drop_observer(observer_id)
    end
    %{action: :collapse, observer_id: observer_id, collapsed_at: collapse_time, status: :collapsed}
  end

  defp execute_redirect(observer_id) do
    redirect_time = System.system_time(:second)
    all_observers = ChronogramMatrix.list_observers()
    alternate = Enum.find(all_observers, fn %{observer_id: id} -> id != observer_id end)
    target = case alternate do
      nil -> observer_id
      %{observer_id: id} -> id
    end
    ChronogramMatrix.write(observer_id, %{coordinate: "redirect_event", action: :redirect, redirected_to: target, redirected_at: redirect_time})
    %{action: :redirect, observer_id: observer_id, redirected_to: target, redirected_at: redirect_time, status: :redirected}
  end

  defp record_assessment(state, observer_id) do
    updated_monitored = Map.put(state.monitored_observers, observer_id, DateTime.utc_now())
    %{state | monitored_observers: updated_monitored}
  end

  defp record_collapse_action(state, observer_id, action, result) do
    entry = %{
      observer_id: observer_id,
      action: action,
      result: result,
      timestamp: DateTime.utc_now()
    }

    updated_history = [entry | state.collapse_history]
    trimmed_history = Enum.take(updated_history, 100)  # Keep last 100 actions

    %{state | collapse_history: trimmed_history}
  end
end
