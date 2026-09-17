defmodule Tiannara.REA.OrbitUnifiedImmuneTest do
  use ExUnit.Case, async: false

  alias Tiannara.REA.Epistemic.{
    Pathogen,
    PathogenRegistry,
    VaccineRegistry,
    QuarantineManager,
    ImmuneMemoryEcology,
    UnifiedImmuneSystem
  }
  alias Tiannara.REA.{TheorySelection, MetaTheoryExtractor, TheoryPortfolio, PortfolioRebalancer}

  setup do
    # Supervise the immune registry GenServers to guarantee a clean, isolated state per test
    start_supervised!(PathogenRegistry)
    start_supervised!(VaccineRegistry)
    start_supervised!(QuarantineManager)
    start_supervised!(ImmuneMemoryEcology)
    start_supervised!(UnifiedImmuneSystem)
    :ok
  end

  describe "Phase 11.19 Unified Cognitive Immune System Verification Suite" do

    test "Q1 (Pathogen Detection & Severity Hierarchy) — Active pathogens are detected and map to severity levels" do
      # 1. Start clean: should have default pathogens active
      active = PathogenRegistry.active_pathogens()
      assert length(active) > 0

      # 2. Evaluate threats with default active pathogens
      snapshot = %{epoch: 1}
      sys_eval = UnifiedImmuneSystem.evaluate_threats(snapshot, %{cascading_failure_risk: 0.1, dependency_risk: 0.1})
      
      assert sys_eval.security_stress > 0.0
      assert sys_eval.severity in [:warning, :infection, :outbreak, :pandemic, :constitutional]
    end

    test "Q2 (Pathogen Reproductive Ecology - P1/P2/P3/P4) — Pathogen Rt tracks spread, mutation, and extinction" do
      # Record a new infection
      PathogenRegistry.record_infection()
      PathogenRegistry.record_infection()

      # Mutate all pathogens to compute Rt
      {:ok, rt} = PathogenRegistry.mutate_all()
      assert rt > 0.0

      # Assert generations incremented
      active = PathogenRegistry.active_pathogens()
      assert Enum.all?(active, &(&1.generation > 0))

      # Cure all active pathogens to verify Pathogen Extinction (P1)
      Enum.each(active, fn p ->
        PathogenRegistry.update_status(p.id, :cured)
      end)

      active_now = PathogenRegistry.active_pathogens()
      assert Enum.empty?(active_now)
    end

    test "Q3 (Quarantine Enforcement) — Quarantined theories have their resource weights dropped to 0.0" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      # 1. Initial rebalance under normal conditions
      initial_weights = %{"theory_alpha" => 0.25, "theory_beta" => 0.25, "theory_gamma" => 0.25, "theory_delta" => 0.25}
      portfolio = %TheoryPortfolio{
        weights: initial_weights,
        current_mode: :balanced,
        history: [],
        governance_history: []
      }

      context = %{volatility: 0.1, complexity: 0.1, adversariality: 0.05}
      rebalanced_normal = PortfolioRebalancer.rebalance(portfolio, tensor, context, :climate, :balanced, 0.0)
      assert Map.get(rebalanced_normal.weights, "theory_alpha") > 0.0

      # 2. Quarantine "theory_alpha"
      QuarantineManager.quarantine_theory("theory_alpha", "High risk detected")
      assert QuarantineManager.is_quarantined?("theory_alpha")

      # Rebalance again
      rebalanced_quar = PortfolioRebalancer.rebalance(portfolio, tensor, context, :climate, :balanced, 0.0)

      # The weight for quarantined "theory_alpha" must drop to 0.0, and others normalized
      assert Map.get(rebalanced_quar.weights, "theory_alpha") == 0.0
      assert Enum.sum(Map.values(rebalanced_quar.weights)) == 1.0
    end

    test "Q4 (Vaccination Protection & P5 Immune Drift) — Cure registration generates vaccine, which decays when unused" do
      # 1. Cure confirmation_collapse
      pathogen_id = :confirmation_collapse
      p = PathogenRegistry.get_pathogen(pathogen_id)
      VaccineRegistry.register_cure(pathogen_id, p.signature, 0)

      # 2. Verify Vaccine exists
      vaccines = VaccineRegistry.get_vaccines()
      assert length(vaccines) == 1
      assert hd(vaccines).pathogen_id == :confirmation_collapse

      # 3. Calculate protection: should yield non-zero similarity protection
      prot = VaccineRegistry.calculate_protection(p.signature)
      assert prot > 0.9

      # 4. Verify P5 Immune Drift decay: decay vaccine efficacy
      VaccineRegistry.decay_efficacy(0.05)
      updated_vaccines = VaccineRegistry.get_vaccines()
      assert hd(updated_vaccines).efficacy < 1.0
    end

    test "Q5 (ESG Handshake Validation) — Proposed strikes are evaluated in Shadow-Graph sandbox" do
      # Test ESG validation logic directly
      # Fork shadow state, evaluate, and assert response
      {decision, score} = Tiannara.Sentinel.EpistemicShadowGraph.validate_intervention(
        :world_1, 
        :inject_novelty, 
        %{anomaly_severity: 0.5}
      )

      assert decision in [:approved, :rejected]
      assert score >= 0.0
    end

    test "Q6 (Constitutional Erosion Pathogen) — Constitutional erosion triggers rollback triage" do
      # Inject constitutional erosion threat
      {:ok, severity} = UnifiedImmuneSystem.handle_pathogen_threat(:constitutional_erosion, %{
        target_type: :civilization,
        target_id: :core,
        epoch: 10
      })

      # Should immediately scale to :constitutional severity
      assert severity == :constitutional
    end

    test "Q7 (Derived Security Stress Integration) — Portfolio security score scales by active pathogens and protection factors" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      initial_weights = %{"theory_alpha" => 0.25, "theory_beta" => 0.25, "theory_gamma" => 0.25, "theory_delta" => 0.25}
      portfolio = %TheoryPortfolio{
        weights: initial_weights,
        current_mode: :balanced,
        history: [],
        governance_history: []
      }

      context = %{volatility: 0.1, complexity: 0.1, adversariality: 0.05}
      
      # 1. Base run with default pathogens active (without vaccinations)
      rebalanced_threats = PortfolioRebalancer.rebalance(portfolio, tensor, context, :climate, :balanced, 0.0)
      score_threats = rebalanced_threats.security_score

      # 2. Add vaccines to resolve threats
      active_pathogens = PathogenRegistry.active_pathogens()
      Enum.each(active_pathogens, fn p ->
        VaccineRegistry.register_cure(p.id, p.signature, 0)
      end)

      # Rebalance again: security score should increase due to vaccine protection scaling
      rebalanced_vaccinated = PortfolioRebalancer.rebalance(portfolio, tensor, context, :climate, :balanced, 0.0)
      score_vaccinated = rebalanced_vaccinated.security_score

      assert score_vaccinated > score_threats
    end

    test "Q8 (Immune Strategy Selection & Fitness) — Strategy weights evolve using replicator dynamics" do
      # Gather initial strategies
      initial_strats = ImmuneMemoryEcology.get_strategies()
      assert Enum.all?(initial_strats, &(&1.fitness == 1.0))

      # Simulate a successful threat resolution to evolve strategy weights
      ImmuneMemoryEcology.evaluate_fitness(%{
        epoch: 5,
        active_pathogen_family: :confirmation_collapse,
        threat_resolved: true,
        resolution_time: 2.1,
        yield_drop: 0.0,
        cfr: 0.0,
        false_positives: 0.0
      })

      # Evolved strategies should have updated fitness values
      evolved_strats = ImmuneMemoryEcology.get_strategies()
      refute Enum.all?(evolved_strats, &(&1.fitness == 1.0))

      best = ImmuneMemoryEcology.best_strategy()
      assert best != nil
    end

  end
end
