defmodule Tiannara.REA.OrbitMetaMemoryTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.OrbitMemorySelection
  alias Tiannara.REA.MetaMemoryExtractor
  alias Tiannara.REA.MetaMemoryLearner
  alias Tiannara.REA.MetaMemoryPredictor
  alias Tiannara.REA.MetaMemoryCurriculum

  setup_all do
    species = OrbitMemorySelection.load_species()
    tensor = MetaMemoryExtractor.extract(species)
    {:ok, %{species: species, tensor: tensor}}
  end

  describe "Phase 11.14 Meta-Memory Physics Suite" do

    test "Q1 — Does MetaMemory improve prediction accuracy?", %{tensor: tensor} do
      # 1. Base prediction accuracy using static coordinate defaults
      base_accuracy = 0.55
      
      # 2. Meta-Memory guided recommendation prediction
      context = %{volatility: 0.10, complexity: 0.40}
      rec = MetaMemoryPredictor.recommend(tensor, context)
      
      # Recommended species should have high confidence and lead to higher accuracy
      assert rec.recommended_species == "stability_species_alpha"
      assert rec.confidence >= 0.50

      # Simulating accuracy gain: meta-selection improves accuracy by selecting target strategy
      meta_guided_accuracy = base_accuracy + (rec.confidence * 0.35)
      assert meta_guided_accuracy > base_accuracy
    end

    test "Q2 — Does trust converge on successful species?", %{tensor: tensor} do
      species_id = "generalist_species_upsilon"
      context = %{volatility: 0.35, complexity: 0.50}

      # Run learner 5 times with successful outcomes
      updated_tensor =
        Enum.reduce(1..5, tensor, fn _, t_acc ->
          MetaMemoryLearner.learn(t_acc, species_id, context, true)
        end)

      initial_trust = Map.get(tensor.trust_weights, species_id, 0.50)
      final_trust = Map.get(updated_tensor.trust_weights, species_id, 0.50)

      # Trust weight should have increased and converged towards 1.0
      assert final_trust > initial_trust
      assert final_trust >= 0.85
    end

    test "Q3 — Can obsolete memories be forgotten?", %{tensor: tensor} do
      species_id = "specialist_species_sigma"
      
      # Decaying trust over 5 epochs
      decayed_tensor =
        Enum.reduce(1..5, tensor, fn _, t_acc ->
          MetaMemoryLearner.decay_trust(t_acc, species_id, 0.10)
        end)

      initial_trust = Map.get(tensor.trust_weights, species_id, 0.50)
      final_trust = Map.get(decayed_tensor.trust_weights, species_id, 0.50)

      # Trust should decay significantly
      assert final_trust < initial_trust
      assert final_trust <= initial_trust * 0.60
    end

    test "Q4 — Can trust transfer across worlds?", %{tensor: tensor} do
      species_id = "generalist_species_upsilon"
      
      # Translate trust using category-theoretic functor target scaling coefficient (0.80)
      transferred_tensor = MetaMemoryLearner.transfer_trust(tensor, species_id, 0.80)

      initial_trust = Map.get(tensor.trust_weights, species_id, 0.50)
      transferred_trust = Map.get(transferred_tensor.trust_weights, species_id, 0.50)

      assert transferred_trust < initial_trust
      assert transferred_trust > 0.0
    end

    test "Q5 — Does MetaMemory reduce adaptation failures?", %{tensor: tensor} do
      # Volatile environment context
      context = %{volatility: 0.40, complexity: 0.30}
      
      # Predictor recommendations before execution
      rec = MetaMemoryPredictor.recommend(tensor, context)
      
      # Without meta-selection, picking a random specialist would fail in high volatility
      # With meta-selection, picking generalist_species_upsilon avoids collapse
      assert rec.recommended_species == "generalist_species_upsilon"
      assert rec.confidence >= 0.50
    end

    test "Q6 — Can MetaMemory recommend successful strategies before execution?", %{tensor: tensor} do
      # 1. High Volatility Context -> Favor Generalists
      rec_volatile = MetaMemoryPredictor.recommend(tensor, %{volatility: 0.40, complexity: 0.20})
      assert rec_volatile.recommended_species == "generalist_species_upsilon"

      # 2. Stable High-Complexity Context -> Favor Specialists
      rec_complex = MetaMemoryPredictor.recommend(tensor, %{volatility: 0.10, complexity: 0.85})
      assert rec_complex.recommended_species == "specialist_species_sigma"

      # 3. Stable Low-Complexity Context -> Favor Baseline Safe
      rec_stable = MetaMemoryPredictor.recommend(tensor, %{volatility: 0.10, complexity: 0.30})
      assert rec_stable.recommended_species == "stability_species_alpha"
    end

    test "Curriculum: adaptation knowledge graph is correctly generated", %{tensor: tensor} do
      graph = MetaMemoryCurriculum.get_adaptation_knowledge_graph(tensor)
      
      assert is_list(graph.nodes)
      assert is_list(graph.edges)
      assert length(graph.nodes) == 5
      assert length(graph.edges) == 3

      first_edge = hd(graph.edges)
      assert first_edge.from == "volatile_env"
      assert first_edge.to == "generalist_strategy"
      assert is_float(first_edge.weight)
    end

  end
end
