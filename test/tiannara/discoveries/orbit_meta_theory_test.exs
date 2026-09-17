defmodule Tiannara.REA.MetaTheoryTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.TheorySelection
  alias Tiannara.REA.MetaTheoryExtractor
  alias Tiannara.REA.MetaTheoryLearner
  alias Tiannara.REA.MetaTheoryPredictor

  describe "Phase 11.17 Meta-Theory Physics Verification Suite" do

    test "Q1 (Trust Integration - MT1) — Success increases trust and failure decays trust" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      initial_trust = Map.get(tensor.theory_trust_weights, "theory_alpha")
      assert initial_trust == 0.50

      # 1. Success case: Trust should increase towards 1.0
      context_success = %{volatility: 0.2, complexity: 0.2, adversariality: 0.1, domain: :climate}
      tensor_after_success = MetaTheoryLearner.learn(tensor, "theory_alpha", context_success, true, 0.05)
      success_trust = Map.get(tensor_after_success.theory_trust_weights, "theory_alpha")

      assert success_trust > initial_trust
      assert success_trust <= 0.99

      # Verify episode is logged
      assert length(tensor_after_success.selection_history) == 1
      [episode] = tensor_after_success.selection_history
      assert episode.validation_result == :success
      assert episode.selected_theory == "theory_alpha"

      # 2. Failure case: Trust should decay
      context_fail = %{volatility: 0.2, complexity: 0.2, adversariality: 0.1, domain: :climate}
      tensor_after_fail = MetaTheoryLearner.learn(tensor, "theory_alpha", context_fail, false, -0.10)
      fail_trust = Map.get(tensor_after_fail.theory_trust_weights, "theory_alpha")

      assert fail_trust < initial_trust
      assert fail_trust >= 0.01
    end

    test "Q2 (Theory Forgetting - MT2) — Trust weight decays for obsolete/unused theories" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      initial_trust = Map.get(tensor.theory_trust_weights, "theory_alpha")

      # Apply decay
      decayed_tensor = MetaTheoryLearner.decay_trust(tensor, "theory_alpha", 0.15)
      decayed_trust = Map.get(decayed_tensor.theory_trust_weights, "theory_alpha")

      assert decayed_trust < initial_trust
      assert decayed_trust == Float.round(initial_trust * (1.0 - 0.15), 4)
    end

    test "Q3 (Coordinate Transfer - MT3) — Domain coordinate trust transfers scale based on similarity" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      initial_trust = Map.get(tensor.theory_trust_weights, "theory_alpha")

      # Transfer trust with a similarity coefficient
      similarity = 0.80
      transferred_tensor = MetaTheoryLearner.transfer_trust(tensor, "theory_alpha", similarity)
      transferred_trust = Map.get(transferred_tensor.theory_trust_weights, "theory_alpha")

      assert transferred_trust < initial_trust
      assert transferred_trust == Float.round(initial_trust * similarity, 4)
    end

    test "Q4 (Contextual Selection - MT4) — Verify dynamic shifts in recommendations across geometry" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      # Test volatile regime
      volatile_context = %{volatility: 0.85, complexity: 0.15, adversariality: 0.20}
      rec_volatile = MetaTheoryPredictor.recommend(tensor, volatile_context, :climate)

      # Test complex regime
      complex_context = %{volatility: 0.15, complexity: 0.85, adversariality: 0.15}
      rec_complex = MetaTheoryPredictor.recommend(tensor, complex_context, :technology)

      IO.inspect(
        %{volatile: rec_volatile.recommended_theory, complex: rec_complex.recommended_theory},
        label: "Dynamic Contextual Recommendations"
      )

      # Assert that recommendations are dynamically dependent on context geometry and differ
      assert rec_volatile.recommended_theory != "N/A"
      assert rec_complex.recommended_theory != "N/A"
      assert rec_volatile.recommended_theory != rec_complex.recommended_theory
    end

    test "Q5 (Confidence Sensitivity) — Unfamiliar/far environments register lower confidence ratings" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      # Familiar environment (close to theory_alpha focus: volatility 0.8, complexity 0.2, adversariality 0.3, domain: :climate)
      familiar_context = %{volatility: 0.8, complexity: 0.2, adversariality: 0.3}
      rec_familiar = MetaTheoryPredictor.recommend(tensor, familiar_context, :climate)

      # Unfamiliar environment (very high coordinates, mismatching domain :education)
      unfamiliar_context = %{volatility: 0.95, complexity: 0.95, adversariality: 0.95}
      rec_unfamiliar = MetaTheoryPredictor.recommend(tensor, unfamiliar_context, :education)

      assert rec_familiar.confidence > rec_unfamiliar.confidence
    end

    test "Q6 (Seed Invariance) — Recommendation predictions are robust against small noise perturbations" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      base_context = %{volatility: 0.8, complexity: 0.2, adversariality: 0.3}
      base_rec = MetaTheoryPredictor.recommend(tensor, base_context, :climate)

      # Add small random perturbations under different random seeds and verify recommendation holds
      results =
        Enum.map(1..5, fn seed ->
          :rand.seed(:exs1024, {seed, seed, seed})
          noise_v = (:rand.uniform() - 0.5) * 0.05
          noise_c = (:rand.uniform() - 0.5) * 0.05
          noise_a = (:rand.uniform() - 0.5) * 0.05

          perturbed_context = %{
            volatility: base_context.volatility + noise_v,
            complexity: base_context.complexity + noise_c,
            adversariality: base_context.adversariality + noise_a
          }

          rec = MetaTheoryPredictor.recommend(tensor, perturbed_context, :climate)
          rec.recommended_theory
        end)

      # The recommendation should remain robustly invariant to small coordinate noise
      assert Enum.all?(results, &(&1 == base_rec.recommended_theory))
    end

    test "Q7 (Meta-Theory Advantage - MT5) — Adaptive dynamic recommendation outcompetes a static policy" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      # Compile mapped baseline theory structs for fitness evaluations
      theory_map = Map.new(theories, & {&1.theory_id, &1})

      # Define a sequence of alternating environment regimes
      regimes = [
        # Volatile
        %{volatility: 0.8, complexity: 0.1, domain: :climate},
        # Complex
        %{volatility: 0.1, complexity: 0.8, domain: :technology},
        # Volatile
        %{volatility: 0.85, complexity: 0.15, domain: :climate},
        # Complex
        %{volatility: 0.05, complexity: 0.90, domain: :technology}
      ]

      # 1. Evaluate Dynamic Recommender Policy
      dynamic_fitness_scores =
        Enum.map(regimes, fn context ->
          rec = MetaTheoryPredictor.recommend(tensor, context, context.domain)
          theory_struct = Map.get(theory_map, rec.recommended_theory)
          TheorySelection.calculate_fitness(theory_struct, context.volatility, context.complexity)
        end)

      # 2. Evaluate Static Policy (Always select theory_alpha)
      static_fitness_scores =
        Enum.map(regimes, fn context ->
          theory_struct = Map.get(theory_map, "theory_alpha")
          TheorySelection.calculate_fitness(theory_struct, context.volatility, context.complexity)
        end)

      avg_dynamic = Enum.sum(dynamic_fitness_scores) / length(regimes)
      avg_static = Enum.sum(static_fitness_scores) / length(regimes)

      IO.inspect(
        %{dynamic: avg_dynamic, static: avg_static},
        label: "Policy Performance Comparison"
      )

      # The adaptive dynamic policy yields a higher average fitness across diverse regimes
      assert avg_dynamic > avg_static
    end

    test "Q8 (Adversarial Generalization - MT6) — Hostile environment success accelerates trust formation" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      # Success under low adversariality (0.0)
      context_low = %{volatility: 0.5, complexity: 0.5, adversariality: 0.0, domain: :climate}
      tensor_low = MetaTheoryLearner.learn(tensor, "theory_alpha", context_low, true, 0.0)
      trust_low = Map.get(tensor_low.theory_trust_weights, "theory_alpha")

      # Success under high adversariality (0.9)
      context_high = %{volatility: 0.5, complexity: 0.5, adversariality: 0.9, domain: :climate}
      tensor_high = MetaTheoryLearner.learn(tensor, "theory_alpha", context_high, true, 0.0)
      trust_high = Map.get(tensor_high.theory_trust_weights, "theory_alpha")

      # High adversarial success must yield a larger trust gain
      assert trust_high > trust_low
    end

    test "Q9 (Theory Portfolio Law - MT7) — Adaptive context portfolio outcompetes static combinations" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)
      theory_map = Map.new(theories, & {&1.theory_id, &1})

      # Sequence of changing environments
      regimes = [
        %{volatility: 0.8, complexity: 0.1, domain: :climate},
        %{volatility: 0.1, complexity: 0.8, domain: :technology},
        %{volatility: 0.7, complexity: 0.2, domain: :climate},
        %{volatility: 0.2, complexity: 0.7, domain: :technology}
      ]

      # 1. Dynamic Portfolio Fitness
      dynamic_portfolio_fitness =
        Enum.map(regimes, fn context ->
          weights = MetaTheoryPredictor.get_adaptive_portfolio_weights(tensor, context, context.domain)
          Enum.reduce(weights, 0.0, fn {tid, w}, acc ->
            t_struct = Map.get(theory_map, tid)
            fit = TheorySelection.calculate_fitness(t_struct, context.volatility, context.complexity)
            acc + w * fit
          end)
        end)

      # 2. Static Uniform Portfolio Fitness (0.25 weight each for 4 theories)
      static_uniform_fitness =
        Enum.map(regimes, fn context ->
          theory_ids = ["theory_alpha", "theory_beta", "theory_gamma", "theory_delta"]
          Enum.reduce(theory_ids, 0.0, fn tid, acc ->
            t_struct = Map.get(theory_map, tid)
            fit = TheorySelection.calculate_fitness(t_struct, context.volatility, context.complexity)
            acc + 0.25 * fit
          end)
        end)

      # 3. Single Permanent Theory Fitness (Theory Alpha)
      single_theory_fitness =
        Enum.map(regimes, fn context ->
          t_struct = Map.get(theory_map, "theory_alpha")
          TheorySelection.calculate_fitness(t_struct, context.volatility, context.complexity)
        end)

      avg_dynamic_port = Enum.sum(dynamic_portfolio_fitness) / length(regimes)
      avg_static_port = Enum.sum(static_uniform_fitness) / length(regimes)
      avg_single = Enum.sum(single_theory_fitness) / length(regimes)

      IO.inspect(
        %{dynamic_portfolio: avg_dynamic_port, static_uniform_portfolio: avg_static_port, single_theory: avg_single},
        label: "Portfolio Strategy Comparison"
      )

      # The dynamic adaptive portfolio outcompetes both static uniform and the single permanent theory
      assert avg_dynamic_port > avg_static_port
      assert avg_dynamic_port > avg_single
    end
  end
end
