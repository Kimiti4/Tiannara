defmodule TiannaraRuntime.Civilization.Scenarios.ScenarioEngine do
  def initialize do
    {:ok, %{scenarios: %{}, comparisons: [], recommendations: []}}
  end

  def register_scenario(engine, scenario) do
    registered = %{
      id: "scenario_#{:erlang.unique_integer([:positive])}",
      name: Map.get(scenario, :name),
      type: Map.get(scenario, :type),
      assumptions: Map.get(scenario, :assumptions, []),
      state: Map.get(scenario, :state, %{}),
      created_at: :erlang.unique_integer([:positive])
    }
    scenarios = Map.put(Map.get(engine, :scenarios, %{}), Map.get(registered, :id), registered)
    {:ok, %{engine | scenarios: scenarios}}
  end

  def compare(engine, scenario_a_id, scenario_b_id) do
    scenarios = Map.get(engine, :scenarios, %{})
    a = Map.get(scenarios, scenario_a_id, %{})
    b = Map.get(scenarios, scenario_b_id, %{})
    state_a = Map.get(a, :state, %{})
    state_b = Map.get(b, :state, %{})
    dimensions = [:scientific_output, :knowledge_growth, :infrastructure, :economic_stability, :institutional_health, :civilization_readiness]
    differences = Map.new(dimensions, fn dim ->
      {dim, Map.get(state_a, dim, 0.0) - Map.get(state_b, dim, 0.0)}
    end)
    {:ok, %{scenario_a: scenario_a_id, scenario_b: scenario_b_id, differences: differences}}
  end

  def metrics(engine) do
    {:ok, %{
      scenario_count: map_size(Map.get(engine, :scenarios, %{})),
      comparison_count: length(Map.get(engine, :comparisons, []))
    }}
  end
end
