defmodule Tiannara.REA.PortfolioDynamicsTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.TheorySelection
  alias Tiannara.REA.MetaTheoryExtractor
  alias Tiannara.REA.TheoryPortfolio
  alias Tiannara.REA.PortfolioRebalancer
  alias Tiannara.REA.PortfolioRiskAnalyzer
  alias Tiannara.REA.TheoryTensor

  describe "Phase 11.18 Theory Portfolio Governance Verification Suite" do

    test "Q1 (HHI Concentration - TP5) — HHI correctly measures concentration risk" do
      # 1. Monoculture: 100% in one theory
      weights_monoculture = %{"theory_alpha" => 1.0, "theory_beta" => 0.0, "theory_gamma" => 0.0, "theory_delta" => 0.0}
      hhi_mono = PortfolioRiskAnalyzer.calculate_hhi(weights_monoculture)
      assert hhi_mono == 1.0

      # 2. Balanced uniform: 25% each for 4 theories
      weights_uniform = %{"theory_alpha" => 0.25, "theory_beta" => 0.25, "theory_gamma" => 0.25, "theory_delta" => 0.25}
      hhi_uniform = PortfolioRiskAnalyzer.calculate_hhi(weights_uniform)
      assert hhi_uniform == 0.25
    end

    test "Q2 (Rebalancing Friction - TP6) — Weight rebalancing is suppressed below threshold" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      # Start with balanced portfolio weights
      initial_weights = %{"theory_alpha" => 0.25, "theory_beta" => 0.25, "theory_gamma" => 0.25, "theory_delta" => 0.25}
      portfolio = %TheoryPortfolio{
        weights: initial_weights,
        current_mode: :balanced,
        history: [],
        governance_history: []
      }

      # Use a high friction threshold of 1.0 (which is larger than any possible weight shift for 0.25 base weights)
      context = %{volatility: 0.16, complexity: 0.11, adversariality: 0.06}
      updated = PortfolioRebalancer.rebalance(portfolio, tensor, context, :climate, :balanced, 1.0)

      # Under a high friction threshold, the weights should NOT change
      assert updated.weights == initial_weights
      assert updated.tracking_error == 0.0
    end

    test "Q3 (Aggregate Extinction Risk - TP5) — Portfolio extinction risk scales as weighted hazard ratios" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      # Override specific hazard ratios for test assertions
      tensor_override = %{tensor |
        hazard_ratios: %{"theory_alpha" => 0.10, "theory_beta" => 0.30, "theory_gamma" => 0.50, "theory_delta" => 0.70}
      }

      portfolio_uniform = %TheoryPortfolio{
        weights: %{"theory_alpha" => 0.25, "theory_beta" => 0.25, "theory_gamma" => 0.25, "theory_delta" => 0.25},
        current_mode: :balanced,
        history: [],
        governance_history: []
      }

      # Force portfolio weights to remain uniform by using threshold = 1.0
      context = %{volatility: 0.5, complexity: 0.5, adversariality: 0.0}
      rebalanced = PortfolioRebalancer.rebalance(portfolio_uniform, tensor_override, context, :climate, :balanced, 1.0)

      expected_pe = 0.25 * 0.10 + 0.25 * 0.30 + 0.25 * 0.50 + 0.25 * 0.70
      assert rebalanced.extinction_risk == Float.round(expected_pe, 4)
    end

    test "Q4 (Correlation Risk - TP2) — Focus covariance is correctly calculated" do
      # Highly correlated focus portfolio (Theory Alpha is volatile, Beta complex, Gamma adversarial)
      # If we assign weights to overlapping focuses, correlation risk shifts
      weights_high = %{"theory_alpha" => 0.90, "theory_beta" => 0.10}
      weights_low = %{"theory_alpha" => 0.50, "theory_beta" => 0.50}

      cr_high = PortfolioRiskAnalyzer.calculate_correlation_risk(weights_high, nil)
      cr_low = PortfolioRiskAnalyzer.calculate_correlation_risk(weights_low, nil)

      assert cr_high != cr_low
    end

    test "Q5 (Dependency Graph Risk - TP4) — Portfolios with shared ancestry have higher dependency risk" do
      # 1. Independent portfolio: baseline theories with empty parent ancestries
      independent_theories = [
        %TheoryTensor{theory_id: "theory_alpha", parent_theories: []},
        %TheoryTensor{theory_id: "theory_beta", parent_theories: []},
        %TheoryTensor{theory_id: "theory_gamma", parent_theories: []},
        %TheoryTensor{theory_id: "theory_delta", parent_theories: []}
      ]

      weights = %{"theory_alpha" => 0.25, "theory_beta" => 0.25, "theory_gamma" => 0.25, "theory_delta" => 0.25}
      dr_indep = PortfolioRiskAnalyzer.calculate_dependency_risk(weights, nil, independent_theories)
      assert dr_indep == 0.0 # No ancestry overlap

      # 2. High dependency portfolio: theories share common ancestors
      dependent_theories = [
        %TheoryTensor{theory_id: "theory_child_1", parent_theories: ["theory_alpha"]},
        %TheoryTensor{theory_id: "theory_child_2", parent_theories: ["theory_alpha"]},
        %TheoryTensor{theory_id: "theory_alpha", parent_theories: []}
      ]
      weights_dep = %{"theory_child_1" => 0.50, "theory_child_2" => 0.50}
      dr_dep = PortfolioRiskAnalyzer.calculate_dependency_risk(weights_dep, nil, dependent_theories)

      assert dr_dep > 0.0
    end

    test "Q6 (Cascading Failure Risk - TP4) — CFR correctly traces dynamic failure propagation" do
      # 1. Independent theories: CFR should be low
      independent_theories = [
        %TheoryTensor{theory_id: "t_a", parent_theories: []},
        %TheoryTensor{theory_id: "t_b", parent_theories: []},
        %TheoryTensor{theory_id: "t_c", parent_theories: []},
        %TheoryTensor{theory_id: "t_d", parent_theories: []}
      ]
      weights = %{"t_a" => 0.25, "t_b" => 0.25, "t_c" => 0.25, "t_d" => 0.25}
      cfr_indep = PortfolioRiskAnalyzer.calculate_cfr(weights, nil, independent_theories)

      # 2. Dependent theories: failing ancestor t_a collapses descendant child_1 and child_2
      dependent_theories = [
        %TheoryTensor{theory_id: "t_a", parent_theories: []},
        %TheoryTensor{theory_id: "child_1", parent_theories: ["t_a"]},
        %TheoryTensor{theory_id: "child_2", parent_theories: ["t_a"]}
      ]
      weights_dep = %{"t_a" => 0.60, "child_1" => 0.20, "child_2" => 0.20}
      cfr_dep = PortfolioRiskAnalyzer.calculate_cfr(weights_dep, nil, dependent_theories)

      # Ancestry sharing increases cascade risk since a single failure takes down the descendants
      assert cfr_dep > cfr_indep
    end

    test "Q7 (Portfolio Recovery Capacity - TP3) — PRC correctly measures restoration yield under shock" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      weights = %{"theory_alpha" => 0.25, "theory_beta" => 0.25, "theory_gamma" => 0.25, "theory_delta" => 0.25}
      context = %{volatility: 0.20, complexity: 0.20, adversariality: 0.10}

      prc = PortfolioRiskAnalyzer.calculate_prc(weights, tensor, context, :climate, theories)
      assert prc >= 0.01 and prc <= 1.0

      # Assert floor protection in security score is active
      portfolio = %TheoryPortfolio{
        weights: weights,
        current_mode: :balanced,
        history: [],
        governance_history: []
      }
      rebalanced = PortfolioRebalancer.rebalance(portfolio, tensor, context, :climate, :balanced, 1.0)
      assert rebalanced.security_score >= 0.0
    end

    test "Q8 (Portfolio Adaptation Velocity - TP6) — PAV correctly tracks responsiveness" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      initial_weights = %{"theory_alpha" => 0.10, "theory_beta" => 0.10, "theory_gamma" => 0.10, "theory_delta" => 0.70}
      portfolio = %TheoryPortfolio{
        weights: initial_weights,
        current_mode: :balanced,
        history: [],
        governance_history: []
      }

      # Force rebalancing to a balanced regime context
      context = %{volatility: 0.8, complexity: 0.1, adversariality: 0.1}
      rebalanced = PortfolioRebalancer.rebalance(portfolio, tensor, context, :climate, :balanced, 0.0)

      # Adaptation velocity should record the total weight shift sum
      assert rebalanced.adaptation_velocity > 0.0
      expected_shift = Enum.sum(Enum.map(rebalanced.weights, fn {tid, w} -> abs(w - Map.get(initial_weights, tid, 0.0)) end))
      assert rebalanced.adaptation_velocity == Float.round(expected_shift, 4)
    end

    test "Q9 (Cognitive Immune Law - TP1) — Balanced low-dependency portfolios outcompete monocultures" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      # 1. Monoculture Portfolio
      portfolio_mono = %TheoryPortfolio{
        weights: %{"theory_alpha" => 1.0, "theory_beta" => 0.0, "theory_gamma" => 0.0, "theory_delta" => 0.0},
        current_mode: :balanced,
        history: [],
        governance_history: []
      }

      # 2. Balanced/Diversified Portfolio
      portfolio_div = %TheoryPortfolio{
        weights: %{"theory_alpha" => 0.25, "theory_beta" => 0.25, "theory_gamma" => 0.25, "theory_delta" => 0.25},
        current_mode: :balanced,
        history: [],
        governance_history: []
      }

      context = %{volatility: 0.50, complexity: 0.50, adversariality: 0.80}

      # Run with threshold = 1.0 to ensure they preserve their specific monoculture vs diversified structures
      rebalanced_mono = PortfolioRebalancer.rebalance(portfolio_mono, tensor, context, :climate, :balanced, 1.0)
      rebalanced_div = PortfolioRebalancer.rebalance(portfolio_div, tensor, context, :climate, :balanced, 1.0)

      # Diversified portfolio must yield a higher security score under adversarial stress
      assert rebalanced_div.security_score > rebalanced_mono.security_score
    end

    test "Q10 (Coordinated Attack Resistance - TP1) — Diversified portfolios resist attacks better" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      # Apply coordinates corresponding to a coordinated attack (hostile adversariality, high volatility, complex)
      attack_context = %{volatility: 0.90, complexity: 0.90, adversariality: 0.95}

      portfolio_mono = %TheoryPortfolio{
        weights: %{"theory_alpha" => 1.0, "theory_beta" => 0.0, "theory_gamma" => 0.0, "theory_delta" => 0.0},
        current_mode: :balanced,
        history: [],
        governance_history: []
      }

      portfolio_div = %TheoryPortfolio{
        weights: %{"theory_alpha" => 0.25, "theory_beta" => 0.25, "theory_gamma" => 0.25, "theory_delta" => 0.25},
        current_mode: :balanced,
        history: [],
        governance_history: []
      }

      # Use threshold = 1.0 to preserve structure under attack
      shocked_mono = PortfolioRebalancer.rebalance(portfolio_mono, tensor, attack_context, :climate, :balanced, 1.0)
      shocked_div = PortfolioRebalancer.rebalance(portfolio_div, tensor, attack_context, :climate, :balanced, 1.0)

      IO.inspect(
        %{mono_security: shocked_mono.security_score, div_security: shocked_div.security_score},
        label: "Coordinated Attack Security Scores"
      )

      # Diversified portfolio maintains a higher security score under attack
      assert shocked_div.security_score > shocked_mono.security_score
    end

    test "Q11 (Active Governance Advantage - TP6) — Active Rebalancing outperforms static uniform and static single theory" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)
      theory_map = Map.new(theories, & {&1.theory_id, &1})

      # Varying regimes sequence
      regimes = [
        %{volatility: 0.85, complexity: 0.15, domain: :climate},
        %{volatility: 0.15, complexity: 0.85, domain: :technology},
        %{volatility: 0.75, complexity: 0.25, domain: :climate},
        %{volatility: 0.25, complexity: 0.75, domain: :technology}
      ]

      # 1. Active Rebalancing Portfolio (threshold = 0.0 allows dynamic weight adjustments)
      {_final_portfolio, active_yields} =
        Enum.reduce(regimes, {%TheoryPortfolio{weights: %{"theory_alpha" => 0.25, "theory_beta" => 0.25, "theory_gamma" => 0.25, "theory_delta" => 0.25}, current_mode: :balanced, history: [], governance_history: []}, []}, fn context, {p_acc, yields_acc} ->
          p_new = PortfolioRebalancer.rebalance(p_acc, tensor, context, context.domain, :balanced, 0.0)
          
          # Compute yield fitness
          yield =
            Enum.reduce(p_new.weights, 0.0, fn {tid, w}, acc ->
              t = Map.get(theory_map, tid)
              fit = TheorySelection.calculate_fitness(t, context.volatility, context.complexity)
              acc + w * fit
            end)

          {p_new, [yield | yields_acc]}
        end)

      # 2. Static Uniform Portfolio (fixed 0.25 weights)
      static_uniform_yields =
        Enum.map(regimes, fn context ->
          tids = ["theory_alpha", "theory_beta", "theory_gamma", "theory_delta"]
          Enum.reduce(tids, 0.0, fn tid, acc ->
            t = Map.get(theory_map, tid)
            fit = TheorySelection.calculate_fitness(t, context.volatility, context.complexity)
            acc + 0.25 * fit
          end)
        end)

      # 3. Static Single Theory (100% Theory Alpha)
      static_single_yields =
        Enum.map(regimes, fn context ->
          t = Map.get(theory_map, "theory_alpha")
          TheorySelection.calculate_fitness(t, context.volatility, context.complexity)
        end)

      avg_active = Enum.sum(active_yields) / length(regimes)
      avg_uniform = Enum.sum(static_uniform_yields) / length(regimes)
      avg_single = Enum.sum(static_single_yields) / length(regimes)

      IO.inspect(
        %{active: avg_active, static_uniform: avg_uniform, static_single: avg_single},
        label: "Portfolio Strategy Long-Term Yields"
      )

      # Active rebalancing portfolio outcompetes both static strategies
      assert avg_active > avg_uniform
      assert avg_active > avg_single
    end
  end
end
