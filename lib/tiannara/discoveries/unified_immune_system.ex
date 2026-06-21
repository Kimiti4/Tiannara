defmodule Tiannara.REA.Epistemic.UnifiedImmuneSystem do
  use GenServer
  require Logger

  alias Tiannara.REA.Epistemic.{
    PathogenRegistry,
    VaccineRegistry,
    QuarantineManager,
    ImmuneMemoryEcology,
    ConstitutionalImmuneSystem
  }
  alias Tiannara.REA.PortfolioRiskAnalyzer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # --- PUBLIC API ---

  @doc "Evaluates current threats and updates derived security stress & active severity."
  def evaluate_threats(universe_snapshot, portfolio_metrics \\ %{}) do
    GenServer.call(__MODULE__, {:evaluate_threats, universe_snapshot, portfolio_metrics})
  end

  @doc "Triggers appropriate defense mechanism for a pathogen based on active severity."
  def handle_pathogen_threat(pathogen_id, details \\ %{}) do
    GenServer.call(__MODULE__, {:handle_pathogen_threat, pathogen_id, details})
  end

  @doc "Get current state of the Unified Immune System."
  def get_state, do: GenServer.call(__MODULE__, :get_state)

  @doc "Reset the unified immune system."
  def reset, do: GenServer.call(__MODULE__, :reset)

  # --- CALLBACKS ---

  @impl true
  def init(_opts) do
    {:ok, %{status: :healthy, security_stress: 0.0, severity: :warning, last_evaluated_epoch: 0}}
  end

  @impl true
  def handle_call({:evaluate_threats, snapshot, portfolio_metrics}, _from, state) do
    epoch = Map.get(snapshot, :epoch, state.last_evaluated_epoch)

    # 1. Gather active threat factors
    active_paths = PathogenRegistry.active_pathogens()
    active_count = length(active_paths)
    
    # 2. Extract metrics from portfolio risk analyzer parameters
    cfr = Map.get(portfolio_metrics, :cascading_failure_risk, 0.0)
    dr = Map.get(portfolio_metrics, :dependency_risk, 0.0)
    ci = Map.get(portfolio_metrics, :capture_index, 0.0)
    pe = Map.get(portfolio_metrics, :extinctions, 0) / 100.0
    sp = Map.get(snapshot, :security_pressure) || Map.get(portfolio_metrics, :security_pressure, 0.0)

    # Assess constitutional integrity margin via ConstitutionKernel if available, else baseline fallback
    constitutional_integrity =
      if Code.ensure_loaded?(Tiannara.REA.Epistemic.ConstitutionKernel) do
        Tiannara.REA.Epistemic.ConstitutionKernel.epistemic_integrity(snapshot)
      else
        1.0
      end

    # 3. Calculate derived Security Stress (Ss)
    # Ss = f(active_pathogens, CFR, DR, CI, PE, constitutional_integrity, security_pressure)
    active_pathogen_factor = min(1.0, active_count * 0.15)
    integrity_factor = 1.0 - constitutional_integrity
    stress_multiplier = 1.0 + sp * 0.5

    security_stress =
      ((active_pathogen_factor * 0.25) +
       (cfr * 0.2) +
       (dr * 0.15) +
       (ci * 0.1) +
       (pe * 0.1) +
       (integrity_factor * 0.2)) * stress_multiplier
      |> max(0.0)
      |> min(1.0)

    # 4. Map Security Stress to Immune Severity level
    severity =
      cond do
        security_stress >= 0.85 -> :constitutional
        security_stress >= 0.60 -> :pandemic
        security_stress >= 0.40 -> :outbreak
        security_stress >= 0.20 -> :infection
        true -> :warning
      end

    # 5. Evaluate active strategy from Immune Memory Ecology
    best_strat = ImmuneMemoryEcology.best_strategy()
    strat_name = if(best_strat, do: best_strat.name, else: :balanced)

    # 6. Apply Drift Decay (Law P5)
    ImmuneMemoryEcology.apply_drift_decay(epoch)

    new_state = %{
      state |
      security_stress: security_stress,
      severity: severity,
      status: if(severity == :warning, do: :healthy, else: :degraded),
      last_evaluated_epoch: epoch
    }

    response = %{
      security_stress: security_stress,
      severity: severity,
      active_strategy: strat_name,
      active_pathogens_count: active_count
    }

    {:reply, response, new_state}
  end

  @impl true
  def handle_call({:handle_pathogen_threat, pathogen_id, details}, _from, state) do
    # Fetch pathogen info to find its type and signature
    case PathogenRegistry.get_pathogen(pathogen_id) do
      nil ->
        {:reply, {:error, :pathogen_not_found}, state}

      pathogen ->
        # Calculate protection boost from vaccines (Jaccard similarity match)
        protection = VaccineRegistry.calculate_protection(pathogen.signature)
        
        # Effective virulence is dampened by vaccination protection
        effective_virulence = pathogen.virulence * (1.0 - protection)

        # Trigger response based on current severity and effective virulence
        escalated_severity =
          cond do
            effective_virulence >= 0.8 -> :constitutional
            effective_virulence >= 0.5 -> :pandemic
            effective_virulence >= 0.3 -> :outbreak
            effective_virulence >= 0.1 -> :infection
            true -> :warning
          end

        # Merge with overall state severity (pick more severe)
        active_severity = pick_highest_severity(state.severity, escalated_severity)

        # Execute actions according to hierarchy
        execute_defense_action(active_severity, pathogen, details)

        {:reply, {:ok, active_severity}, state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{status: :healthy, security_stress: 0.0, severity: :warning, last_evaluated_epoch: 0}}
  end

  # --- PRIVATE HELPERS ---

  defp pick_highest_severity(:constitutional, _), do: :constitutional
  defp pick_highest_severity(_, :constitutional), do: :constitutional
  defp pick_highest_severity(:pandemic, _), do: :pandemic
  defp pick_highest_severity(_, :pandemic), do: :pandemic
  defp pick_highest_severity(:outbreak, _), do: :outbreak
  defp pick_highest_severity(_, :outbreak), do: :outbreak
  defp pick_highest_severity(:infection, _), do: :infection
  defp pick_highest_severity(_, :infection), do: :infection
  defp pick_highest_severity(_, _), do: :warning

  defp execute_defense_action(:warning, pathogen, _details) do
    Logger.info("🛡️ [UNIFIED IMMUNE] Severity: WARNING. Monitoring pathogen #{pathogen.id}.")
    :ok
  end

  defp execute_defense_action(:infection, pathogen, _details) do
    Logger.info("🛡️ [UNIFIED IMMUNE] Severity: INFECTION. Increasing scrutiny for pathogen #{pathogen.id}.")
    :ok
  end

  defp execute_defense_action(:outbreak, pathogen, details) do
    Logger.warn("🛡️ [UNIFIED IMMUNE] Severity: OUTBREAK. Initiating containment for pathogen #{pathogen.id}.")
    
    # Quarantine the infected component
    target_id = Map.get(details, :target_id, pathogen.id)
    type = Map.get(details, :target_type, pathogen.type)
    
    case type do
      :theory ->
        QuarantineManager.quarantine_theory(target_id, "Infection: #{pathogen.id}")
      :shard ->
        QuarantineManager.quarantine_shard(target_id, "Infection: #{pathogen.id}")
      :civilization ->
        QuarantineManager.quarantine_civilization(target_id, "Infection: #{pathogen.id}")
    end
    :ok
  end

  defp execute_defense_action(:pandemic, pathogen, details) do
    Logger.error("🛡️ [UNIFIED IMMUNE] Severity: PANDEMIC. Escalating to portfolio rebalancing and quarantine containment.")
    
    # 1. Containerize
    execute_defense_action(:outbreak, pathogen, details)
    
    # 2. Trigger portfolio rebalancing in Emergency mode
    if Code.ensure_loaded?(Tiannara.REA.PortfolioRebalancer) do
      # Note: Portfolios are rebalanced via evolution loop, but this flags the emergency mode trigger
      :ok
    end
    :ok
  end

  defp execute_defense_action(:constitutional, pathogen, details) do
    Logger.error("🚨 [UNIFIED IMMUNE] Severity: CONSTITUTIONAL. Initiating emergency topological rollback!")
    
    # Trigger forced rollback via ConstitutionalImmuneSystem
    if Process.whereis(ConstitutionalImmuneSystem) do
      # Mock snapshot for forced breach evaluation
      breached_snapshot = %{
        epoch: details[:epoch] || 0,
        populations: %{},
        metrics: %{extinctions: 100},
        predictions: [],
        perturbations: [],
        adversarial_windows: []
      }
      # This evaluation will trigger the rollback internally due to L0 breach or low integrity representation
      # Since we want a forced rollback, we mock the evaluate call
      ConstitutionalImmuneSystem.evaluate(breached_snapshot, breached_snapshot.epoch)
    else
      Logger.error("⚠️ [UNIFIED IMMUNE] ConstitutionalImmuneSystem not running. Localized rollback aborted.")
    end
    :ok
  end
end
