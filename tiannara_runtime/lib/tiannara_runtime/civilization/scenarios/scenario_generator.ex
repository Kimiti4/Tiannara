defmodule TiannaraRuntime.Civilization.Scenarios.ScenarioGenerator do
  def generate(engine, civilization, scenario_type) do
    modifiers = type_modifiers(scenario_type)
    base_state = extract_state(civilization)
    modified = Map.merge(base_state, modifiers, fn _k, v1, v2 -> v1 + v2 end)
    clamped = Map.new(modified, fn {k, v} -> {k, clamp(v, 0.0, 1.0)} end)
    scenario = %{
      id: "gen_#{:erlang.unique_integer([:positive])}",
      type: scenario_type,
      base_state: base_state,
      modified_state: clamped,
      assumptions: Map.get(modifiers, :assumptions, [])
    }
    scenarios = Map.put(Map.get(engine, :scenarios, %{}), Map.get(scenario, :id), scenario)
    {:ok, %{engine | scenarios: scenarios}}
  end

  def list_types(_engine) do
    {:ok, [:scientific_acceleration, :resource_scarcity, :infrastructure_failure, :pandemic, :climate_adaptation, :technological_breakthrough, :governance_stress, :population_growth, :interplanetary_expansion, :knowledge_loss]}
  end

  def metrics(engine) do
    {:ok, %{generated_count: map_size(Map.get(engine, :scenarios, %{}))}}
  end

  defp extract_state(civ) do
    %{
      scientific_output: Map.get(civ, :scientific_output, 0.5),
      knowledge_growth: Map.get(civ, :knowledge_growth, 0.5),
      infrastructure: Map.get(civ, :infrastructure, 0.5),
      economic_stability: Map.get(civ, :economic_stability, 0.5),
      institutional_health: Map.get(civ, :institutional_health, 0.5),
      civilization_readiness: Map.get(civ, :civilization_readiness, 0.5)
    }
  end

  defp type_modifiers(:scientific_acceleration) do
    %{scientific_output: 0.3, knowledge_growth: 0.2, infrastructure: -0.1, assumptions: [:increased_research_funding, :breakthrough_discoveries]}
  end

  defp type_modifiers(:resource_scarcity) do
    %{economic_stability: -0.3, infrastructure: -0.2, civilization_readiness: -0.1, assumptions: [:depleting_resources, :supply_chain_disruption]}
  end

  defp type_modifiers(:infrastructure_failure) do
    %{infrastructure: -0.4, economic_stability: -0.2, institutional_health: -0.1, assumptions: [:aging_infrastructure, :systemic_collapse_risk]}
  end

  defp type_modifiers(:pandemic) do
    %{institutional_health: -0.3, economic_stability: -0.2, knowledge_growth: -0.1, assumptions: [:pathogen_outbreak, :healthcare_strain]}
  end

  defp type_modifiers(:climate_adaptation) do
    %{infrastructure: -0.2, civilization_readiness: 0.2, scientific_output: 0.1, assumptions: [:extreme_weather, :adaptation_measures]}
  end

  defp type_modifiers(:technological_breakthrough) do
    %{scientific_output: 0.4, knowledge_growth: 0.3, civilization_readiness: 0.2, assumptions: [:paradigm_shift, :new_technology]}
  end

  defp type_modifiers(:governance_stress) do
    %{institutional_health: -0.3, economic_stability: -0.2, civilization_readiness: -0.1, assumptions: [:political_instability, :policy_paralysis]}
  end

  defp type_modifiers(:population_growth) do
    %{infrastructure: -0.2, economic_stability: -0.1, civilization_readiness: 0.1, assumptions: [:demographic_expansion, :urbanization_pressure]}
  end

  defp type_modifiers(:interplanetary_expansion) do
    %{civilization_readiness: 0.3, scientific_output: 0.2, infrastructure: 0.1, assumptions: [:space_colonization, :interplanetary_logistics]}
  end

  defp type_modifiers(:knowledge_loss) do
    %{knowledge_growth: -0.4, scientific_output: -0.3, institutional_health: -0.2, assumptions: [:information_degradation, :cultural_amnesia]}
  end

  defp type_modifiers(_unknown) do
    %{assumptions: [:unknown_scenario]}
  end

  defp clamp(value, min_val, max_val) do
    value |> max(min_val) |> min(max_val)
  end
end
