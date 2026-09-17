defmodule TiannaraRuntime.Civilization.Scenarios.RiskAssessmentEngine do
  def initialize do
    {:ok, %{risks: [], categories: [:critical_dependencies, :single_points_of_failure, :knowledge_bottlenecks, :institution_bottlenecks, :resource_bottlenecks, :governance_bottlenecks]}}
  end

  def assess(engine, civilization) do
    risks = assess_critical_dependencies(civilization) ++
            assess_single_points_of_failure(civilization) ++
            assess_knowledge_bottlenecks(civilization) ++
            assess_institution_bottlenecks(civilization) ++
            assess_resource_bottlenecks(civilization) ++
            assess_governance_bottlenecks(civilization)
    {:ok, %{engine | risks: risks}}
  end

  defp assess_critical_dependencies(civ) do
    severity = if Map.get(civ, :institutional_health, 0.5) < 0.3, do: 0.8, else: 0.3
    [%{category: :critical_dependencies, severity: severity, description: "critical_institutional_dependencies", mitigation: "diversify_institutional_network"}]
  end

  defp assess_single_points_of_failure(civ) do
    severity = if Map.get(civ, :infrastructure, 0.5) < 0.25, do: 0.9, else: 0.4
    [%{category: :single_points_of_failure, severity: severity, description: "infrastructure_single_points", mitigation: "redundant_systems"}]
  end

  defp assess_knowledge_bottlenecks(civ) do
    severity = if Map.get(civ, :knowledge_growth, 0.5) < 0.2, do: 0.85, else: 0.35
    [%{category: :knowledge_bottlenecks, severity: severity, description: "knowledge_flow_bottlenecks", mitigation: "knowledge_dissemination_programs"}]
  end

  defp assess_institution_bottlenecks(civ) do
    severity = if Map.get(civ, :institutional_health, 0.5) < 0.3, do: 0.75, else: 0.25
    [%{category: :institution_bottlenecks, severity: severity, description: "institutional_capacity_limits", mitigation: "institution_strengthening"}]
  end

  defp assess_resource_bottlenecks(civ) do
    severity = if Map.get(civ, :economic_stability, 0.5) < 0.2, do: 0.8, else: 0.3
    [%{category: :resource_bottlenecks, severity: severity, description: "resource_allocation_constraints", mitigation: "resource_optimization"}]
  end

  defp assess_governance_bottlenecks(civ) do
    severity = if Map.get(civ, :civilization_readiness, 0.5) < 0.3, do: 0.7, else: 0.2
    [%{category: :governance_bottlenecks, severity: severity, description: "governance_coordination_gaps", mitigation: "governance_reform"}]
  end

  def get_critical(engine, threshold) do
    critical = Enum.filter(Map.get(engine, :risks, []), fn r -> Map.get(r, :severity, 0.0) >= threshold end)
    {:ok, critical}
  end

  def metrics(engine) do
    risks = Map.get(engine, :risks, [])
    categories = Map.get(engine, :categories, [])
    critical = Enum.count(risks, fn r -> Map.get(r, :severity, 0.0) >= 0.7 end)
    {:ok, %{total_risks: length(risks), critical: critical, categories: length(categories)}}
  end
end
