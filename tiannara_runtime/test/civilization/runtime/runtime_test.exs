defmodule TiannaraRuntime.Civilization.Runtime.RuntimeTest do
  use ExUnit.Case
  @moduletag :civilization
  @moduletag :runtime

  alias TiannaraRuntime.Civilization.Runtime.CivilizationScheduler
  alias TiannaraRuntime.Civilization.Runtime.InstitutionCoordinator
  alias TiannaraRuntime.Civilization.Runtime.GovernanceCoordinator
  alias TiannaraRuntime.Civilization.Runtime.InfrastructureRuntime
  alias TiannaraRuntime.Civilization.Runtime.KnowledgeRuntime

  test "scheduler enqueue, schedule, and next cycle" do
    {:ok, scheduler} = CivilizationScheduler.initialize()
    item_a = %{id: "task_a", priority: 1}
    item_b = %{id: "task_b", priority: 2}
    {:ok, scheduler} = CivilizationScheduler.enqueue(scheduler, item_a)
    {:ok, scheduler} = CivilizationScheduler.enqueue(scheduler, item_b)
    {:ok, scheduler} = CivilizationScheduler.schedule(scheduler, %{"task_a" => [], "task_b" => ["task_a"]})
    {:ok, {next, rest}} = CivilizationScheduler.next(scheduler)
    assert next.id == "task_b"
    assert length(rest.order) == 1
    {:ok, {next, rest}} = CivilizationScheduler.next(rest)
    assert next.id == "task_a"
    assert CivilizationScheduler.next(rest) == {:error, :empty}
  end

  test "coordinator activate and coordinate" do
    {:ok, coord} = InstitutionCoordinator.initialize()
    inst = %{id: "inst_1", name: "Research Lab"}
    {:ok, coord} = InstitutionCoordinator.activate(coord, inst)
    {:ok, coord} = InstitutionCoordinator.coordinate(coord, "inst_1", "inst_2", :physics)
    {:ok, metrics} = InstitutionCoordinator.metrics(coord)
    assert metrics.institution_count == 1
    assert metrics.collaboration_count == 1
  end

  test "governance execute_policy" do
    {:ok, gov} = GovernanceCoordinator.initialize()
    policy = %{name: "Research Acceleration Act", domain: :science}
    {:ok, gov} = GovernanceCoordinator.execute_policy(gov, policy)
    assert length(gov.policies) == 1
    assert hd(gov.policies).name == "Research Acceleration Act"
    {:ok, gov} = GovernanceCoordinator.delegate(gov, "council", "ministry", :research)
    {:ok, metrics} = GovernanceCoordinator.metrics(gov)
    assert metrics.policy_count == 1
    assert metrics.authority_chain_length == 1
  end

  test "infrastructure tick and invest" do
    {:ok, infra} = InfrastructureRuntime.initialize(%{energy: %{level: 5, capacity: 100, health: 1.0}})
    {:ok, invested} = InfrastructureRuntime.invest(infra, :energy, 2)
    assert invested[:energy][:level] == 7
    assert invested[:energy][:capacity] == 120
    {:ok, ticked} = InfrastructureRuntime.tick(invested)
    assert ticked[:energy][:health] < 1.0
  end

  test "knowledge add_discovery and query" do
    {:ok, kr} = KnowledgeRuntime.initialize()
    discovery = %{id: "d1", domain: :mathematics, type: :repositories, content: "New Theorem"}
    {:ok, kr} = KnowledgeRuntime.add_discovery(kr, discovery)
    {:ok, results} = KnowledgeRuntime.query(kr, :mathematics)
    assert length(results) == 1
    {:ok, metrics} = KnowledgeRuntime.metrics(kr)
    assert metrics.repositories == 1
  end

  test "scheduler cycle detection" do
    cyclic = %{"a" => ["b"], "b" => ["c"], "c" => ["a"]}
    {:ok, result} = CivilizationScheduler.cycle_detected?(cyclic)
    assert result == true
    acyclic = %{"a" => ["b"], "b" => ["c"], "c" => []}
    {:ok, result} = CivilizationScheduler.cycle_detected?(acyclic)
    assert result == false
  end

  test "institution coordinator synchronize discoveries" do
    {:ok, coord} = InstitutionCoordinator.initialize()
    {:ok, coord} = InstitutionCoordinator.activate(coord, %{id: "i1"})
    {:ok, coord} = InstitutionCoordinator.activate(coord, %{id: "i2"})
    {:ok, coord} = InstitutionCoordinator.synchronize(coord, [%{discovery_id: "d1"}])
    assert length(coord.activity_log) == 2
    {:ok, metrics} = InstitutionCoordinator.metrics(coord)
    assert metrics.activity_count == 2
  end
end
