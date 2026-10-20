defmodule TiannaraRuntime.Civilization.Portfolio.PortfolioTest do
  use ExUnit.Case
  @moduletag :civilization
  @moduletag :portfolio

  alias TiannaraRuntime.Civilization.Portfolio.ResearchPortfolioManager
  alias TiannaraRuntime.Civilization.Portfolio.ResearchProgramRegistry
  alias TiannaraRuntime.Civilization.Portfolio.PriorityEngine
  alias TiannaraRuntime.Civilization.Portfolio.BottleneckAnalyzer
  alias TiannaraRuntime.Civilization.Portfolio.ResourcePlanner
  alias TiannaraRuntime.Civilization.Portfolio.MilestoneTracker
  alias TiannaraRuntime.Civilization.Portfolio.PortfolioReplay
  alias TiannaraRuntime.Civilization.Portfolio.PortfolioArchaeology

  test "manager add_portfolio and metrics" do
    {:ok, mgr} = ResearchPortfolioManager.initialize()
    {:ok, mgr} = ResearchPortfolioManager.add_portfolio(mgr, %{id: "pf1", domain: :physics})
    {:ok, mgr} = ResearchPortfolioManager.add_portfolio(mgr, %{id: "pf2", domain: :biology})
    {:ok, metrics} = ResearchPortfolioManager.metrics(mgr)
    assert metrics.portfolio_count == 2
    assert metrics.balance == 0.5
    assert metrics.diversity == 0.0
    assert ResearchPortfolioManager.validate(mgr) == :ok
  end

  test "registry register and archive" do
    {:ok, reg} = ResearchProgramRegistry.initialize()
    program = %{id: "prog_1", domain: :mathematics, name: "Algebraic Topology"}
    {:ok, reg} = ResearchProgramRegistry.register(reg, program)
    {:ok, found} = ResearchProgramRegistry.lookup(reg, "prog_1")
    assert found.name == "Algebraic Topology"
    {:ok, reg} = ResearchProgramRegistry.archive(reg, "prog_1")
    {:ok, archived} = ResearchProgramRegistry.lookup(reg, "prog_1")
    assert archived.status == :archived
    assert ResearchProgramRegistry.archive(reg, "nonexistent") == {:error, :not_found}
  end

  test "priority_engine compute" do
    {:ok, eng} = PriorityEngine.initialize()
    programs = [
      %{id: "p1", constitutional_priority: 3, dependency_depth: 1, timestamp: 100},
      %{id: "p2", constitutional_priority: 5, dependency_depth: 2, timestamp: 200}
    ]
    {:ok, eng} = PriorityEngine.compute(eng, programs, %{})
    {:ok, rank} = PriorityEngine.get_priority(eng, "p2")
    assert rank == 1
    {:ok, rank} = PriorityEngine.get_priority(eng, "p1")
    assert rank == 2
    assert PriorityEngine.get_priority(eng, "nonexistent") == {:error, :not_found}
  end

  test "bottleneck_analyzer analyze" do
    {:ok, analyzer} = BottleneckAnalyzer.initialize()
    civ = %{research_output: 0.2, engineering_capacity: 0.1, infrastructure_health: 0.4, economic_output: 0.6}
    {:ok, analyzer} = BottleneckAnalyzer.analyze(analyzer, civ)
    {:ok, severe} = BottleneckAnalyzer.get_bottlenecks(analyzer, 0.5)
    assert length(severe) > 0
    {:ok, metrics} = BottleneckAnalyzer.metrics(analyzer)
    assert metrics.total > 0
  end

  test "resource_planner plan and allocate" do
    {:ok, planner} = ResourcePlanner.initialize(100)
    {:ok, planner} = ResourcePlanner.plan(planner, "prog_1", 30, :computation)
    {:ok, planner} = ResourcePlanner.plan(planner, "prog_2", 20, :storage)
    {:ok, planner} = ResourcePlanner.allocate(planner, "prog_1")
    {:ok, metrics} = ResourcePlanner.metrics(planner)
    assert metrics.planned == 20
    assert metrics.allocated == 30
    assert metrics.remaining == 50
    assert ResourcePlanner.plan(planner, "prog_3", 200, :compute) == {:error, :insufficient}
  end

  test "milestone_tracker add_milestone and complete" do
    {:ok, tracker} = MilestoneTracker.initialize()
    {:ok, tracker} = MilestoneTracker.add_milestone(tracker, "prog_1", %{name: "Publish Paper"})
    {:ok, tracker} = MilestoneTracker.add_milestone(tracker, "prog_1", %{name: "Peer Review"})
    {:ok, milestones} = MilestoneTracker.get_program_milestones(tracker, "prog_1")
    assert length(milestones) == 2
    completed_id = hd(milestones).id
    {:ok, tracker} = MilestoneTracker.complete(tracker, completed_id)
    {:ok, metrics} = MilestoneTracker.metrics(tracker)
    assert metrics.completed == 1
    assert metrics.total == 2
  end

  test "replay record and verify" do
    {:ok, mgr} = ResearchPortfolioManager.initialize()
    {:ok, reg} = ResearchProgramRegistry.initialize()
    {:ok, eng} = PriorityEngine.initialize()
    {:ok, mgr} = ResearchPortfolioManager.add_portfolio(mgr, %{id: "pf1"})
    {:ok, reg} = ResearchProgramRegistry.register(reg, %{id: "rp1", domain: :physics})
    {:ok, eng} = PriorityEngine.compute(eng, [%{id: "rp1"}], %{})
    {:ok, replay} = PortfolioReplay.record(mgr, reg, eng)
    assert is_map(replay)
    {:ok, :verified} = PortfolioReplay.verify(replay, mgr, reg, eng)
    bad_mgr = %{mgr | portfolios: []}
    assert PortfolioReplay.verify(replay, bad_mgr, reg, eng) == {:error, :hash_mismatch}
  end

  test "archaeology record and explain" do
    {:ok, mgr} = ResearchPortfolioManager.initialize()
    {:ok, reg} = ResearchProgramRegistry.initialize()
    {:ok, mgr} = ResearchPortfolioManager.add_portfolio(mgr, %{id: "pf1"})
    {:ok, archaeology} = PortfolioArchaeology.record(mgr, reg, "Phase19")
    {:ok, explanation} = PortfolioArchaeology.explain(archaeology)
    assert String.contains?(explanation, "Phase19")
    {:ok, lineage} = PortfolioArchaeology.get_lineage(archaeology)
    assert lineage == []
  end
end
