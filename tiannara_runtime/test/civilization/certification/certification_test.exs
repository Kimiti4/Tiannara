defmodule TiannaraRuntime.Civilization.Certification.CertificationTest do
  use ExUnit.Case
  @moduletag :civilization
  @moduletag :certification
  @moduletag :stress

  alias TiannaraRuntime.Civilization.Ontology.CivilizationState
  alias TiannaraRuntime.Civilization.Ontology.GovernanceModel
  alias TiannaraRuntime.Civilization.Ontology.InfrastructureModel
  alias TiannaraRuntime.Civilization.Ontology.EconomyModel
  alias TiannaraRuntime.Civilization.Ontology.CultureModel
  alias TiannaraRuntime.Civilization.Ontology.KnowledgeModel
  alias TiannaraRuntime.Civilization.Ontology.TechnologyPortfolio
  alias TiannaraRuntime.Civilization.Registry.CivilizationRegistry
  alias TiannaraRuntime.Civilization.Registry.InstitutionRegistry
  alias TiannaraRuntime.Civilization.Registry.CivilizationGraphRegistry
  alias TiannaraRuntime.Civilization.Runtime.CivilizationScheduler
  alias TiannaraRuntime.Civilization.Runtime.InstitutionCoordinator
  alias TiannaraRuntime.Civilization.Runtime.GovernanceCoordinator
  alias TiannaraRuntime.Civilization.Runtime.InfrastructureRuntime
  alias TiannaraRuntime.Civilization.Runtime.KnowledgeRuntime
  alias TiannaraRuntime.Civilization.Economy.ScientificCapitalLedger
  alias TiannaraRuntime.Civilization.Economy.CapitalAllocator
  alias TiannaraRuntime.Civilization.Economy.PortfolioAllocator
  alias TiannaraRuntime.Civilization.Economy.InvestmentPlanner
  alias TiannaraRuntime.Civilization.Economy.ScientificMarket
  alias TiannaraRuntime.Civilization.Economy.EconomyReplay
  alias TiannaraRuntime.Civilization.Economy.EconomyArchaeology
  alias TiannaraRuntime.Civilization.Portfolio.ResearchPortfolioManager
  alias TiannaraRuntime.Civilization.Portfolio.ResearchProgramRegistry
  alias TiannaraRuntime.Civilization.Portfolio.PriorityEngine
  alias TiannaraRuntime.Civilization.Portfolio.BottleneckAnalyzer
  alias TiannaraRuntime.Civilization.Portfolio.ResourcePlanner
  alias TiannaraRuntime.Civilization.Portfolio.MilestoneTracker
  alias TiannaraRuntime.Civilization.Portfolio.PortfolioReplay
  alias TiannaraRuntime.Civilization.Portfolio.PortfolioArchaeology
  alias TiannaraRuntime.Civilization.Coordination.CivilizationCoordinator
  alias TiannaraRuntime.Civilization.Coordination.DomainCollaborationEngine
  alias TiannaraRuntime.Civilization.Coordination.DependencyCoordinator
  alias TiannaraRuntime.Civilization.Coordination.InfrastructureCoordinator
  alias TiannaraRuntime.Civilization.Coordination.CivilizationObjectiveManager
  alias TiannaraRuntime.Civilization.Coordination.KnowledgeExchangeEngine
  alias TiannaraRuntime.Civilization.Coordination.CoordinationReplay
  alias TiannaraRuntime.Civilization.Coordination.CoordinationArchaeology
  alias TiannaraRuntime.Civilization.Planning.CivilizationPlanner
  alias TiannaraRuntime.Civilization.Planning.StrategicObjectiveEngine
  alias TiannaraRuntime.Civilization.Planning.HorizonPlanner
  alias TiannaraRuntime.Civilization.Planning.DependencyProjectionEngine
  alias TiannaraRuntime.Civilization.Planning.CivilizationRoadmapEngine
  alias TiannaraRuntime.Civilization.Planning.PlanningReplay
  alias TiannaraRuntime.Civilization.Planning.PlanningArchaeology
  alias TiannaraRuntime.Civilization.Scenarios.ScenarioEngine
  alias TiannaraRuntime.Civilization.Scenarios.ScenarioGenerator
  alias TiannaraRuntime.Civilization.Scenarios.ScenarioComparator
  alias TiannaraRuntime.Civilization.Scenarios.ResilienceAnalyzer
  alias TiannaraRuntime.Civilization.Scenarios.RiskAssessmentEngine
  alias TiannaraRuntime.Civilization.Scenarios.StrategicRecommendationEngine
  alias TiannaraRuntime.Civilization.Scenarios.ScenarioReplay
  alias TiannaraRuntime.Civilization.Scenarios.ScenarioArchaeology

  defp build_civilization do
    {:ok, cs} = CivilizationState.new(%{civilization_id: "stress_civ"})
    {:ok, gm} = GovernanceModel.new(%{civilization_id: "stress_civ"})
    {:ok, im} = InfrastructureModel.new(%{civilization_id: "stress_civ"})
    {:ok, em} = EconomyModel.new(%{civilization_id: "stress_civ"})
    {:ok, cm} = CultureModel.new(%{civilization_id: "stress_civ"})
    {:ok, km} = KnowledgeModel.new(%{civilization_id: "stress_civ"})
    {:ok, tp} = TechnologyPortfolio.new(%{civilization_id: "stress_civ"})
    {cs, gm, im, em, cm, km, tp}
  end

  defp build_registry do
    {:ok, reg} = CivilizationRegistry.initialize()
    {:ok, ireg} = InstitutionRegistry.initialize()
    {:ok, greg} = CivilizationGraphRegistry.initialize()
    {:ok, greg} = CivilizationGraphRegistry.add_node(greg, "civ_root", :civilization)
    {:ok, greg} = CivilizationGraphRegistry.add_node(greg, "inst_1", :institution)
    {:ok, greg} = CivilizationGraphRegistry.add_node(greg, "tech_1", :technology)
    {:ok, greg} = CivilizationGraphRegistry.add_edge(greg, "civ_root", "inst_1", :governs)
    {:ok, greg} = CivilizationGraphRegistry.add_edge(greg, "inst_1", "tech_1", :funds)
    {reg, ireg, greg}
  end

  defp build_runtime do
    {:ok, sched} = CivilizationScheduler.initialize()
    {:ok, icoord} = InstitutionCoordinator.initialize()
    {:ok, gcoord} = GovernanceCoordinator.initialize()
    {:ok, infra} = InfrastructureRuntime.initialize(%{energy: %{level: 5, capacity: 100, health: 1.0}, transport: %{level: 3, capacity: 50, health: 0.9}})
    {:ok, kr} = KnowledgeRuntime.initialize()
    {sched, icoord, gcoord, infra, kr}
  end

  defp build_economy do
    {:ok, ledger} = ScientificCapitalLedger.initialize()
    {:ok, alloc} = CapitalAllocator.initialize(1000)
    {:ok, pall} = PortfolioAllocator.initialize([:physics, :biology, :mathematics])
    {:ok, planner} = InvestmentPlanner.initialize()
    {:ok, market} = ScientificMarket.initialize()
    {ledger, alloc, pall, planner, market}
  end

  defp build_portfolio do
    {:ok, mgr} = ResearchPortfolioManager.initialize()
    {:ok, preg} = ResearchProgramRegistry.initialize()
    {:ok, peng} = PriorityEngine.initialize()
    {:ok, ban} = BottleneckAnalyzer.initialize()
    {:ok, rpl} = ResourcePlanner.initialize(500)
    {:ok, mt} = MilestoneTracker.initialize()
    {mgr, preg, peng, ban, rpl, mt}
  end

  defp build_coordination do
    {:ok, coord} = CivilizationCoordinator.initialize()
    {:ok, collab} = DomainCollaborationEngine.initialize([:physics, :biology, :mathematics, :engineering])
    {:ok, dc} = DependencyCoordinator.initialize()
    {:ok, ic} = InfrastructureCoordinator.initialize()
    {:ok, om} = CivilizationObjectiveManager.initialize()
    {:ok, kee} = KnowledgeExchangeEngine.initialize()
    {coord, collab, dc, ic, om, kee}
  end

  defp build_planning do
    {:ok, oe} = StrategicObjectiveEngine.initialize()
    {:ok, hp} = HorizonPlanner.initialize()
    {:ok, dpe} = DependencyProjectionEngine.initialize()
    {:ok, rme} = CivilizationRoadmapEngine.initialize()
    {oe, hp, dpe, rme}
  end

  defp build_scenarios do
    {:ok, eng} = ScenarioEngine.initialize()
    {:ok, comp} = ScenarioComparator.initialize()
    {:ok, ra} = ResilienceAnalyzer.initialize()
    {:ok, rae} = RiskAssessmentEngine.initialize()
    {:ok, sre} = StrategicRecommendationEngine.initialize()
    {eng, comp, ra, rae, sre}
  end

  test "run all subsystems together end-to-end" do
    {cs, gm, im, em, cm, km, tp} = build_civilization()
    assert cs.id != nil
    assert gm.id != nil
    assert im.id != nil
    assert em.id != nil
    assert cm.id != nil
    assert km.id != nil
    assert tp.id != nil

    {reg, ireg, greg} = build_registry()
    {:ok, reg} = CivilizationRegistry.register(reg, %{id: "civ_stress"})
    {:ok, ireg} = InstitutionRegistry.register(ireg, %{id: "inst_stress"})
    {:ok, counts} = CivilizationGraphRegistry.count(greg)
    assert counts.nodes == 3
    assert counts.edges == 2

    {sched, icoord, gcoord, infra, kr} = build_runtime()
    {:ok, sched} = CivilizationScheduler.enqueue(sched, %{id: "t1", priority: 1})
    {:ok, sched} = CivilizationScheduler.enqueue(sched, %{id: "t2", priority: 2})
    {:ok, sched} = CivilizationScheduler.schedule(sched, %{"t1" => [], "t2" => []})
    {:ok, {_item, sched}} = CivilizationScheduler.next(sched)
    {:ok, icoord} = InstitutionCoordinator.activate(icoord, %{id: "inst_a"})
    {:ok, icoord} = InstitutionCoordinator.coordinate(icoord, "inst_a", "inst_b", :particle_physics)
    {:ok, gcoord} = GovernanceCoordinator.execute_policy(gcoord, %{name: "Science Act"})
    {:ok, infra} = InfrastructureRuntime.tick(infra)
    {:ok, infra} = InfrastructureRuntime.invest(infra, :energy, 3)
    {:ok, kr} = KnowledgeRuntime.add_discovery(kr, %{id: "d1", domain: :physics, type: :theories})

    {ledger, alloc, pall, planner, market} = build_economy()
    {:ok, ledger} = ScientificCapitalLedger.record_transaction(ledger, :gov, :university, 200, :grant)
    {:ok, alloc} = CapitalAllocator.allocate(alloc, "fusion", 300, :energy_research)
    {:ok, pall} = PortfolioAllocator.allocate(pall, :physics, 150)
    {:ok, planner} = InvestmentPlanner.plan(planner, "fusion", 500, 10, 2.5)
    {:ok, market} = ScientificMarket.list_asset(market, "patent_1", :patent, 5000)
    {:ok, _} = ScientificMarket.exchange(market, :university, :corp, "patent_1")
    {:ok, verified} = ScientificCapitalLedger.verify(ledger)
    assert verified == false

    {mgr, preg, peng, ban, rpl, mt} = build_portfolio()
    {:ok, mgr} = ResearchPortfolioManager.add_portfolio(mgr, %{id: "port_1", domain: :physics})
    {:ok, preg} = ResearchProgramRegistry.register(preg, %{id: "prog_x", domain: :mathematics})
    {:ok, peng} = PriorityEngine.compute(peng, [%{id: "prog_x", constitutional_priority: 5}], %{})
    {:ok, _} = ResourcePlanner.plan(rpl, "prog_x", 100, :compute)
    {:ok, _} = MilestoneTracker.add_milestone(mt, "prog_x", %{name: "Publish"})

    {coord, collab, dc, ic, om, kee} = build_coordination()
    {:ok, coord} = CivilizationCoordinator.coordinate(coord, :physics, :mathematics, :joint_project)
    {:ok, collab} = DomainCollaborationEngine.propose(collab, :physics, :biology, "quantum_bio")
    {:ok, dc} = DependencyCoordinator.add_dependency(dc, "fusion", "theory", :depends_on)
    ic = %{ic | shared_resources: %{hpc: 1000}}
    {:ok, ic} = InfrastructureCoordinator.request(ic, "lab", :hpc, 200)
    {:ok, _} = InfrastructureCoordinator.allocate(ic, hd(ic.requests).id)
    {:ok, om} = CivilizationObjectiveManager.add_objective(om, %{name: "Fusion", status: :active})
    {:ok, kee} = KnowledgeExchangeEngine.exchange(kee, :physics, :engineering, %{theory: "plasma"})

    {oe, hp, dpe, rme} = build_planning()
    planner_state = %{}
    {:ok, plan} = CivilizationPlanner.create_plan(planner_state, "Stress Plan", 50)
    {:ok, oe} = StrategicObjectiveEngine.add_objective(oe, %{name: "Fusion Energy", expected_impact: 0.9})
    {:ok, hp} = HorizonPlanner.plan(hp, 10, [%{id: "fusion"}])
    {:ok, _} = DependencyProjectionEngine.project(dpe, :theory, :engineering, 0.7)
    {:ok, _} = CivilizationRoadmapEngine.construct(rme, [%{id: "obj1", required_institutions: ["i1"], required_research: ["r1"]}], [plan], [10, 25])

    {seng, scomp, ra, rae, sre} = build_scenarios()
    civ_state = %{scientific_output: 0.6, knowledge_growth: 0.5, infrastructure: 0.4, economic_stability: 0.5, institutional_health: 0.6, civilization_readiness: 0.5}
    {:ok, seng} = ScenarioEngine.register_scenario(seng, %{name: "baseline", type: :growth, state: civ_state})
    {:ok, gen} = ScenarioGenerator.generate(%{scenarios: %{}}, civ_state, :scientific_acceleration)
    {:ok, _} = ScenarioComparator.rank(scomp, [civ_state |> Map.put(:id, "c1"), civ_state |> Map.put(:id, "c2")])
    {:ok, _} = ResilienceAnalyzer.analyze(ra, civ_state)
    {:ok, rae} = RiskAssessmentEngine.assess(rae, civ_state)
    {:ok, _} = StrategicRecommendationEngine.generate(sre, civ_state, rae.risks, Map.values(gen.scenarios))
  end

  test "determinism: same economic operations produce same balances and allocations" do
    {ledger, alloc, _, _, _} = build_economy()
    {:ok, ledger1} = ScientificCapitalLedger.record_transaction(ledger, :a, :b, 50, :grant)
    {:ok, alloc1} = CapitalAllocator.allocate(alloc, "p1", 100, :research)

    {:ok, ledger2} = ScientificCapitalLedger.record_transaction(ledger, :a, :b, 50, :grant)
    {:ok, alloc2} = CapitalAllocator.allocate(alloc, "p1", 100, :research)

    assert ledger1.balances == ledger2.balances
    assert alloc1.allocations == alloc2.allocations
    assert length(ledger1.transactions) == length(ledger2.transactions)
  end

  test "all subsystem replays pass verification" do
    {ledger, alloc, _, planner, _} = build_economy()
    {:ok, ledger} = ScientificCapitalLedger.record_transaction(ledger, :a, :b, 30, :grant)
    {:ok, alloc} = CapitalAllocator.allocate(alloc, "p1", 50, :research)
    {:ok, p} = InvestmentPlanner.plan(planner, "p1", 100, 5, 1.5)
    {:ok, replay} = EconomyReplay.record(ledger, alloc, p)
    {:ok, :verified} = EconomyReplay.verify(replay, ledger, alloc, p)

    {:ok, mgr} = ResearchPortfolioManager.initialize()
    {:ok, preg} = ResearchProgramRegistry.initialize()
    {:ok, peng} = PriorityEngine.initialize()
    {:ok, mgr} = ResearchPortfolioManager.add_portfolio(mgr, %{id: "pf1"})
    {:ok, preg} = ResearchProgramRegistry.register(preg, %{id: "rp1", domain: :physics})
    {:ok, peng} = PriorityEngine.compute(peng, [%{id: "rp1"}], %{})
    {:ok, preplay} = PortfolioReplay.record(mgr, preg, peng)
    {:ok, :verified} = PortfolioReplay.verify(preplay, mgr, preg, peng)

    {:ok, coord} = CivilizationCoordinator.initialize()
    {:ok, collab} = DomainCollaborationEngine.initialize([:physics])
    {:ok, dc} = DependencyCoordinator.initialize()
    {:ok, coord} = CivilizationCoordinator.coordinate(coord, :a, :b, :sync)
    {:ok, creplay} = CoordinationReplay.record(coord, collab, dc)
    {:ok, :verified} = CoordinationReplay.verify(creplay, coord, collab, dc)

    planner_state = %{}
    {:ok, plan} = CivilizationPlanner.create_plan(planner_state, "Test", 10)
    {:ok, oe} = StrategicObjectiveEngine.initialize()
    {:ok, hp} = HorizonPlanner.initialize()
    {:ok, plreplay} = PlanningReplay.record(Map.put(planner_state, plan.id, plan), oe, hp)
    {:ok, :verified} = PlanningReplay.verify(plreplay, Map.put(planner_state, plan.id, plan), oe, hp)

    {:ok, seng} = ScenarioEngine.initialize()
    civ_state = %{scientific_output: 0.5, knowledge_growth: 0.5, infrastructure: 0.5, economic_stability: 0.5, institutional_health: 0.5, civilization_readiness: 0.5}
    {:ok, sgen} = ScenarioGenerator.generate(%{scenarios: %{}}, civ_state, :scientific_acceleration)
    {:ok, scomp} = ScenarioComparator.initialize()
    {:ok, screplay} = ScenarioReplay.record(seng, sgen, scomp)
    {:ok, :verified} = ScenarioReplay.verify(screplay, seng, sgen, scomp)
  end
end
