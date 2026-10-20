defmodule TiannaraRuntime.Civilization.Planning.PlanningTest do
  use ExUnit.Case
  @moduletag :civilization
  @moduletag :planning

  alias TiannaraRuntime.Civilization.Planning.CivilizationPlanner
  alias TiannaraRuntime.Civilization.Planning.StrategicObjectiveEngine
  alias TiannaraRuntime.Civilization.Planning.HorizonPlanner
  alias TiannaraRuntime.Civilization.Planning.DependencyProjectionEngine
  alias TiannaraRuntime.Civilization.Planning.CivilizationRoadmapEngine
  alias TiannaraRuntime.Civilization.Planning.PlanningReplay
  alias TiannaraRuntime.Civilization.Planning.PlanningArchaeology

  test "planner create, revise, and compare plans" do
    planner = %{}
    {:ok, plan1} = CivilizationPlanner.create_plan(planner, "Mars Colonization", 25)
    {:ok, plan2} = CivilizationPlanner.create_plan(planner, "Deep Space Network", 50)
    planner = Map.put(planner, plan1.id, plan1)
    {:ok, revised} = CivilizationPlanner.revise_plan(planner, plan1.id, %{status: :approved})
    assert revised.status == :approved
    assert CivilizationPlanner.revise_plan(planner, "nonexistent", %{}) == {:error, :not_found}
    planner = Map.put(Map.put(planner, plan1.id, revised), plan2.id, plan2)
    {:ok, comparison} = CivilizationPlanner.compare_plans(planner, plan1.id, plan2.id)
    assert comparison.horizon_diff == -25
    {:ok, metrics} = CivilizationPlanner.metrics(planner)
    assert metrics.plan_count == 2
  end

  test "objective add and update_impact" do
    {:ok, eng} = StrategicObjectiveEngine.initialize()
    {:ok, eng} = StrategicObjectiveEngine.add_objective(eng, %{name: "Fusion Energy", description: "Achieve net-positive fusion", expected_impact: 0.8})
    [obj_id] = Map.keys(eng.objectives)
    {:ok, eng} = StrategicObjectiveEngine.update_impact(eng, obj_id, 0.95)
    assert eng.objectives[obj_id].expected_impact == 0.95
    assert StrategicObjectiveEngine.update_impact(eng, "nonexistent", 0.5) == {:error, :not_found}
    {:ok, actives} = StrategicObjectiveEngine.get_objectives_by_status(eng, :active)
    assert length(actives) == 1
    {:ok, metrics} = StrategicObjectiveEngine.metrics(eng)
    assert metrics.total == 1
  end

  test "horizon plan and project" do
    {:ok, hp} = HorizonPlanner.initialize()
    {:ok, hp} = HorizonPlanner.plan(hp, 10, [%{id: "prog_a"}, %{id: "prog_b"}])
    {:ok, programs} = HorizonPlanner.get_horizon(hp, 10)
    assert length(programs) == 2
    {:ok, projection} = HorizonPlanner.project(hp, 10)
    assert projection.horizon == 10
    assert projection.program_count == 2
    {:ok, metrics} = HorizonPlanner.metrics(hp)
    assert metrics[10] == 2
  end

  test "dependency project and forecast" do
    {:ok, dpe} = DependencyProjectionEngine.initialize()
    {:ok, dpe} = DependencyProjectionEngine.project(dpe, :math, :physics, 0.8)
    assert length(dpe.projections) == 1
    deps = %{"math->physics" => 0.5, "physics->engineering" => 0.3}
    {:ok, forecast} = DependencyProjectionEngine.forecast(dpe, deps, 3)
    assert length(forecast) == 3
    {:ok, metrics} = DependencyProjectionEngine.metrics(dpe)
    assert metrics.total_projections == 1
  end

  test "roadmap construct and compare" do
    {:ok, rme} = CivilizationRoadmapEngine.initialize()
    objectives = [%{id: "obj1", required_institutions: ["inst_a"], required_research: ["res_b"]}]
    plans = [%{id: "plan_x"}]
    {:ok, rme} = CivilizationRoadmapEngine.construct(rme, objectives, plans, [10, 25, 50])
    {:ok, current} = CivilizationRoadmapEngine.get_current(rme)
    assert current.id != nil
    {:ok, rme} = CivilizationRoadmapEngine.construct(rme, objectives, [%{id: "plan_y"}], [10])
    second_id = hd(Enum.reverse(rme.roadmaps)).id
    {:ok, comparison} = CivilizationRoadmapEngine.compare(rme, current.id, second_id)
    assert comparison.timeline_diff == 2
    {:ok, metrics} = CivilizationRoadmapEngine.metrics(rme)
    assert metrics.roadmap_count == 2
  end

  test "planning replay" do
    planner = %{}
    {:ok, plan} = CivilizationPlanner.create_plan(planner, "Test Plan", 10)
    planner = Map.put(planner, plan.id, plan)
    {:ok, oe} = StrategicObjectiveEngine.initialize()
    {:ok, hp} = HorizonPlanner.initialize()
    {:ok, replay} = PlanningReplay.record(planner, oe, hp)
    assert is_map(replay)
    {:ok, :verified} = PlanningReplay.verify(replay, planner, oe, hp)
    bad_hp = %{hp | horizons: %{}}
    assert PlanningReplay.verify(replay, planner, oe, bad_hp) == {:error, :hash_mismatch}
  end

  test "planning archaeology" do
    planner = %{}
    {:ok, plan} = CivilizationPlanner.create_plan(planner, "Archaeology Plan", 100)
    planner = Map.put(planner, plan.id, %{plan | status: :approved})
    {:ok, oe} = StrategicObjectiveEngine.initialize()
    {:ok, archaeology} = PlanningArchaeology.record(planner, oe, "Phase19")
    {:ok, explanation} = PlanningArchaeology.explain(archaeology)
    assert explanation == "civilization_planning_record"
    {:ok, lineage} = PlanningArchaeology.get_lineage(archaeology)
    assert lineage.origin == "Phase19"
  end
end
