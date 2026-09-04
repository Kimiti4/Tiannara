defmodule TiannaraOS.Governance.SimulationEngine do
  @moduledoc """
  SimulationEngine - Execute RFC simulations using validation runtime.

  Runs 4 simulation types (safety, performance, governance, economic) to validate
  RFC proposals before ratification. Integrates with Phase 14.0.99 validation runtime.

  ## Archaeology

  - **purpose**: Validate RFC proposals through multi-dimensional simulation
  - **introduced_in**: Phase 14.1
  - **depends_on**: TiannaraOS.Governance.Validation.CampaignExecutor (Phase 14.0.99)
  - **constitution_reference**: PHASE14_1_RFC_SYSTEM_SPECIFICATION.md Section 3.5
  - **owner**: Governance Council

  ## Usage

      {:ok, report} = SimulationEngine.run_full_simulation(rfc_id)
      {:ok, safety_report} = SimulationEngine.run_safety_simulation(rfc_id)
  """

  @type rfc_id :: String.t()
  @type simulation_report :: map()

  @doc """
  Run all 4 simulation types for an RFC.

  Returns aggregated simulation report with pass/fail determination.
  """
  @spec run_full_simulation(rfc_id()) :: {:ok, simulation_report()} | {:error, term()}
  def run_full_simulation(rfc_id) do
    with {:ok, safety} <- run_safety_simulation(rfc_id),
         {:ok, performance} <- run_performance_simulation(rfc_id),
         {:ok, governance} <- run_governance_simulation(rfc_id),
         {:ok, economic} <- run_economic_simulation(rfc_id) do
      overall_status = determine_overall_status([safety, performance, governance, economic])

      report = %{
        simulation_id: generate_simulation_id(),
        rfc_id: rfc_id,
        completed_at: DateTime.utc_now(),
        overall_status: overall_status,
        safety_simulation: safety,
        performance_simulation: performance,
        governance_simulation: governance,
        economic_simulation: economic
      }

      {:ok, report}
    end
  end

  @doc """
  Run safety simulation - verify no invariant violations.

  Checks:
  - INV-031: Institutional Conservation
  - INV-032: Appointment Immutability
  - INV-033: Capability Provenance
  - INV-034: Replay Determinism
  - INV-035: Authority Separation
  """
  @spec run_safety_simulation(rfc_id()) :: {:ok, map()} | {:error, term()}
  def run_safety_simulation(rfc_id) do
    # Execute GV-RFC-001 validation campaign via CampaignExecutor
    case execute_validation_campaign("GV-RFC-001", rfc_id) do
      {:ok, evidence} ->
        # Extract safety simulation results from evidence
        extract_safety_results(evidence)
      {:error, reason} ->
        {:error, {:campaign_execution_failed, reason}}
    end
  end

  @doc """
  Run performance simulation - benchmark resource usage.

  Measures:
  - CPU impact (%)
  - Memory impact (%)
  - Storage impact (%)
  - Execution time impact (%)
  - Bottleneck identification
  """
  @spec run_performance_simulation(rfc_id()) :: {:ok, map()} | {:error, term()}
  def run_performance_simulation(rfc_id) do
    # Execute GV-RFC-002 validation campaign
    case execute_validation_campaign("GV-RFC-002", rfc_id) do
      {:ok, evidence} ->
        extract_performance_results(evidence)
      {:error, reason} ->
        {:error, {:campaign_execution_failed, reason}}
    end
  end

  @doc """
  Run governance simulation - assess institutional impact.

  Evaluates:
  - Institutions affected
  - Power distribution changes
  - Decision-making process changes
  - Institutional fitness impact
  """
  @spec run_governance_simulation(rfc_id()) :: {:ok, map()} | {:error, term()}
  def run_governance_simulation(rfc_id) do
    # Execute GV-RFC-003 validation campaign
    case execute_validation_campaign("GV-RFC-003", rfc_id) do
      {:ok, evidence} ->
        extract_governance_results(evidence)
      {:error, reason} ->
        {:error, {:campaign_execution_failed, reason}}
    end
  end

  @doc """
  Run economic simulation - calculate cost-benefit analysis.

  Computes:
  - Implementation cost (development hours, resources)
  - Operational cost (ongoing maintenance, compute)
  - Benefit value (efficiency gains, risk reduction)
  - ROI (benefit/cost ratio)
  - Payback period
  """
  @spec run_economic_simulation(rfc_id()) :: {:ok, map()} | {:error, term()}
  def run_economic_simulation(rfc_id) do
    # Execute GV-RFC-004 validation campaign
    case execute_validation_campaign("GV-RFC-004", rfc_id) do
      {:ok, evidence} ->
        extract_economic_results(evidence)
      {:error, reason} ->
        {:error, {:campaign_execution_failed, reason}}
    end
  end

  @doc """
  Re-run failed simulations after RFC revision.

  Only re-runs simulations that previously failed.
  """
  @spec rerun_failed_simulations(rfc_id(), [atom()]) :: {:ok, simulation_report()} | {:error, term()}
  def rerun_failed_simulations(rfc_id, failed_types) do
    results = Enum.map(failed_types, fn type ->
      case type do
        :safety -> {:safety, run_safety_simulation(rfc_id)}
        :performance -> {:performance, run_performance_simulation(rfc_id)}
        :governance -> {:governance, run_governance_simulation(rfc_id)}
        :economic -> {:economic, run_economic_simulation(rfc_id)}
      end
    end)

    # Check if all reruns passed
    all_passed = Enum.all?(results, fn {_type, result} ->
      match?({:ok, %{status: :pass}}, result)
    end)

    if all_passed do
      {:ok, %{rerun_status: :all_passed, results: results}}
    else
      {:ok, %{rerun_status: :some_failed, results: results}}
    end
  end

  @doc """
  Compare simulation results across RFC versions.

  Shows how changes improved or degraded metrics.
  """
  @spec compare_simulations(map(), map()) :: map()
  def compare_simulations(old_report, new_report) do
    %{
      safety_improved: compare_safety(old_report.safety_simulation, new_report.safety_simulation),
      performance_improved: compare_performance(
        old_report.performance_simulation,
        new_report.performance_simulation
      ),
      governance_improved: compare_governance(
        old_report.governance_simulation,
        new_report.governance_simulation
      ),
      economic_improved: compare_economic(
        old_report.economic_simulation,
        new_report.economic_simulation
      )
    }
  end

  # Private helpers

  defp generate_simulation_id() do
    timestamp = System.system_time(:millisecond)
    random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    "SIM-#{timestamp}-#{random}"
  end

  defp determine_overall_status(simulations) do
    if Enum.all?(simulations, fn sim -> Map.get(sim, :status) == :pass end) do
      :pass
    else
      :fail
    end
  end

  defp compare_safety(old, new) do
    old_violations = length(Map.get(old, :invariant_violations, []))
    new_violations = length(Map.get(new, :invariant_violations, []))
    new_violations < old_violations
  end

  defp compare_performance(old, new) do
    old_impact = Map.get(old, :cpu_impact_percent, 100)
    new_impact = Map.get(new, :cpu_impact_percent, 100)
    new_impact < old_impact
  end

  defp compare_governance(old, new) do
    old_fitness = Map.get(old, :institutional_fitness_change, 0)
    new_fitness = Map.get(new, :institutional_fitness_change, 0)
    new_fitness > old_fitness
  end

  defp compare_economic(old, new) do
    old_roi = Map.get(old, :roi, 0)
    new_roi = Map.get(new, :roi, 0)
    new_roi > old_roi
  end

  # Campaign execution helpers

  alias TiannaraOS.Governance.Validation.{CampaignRegistry, CampaignExecutor, AdapterRegistry}

  defp execute_validation_campaign(campaign_id, rfc_id) do
    # Get campaign specification from registry
    case CampaignRegistry.get_campaign(campaign_id) do
      {:ok, spec} ->
        # Get all registered adapters
        adapters = build_adapter_map()
        
        # Execute campaign with RFC context
        params = Map.merge(spec.params || %{}, %{rfc_id: rfc_id})
        updated_spec = %{spec | params: params}
        
        CampaignExecutor.execute_campaign(updated_spec, adapters)
      
      {:error, :not_found} ->
        {:error, {:campaign_not_found, campaign_id}}
    end
  end

  defp build_adapter_map() do
    # Convert adapter list to map for CampaignExecutor
    AdapterRegistry.list_adapters()
    |> Enum.into(%{})
  end

  # Result extraction helpers

  defp extract_safety_results(evidence) do
    # Extract safety simulation results from campaign evidence
    content = Map.get(evidence, :content, %{})
    data = Map.get(content, :data, %{})
    
    {:ok, %{
      status: determine_pass_fail(data),
      invariant_violations: Map.get(data, :invariant_violations, []),
      authority_separation_maintained: Map.get(data, :authority_separation, true),
      replay_determinism_preserved: Map.get(data, :replay_determinism, true),
      provenance_chains_intact: Map.get(data, :provenance_chains, true),
      checks_performed: Map.get(data, :checks_performed, 0),
      checks_passed: Map.get(data, :checks_passed, 0)
    }}
  end

  defp extract_performance_results(evidence) do
    # Extract performance metrics from campaign evidence
    content = Map.get(evidence, :content, %{})
    data = Map.get(content, :data, %{})
    measurements = Map.get(content, :measurements, %{})
    
    {:ok, %{
      status: determine_pass_fail(data),
      cpu_impact_percent: Map.get(data, :cpu_impact, 0),
      memory_impact_percent: Map.get(data, :memory_impact, 0),
      storage_impact_percent: Map.get(data, :storage_impact, 0),
      execution_time_impact_percent: Map.get(data, :execution_time_impact, 0),
      bottleneck_identified: Map.get(data, :bottleneck, nil),
      baseline_cpu_ms: Map.get(measurements, :baseline_cpu_ms, 0),
      projected_cpu_ms: Map.get(measurements, :projected_cpu_ms, 0)
    }}
  end

  defp extract_governance_results(evidence) do
    # Extract governance impact from campaign evidence
    content = Map.get(evidence, :content, %{})
    data = Map.get(content, :data, %{})
    
    {:ok, %{
      status: determine_pass_fail(data),
      institutions_affected: Map.get(data, :institutions_affected, []),
      power_concentration_change: Map.get(data, :power_concentration_change, 0),
      decision_making_impact: Map.get(data, :decision_making_impact, :neutral),
      institutional_fitness_change: Map.get(data, :fitness_change, 0),
      affected_role_count: Map.get(data, :affected_roles, 0)
    }}
  end

  defp extract_economic_results(evidence) do
    # Extract economic analysis from campaign evidence
    content = Map.get(evidence, :content, %{})
    data = Map.get(content, :data, %{})
    
    implementation_cost = Map.get(data, :implementation_cost, 0)
    benefit_value = Map.get(data, :benefit_value, 0)
    roi = if implementation_cost > 0, do: benefit_value / implementation_cost, else: 0
    
    {:ok, %{
      status: determine_pass_fail(data),
      implementation_cost: implementation_cost,
      operational_cost_annual: Map.get(data, :operational_cost, 0),
      benefit_value_annual: benefit_value,
      roi: roi,
      payback_period_months: calculate_payback(implementation_cost, benefit_value),
      development_hours: Map.get(data, :development_hours, 0),
      computational_cost_monthly: Map.get(data, :computational_cost, 0)
    }}
  end

  defp determine_pass_fail(data) do
    # Determine pass/fail based on evidence data
    case Map.get(data, :status) do
      :pass -> :pass
      :fail -> :fail
      _ ->
        # Default to pass if no explicit failures
        if Map.get(data, :has_failures, false), do: :fail, else: :pass
    end
  end

  defp calculate_payback(cost, annual_benefit) do
    # Calculate payback period in months
    if annual_benefit > 0 do
      ceil((cost / annual_benefit) * 12)
    else
      :infinity
    end
  end
end
