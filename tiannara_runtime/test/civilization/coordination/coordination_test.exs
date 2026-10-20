defmodule TiannaraRuntime.Civilization.Coordination.CoordinationTest do
  use ExUnit.Case
  @moduletag :civilization
  @moduletag :coordination

  alias TiannaraRuntime.Civilization.Coordination.CivilizationCoordinator
  alias TiannaraRuntime.Civilization.Coordination.DomainCollaborationEngine
  alias TiannaraRuntime.Civilization.Coordination.DependencyCoordinator
  alias TiannaraRuntime.Civilization.Coordination.InfrastructureCoordinator
  alias TiannaraRuntime.Civilization.Coordination.CivilizationObjectiveManager
  alias TiannaraRuntime.Civilization.Coordination.KnowledgeExchangeEngine
  alias TiannaraRuntime.Civilization.Coordination.CoordinationReplay
  alias TiannaraRuntime.Civilization.Coordination.CoordinationArchaeology

  test "coordinator coordinate and synchronize" do
    {:ok, coord} = CivilizationCoordinator.initialize()
    {:ok, coord} = CivilizationCoordinator.coordinate(coord, :physics, :mathematics, :cross_pollinate)
    {:ok, coord} = CivilizationCoordinator.synchronize(coord, %{phase: :active, tick: 42})
    assert length(coord.collaborations) == 1
    assert coord.sync_state == %{phase: :active, tick: 42}
    {:ok, metrics} = CivilizationCoordinator.metrics(coord)
    assert metrics.collaborations == 1
  end

  test "collab_engine propose and activate" do
    {:ok, eng} = DomainCollaborationEngine.initialize([:physics, :biology, :mathematics])
    {:ok, eng} = DomainCollaborationEngine.propose(eng, :physics, :biology, "unified_theory")
    proposal_id = hd(eng.proposals).id
    {:ok, eng} = DomainCollaborationEngine.activate(eng, proposal_id)
    {:ok, metrics} = DomainCollaborationEngine.metrics(eng)
    assert metrics.edges == 1
    assert metrics.proposals == 1
    {:ok, pairs} = DomainCollaborationEngine.find_potential(eng)
    assert length(pairs) == 6
  end

  test "dep_coordinator add_dependency, validate, and tsort" do
    {:ok, dc} = DependencyCoordinator.initialize()
    {:ok, dc} = DependencyCoordinator.add_dependency(dc, "a", "b", :depends_on)
    {:ok, dc} = DependencyCoordinator.add_dependency(dc, "b", "c", :depends_on)
    assert DependencyCoordinator.validate(dc) == :ok
    {:ok, sorted} = DependencyCoordinator.topological_sort(dc)
    assert sorted == ["c", "b", "a"]
    {:ok, dc} = DependencyCoordinator.add_dependency(dc, "c", "a", :depends_on)
    assert DependencyCoordinator.validate(dc) == {:error, :cycle_detected}
  end

  test "infra_coordinator request and allocate" do
    {:ok, ic} = InfrastructureCoordinator.initialize()
    ic = %{ic | shared_resources: %{compute: 100}}
    {:ok, ic} = InfrastructureCoordinator.request(ic, "lab_a", :compute, 40)
    req_id = hd(ic.requests).id
    {:ok, ic} = InfrastructureCoordinator.allocate(ic, req_id)
    {:ok, metrics} = InfrastructureCoordinator.metrics(ic)
    assert metrics.total_allocations == 1
    {:ok, ic} = InfrastructureCoordinator.request(ic, "lab_b", :compute, 200)
    req_id2 = List.last(ic.requests).id
    assert InfrastructureCoordinator.allocate(ic, req_id2) == {:error, :unavailable}
  end

  test "objective_manager add and update_progress" do
    {:ok, om} = CivilizationObjectiveManager.initialize()
    {:ok, om} = CivilizationObjectiveManager.add_objective(om, %{name: "Colonize Mars", status: :active})
    obj_id = hd(om.ordered_ids)
    {:ok, om} = CivilizationObjectiveManager.update_progress(om, obj_id, 0.5)
    {:ok, actives} = CivilizationObjectiveManager.get_objectives(om, :active)
    assert length(actives) == 1
    {:ok, metrics} = CivilizationObjectiveManager.metrics(om)
    assert metrics.total == 1
  end

  test "knowledge_exchange_engine" do
    {:ok, kee} = KnowledgeExchangeEngine.initialize()
    {:ok, kee} = KnowledgeExchangeEngine.exchange(kee, :physics, :biology, %{theory: "quantum_biology"})
    {:ok, transfers} = KnowledgeExchangeEngine.get_transfers(kee, :physics)
    assert length(transfers) == 1
    {:ok, metrics} = KnowledgeExchangeEngine.metrics(kee)
    assert metrics.total_exchanges == 1
    assert metrics.domains_involved == 2
  end

  test "coordination replay" do
    {:ok, coord} = CivilizationCoordinator.initialize()
    {:ok, collab} = DomainCollaborationEngine.initialize([:physics])
    {:ok, dep} = DependencyCoordinator.initialize()
    {:ok, coord} = CivilizationCoordinator.coordinate(coord, :a, :b, :sync)
    {:ok, replay} = CoordinationReplay.record(coord, collab, dep)
    assert is_map(replay)
    {:ok, :verified} = CoordinationReplay.verify(replay, coord, collab, dep)
    bad_coord = %{coord | collaborations: []}
    assert CoordinationReplay.verify(replay, bad_coord, collab, dep) == {:error, :hash_mismatch}
  end

  test "coordination archaeology" do
    {:ok, coord} = CivilizationCoordinator.initialize()
    {:ok, collab} = DomainCollaborationEngine.initialize([:physics, :biology])
    {:ok, coord} = CivilizationCoordinator.coordinate(coord, :a, :b, :merge)
    {:ok, archaeology} = CoordinationArchaeology.record(coord, collab, "Phase19")
    {:ok, explanation} = CoordinationArchaeology.explain(archaeology)
    assert String.contains?(explanation, "Phase19")
    {:ok, lineage} = CoordinationArchaeology.get_lineage(archaeology)
    assert lineage == []
  end
end
