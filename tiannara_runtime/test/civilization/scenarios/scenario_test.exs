defmodule TiannaraRuntime.Civilization.Scenarios.ScenarioTest do
  use ExUnit.Case
  @moduletag :civilization
  @moduletag :scenarios

  alias TiannaraRuntime.Civilization.Scenarios.ScenarioEngine
  alias TiannaraRuntime.Civilization.Scenarios.ScenarioGenerator
  alias TiannaraRuntime.Civilization.Scenarios.ScenarioComparator
  alias TiannaraRuntime.Civilization.Scenarios.ResilienceAnalyzer
  alias TiannaraRuntime.Civilization.Scenarios.RiskAssessmentEngine
  alias TiannaraRuntime.Civilization.Scenarios.StrategicRecommendationEngine
  alias TiannaraRuntime.Civilization.Scenarios.ScenarioReplay
  alias TiannaraRuntime.Civilization.Scenarios.ScenarioArchaeology

  test "engine register and compare scenarios" do
    {:ok, eng} = ScenarioEngine.initialize()
    {:ok, eng} = ScenarioEngine.register_scenario(eng, %{name: "Optimistic", type: :growth, state: %{scientific_output: 0.8, knowledge_growth: 0.7, infrastructure: 0.6, economic_stability: 0.7, institutional_health: 0.8, civilization_readiness: 0.7}})
    [sid1] = Map.keys(eng.scenarios)
    {:ok, eng} = ScenarioEngine.register_scenario(eng, %{name: "Pessimistic", type: :decline, state: %{scientific_output: 0.2, knowledge_growth: 0.3, infrastructure: 0.3, economic_stability: 0.2, institutional_health: 0.3, civilization_readiness: 0.2}})
    [_, sid2] = Map.keys(eng.scenarios)
    {:ok, comparison} = ScenarioEngine.compare(eng, sid1, sid2)
    assert comparison.differences[:scientific_output] > 0
    {:ok, metrics} = ScenarioEngine.metrics(eng)
    assert metrics.scenario_count == 2
  end

  test "generator generates three scenario types" do
    {:ok, gen} = ScenarioGenerator.generate(%{scenarios: %{}}, %{scientific_output: 0.5, knowledge_growth: 0.5, infrastructure: 0.5, economic_stability: 0.5, institutional_health: 0.5, civilization_readiness: 0.5}, :scientific_acceleration)
    assert map_size(gen.scenarios) == 1
    {:ok, gen} = ScenarioGenerator.generate(gen, %{scientific_output: 0.5, knowledge_growth: 0.5, infrastructure: 0.5, economic_stability: 0.5, institutional_health: 0.5, civilization_readiness: 0.5}, :resource_scarcity)
    {:ok, gen} = ScenarioGenerator.generate(gen, %{scientific_output: 0.5, knowledge_growth: 0.5, infrastructure: 0.5, economic_stability: 0.5, institutional_health: 0.5, civilization_readiness: 0.5}, :technological_breakthrough)
    assert map_size(gen.scenarios) == 3
    {:ok, types} = ScenarioGenerator.list_types(gen)
    assert length(types) == 10
    {:ok, metrics} = ScenarioGenerator.metrics(gen)
    assert metrics.generated_count == 3
  end

  test "comparator rank" do
    {:ok, comp} = ScenarioComparator.initialize()
    scenarios = [
      %{id: "s1", scientific_output: 0.8, knowledge_growth: 0.7, infrastructure: 0.6, economic_stability: 0.7, institutional_health: 0.8, civilization_readiness: 0.7},
      %{id: "s2", scientific_output: 0.3, knowledge_growth: 0.4, infrastructure: 0.4, economic_stability: 0.3, institutional_health: 0.4, civilization_readiness: 0.3}
    ]
    {:ok, ranked} = ScenarioComparator.rank(comp, scenarios)
    [top | _] = ranked
    assert elem(top, 0) == "s1"
    {:ok, pair} = ScenarioComparator.compare_pair(comp, hd(scenarios), List.last(scenarios))
    assert pair.scenario_a == "s1"
  end

  test "resilience analyze" do
    {:ok, ra} = ResilienceAnalyzer.initialize()
    civ = %{institutional_health: 0.9, governance: 0.8, knowledge_growth: 0.7, scientific_output: 0.6, infrastructure: 0.5, economic_stability: 0.4, civilization_readiness: 0.8}
    {:ok, ra} = ResilienceAnalyzer.analyze(ra, civ)
    assert length(ra.resilience_profiles) == 1
    profile = hd(ra.resilience_profiles)
    assert profile.overall > 0
    {:ok, ra} = ResilienceAnalyzer.analyze(ra, civ)
    result = ResilienceAnalyzer.compare(ra, profile.id, hd(ra.resilience_profiles).id)
    assert match?({:ok, _}, result)
    {:ok, metrics} = ResilienceAnalyzer.metrics(ra)
    assert metrics.profile_count == 2
  end

  test "risk assess" do
    {:ok, rae} = RiskAssessmentEngine.initialize()
    civ = %{institutional_health: 0.2, infrastructure: 0.1, knowledge_growth: 0.1, economic_stability: 0.1, civilization_readiness: 0.2}
    {:ok, rae} = RiskAssessmentEngine.assess(rae, civ)
    {:ok, critical} = RiskAssessmentEngine.get_critical(rae, 0.7)
    assert length(critical) > 0
    {:ok, metrics} = RiskAssessmentEngine.metrics(rae)
    assert metrics.total_risks == 6
    assert metrics.critical > 0
  end

  test "recommendation generate" do
    {:ok, sre} = StrategicRecommendationEngine.initialize()
    risks = [%{category: :infrastructure, severity: 0.8, description: "crumbling_bridges"}]
    scenarios = [%{id: "sc1", type: :resource_scarcity}]
    {:ok, sre} = StrategicRecommendationEngine.generate(sre, %{}, risks, scenarios)
    {:ok, invest_recs} = StrategicRecommendationEngine.get_recommendations(sre, :investment)
    assert length(invest_recs) == 1
    {:ok, planning_recs} = StrategicRecommendationEngine.get_recommendations(sre, :planning)
    assert length(planning_recs) == 1
    {:ok, metrics} = StrategicRecommendationEngine.metrics(sre)
    assert metrics.total == 2
  end

  test "scenario replay" do
    {:ok, eng} = ScenarioEngine.initialize()
    {:ok, gen} = ScenarioGenerator.generate(%{scenarios: %{}}, %{scientific_output: 0.5, knowledge_growth: 0.5, infrastructure: 0.5, economic_stability: 0.5, institutional_health: 0.5, civilization_readiness: 0.5}, :scientific_acceleration)
    {:ok, comp} = ScenarioComparator.initialize()
    {:ok, replay} = ScenarioReplay.record(eng, gen, comp)
    assert is_map(replay)
    {:ok, :verified} = ScenarioReplay.verify(replay, eng, gen, comp)
    bad_gen = %{gen | scenarios: %{}}
    assert ScenarioReplay.verify(replay, eng, bad_gen, comp) == {:error, :hash_mismatch}
  end

  test "scenario archaeology" do
    {:ok, eng} = ScenarioEngine.initialize()
    {:ok, eng} = ScenarioEngine.register_scenario(eng, %{name: "Test", type: :growth})
    {:ok, archaeology} = ScenarioArchaeology.record(eng, %{scenarios: %{}}, "Phase19")
    {:ok, explanation} = ScenarioArchaeology.explain(archaeology)
    assert explanation == "scenario_simulation_record"
    {:ok, lineage} = ScenarioArchaeology.get_lineage(archaeology)
    assert lineage.origin == "Phase19"
  end
end
