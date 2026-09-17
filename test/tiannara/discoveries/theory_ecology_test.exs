defmodule Tiannara.REA.TheoryEcologyTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.TheoryRelation
  alias Tiannara.REA.TheoryTensor
  alias Tiannara.REA.TheoryEcology
  alias Tiannara.REA.TheoryMutator
  alias Tiannara.REA.DomainCrucible

  describe "Phase 11.15 Theory Ecology Verification Suite" do

    test "Q1 — Do universal theories (high transferability) dominate domain-specific ones in selection sweeps?" do
      universal = %TheoryTensor{
        theory_id: "theory_universal",
        relations: [%TheoryRelation{lhs: :functor_retention, operator: :dominates, rhs: :mpp, context: :high_volatility, confidence: 0.9}],
        predictive_power: 0.85,
        transferability: 0.95,
        survivability: 0.90,
        population: 100,
        parent_theories: [],
        generation: 1,
        supporting_discoveries: [],
        validation_history: [],
        failure_history: [],
        adaptation_history: []
      }

      specialized = %TheoryTensor{
        theory_id: "theory_specialized",
        relations: [%TheoryRelation{lhs: :mpp, operator: :equals, rhs: :correctness, context: :low_volatility, confidence: 0.4}],
        predictive_power: 0.40,
        transferability: 0.20,
        survivability: 0.30,
        population: 100,
        parent_theories: [],
        generation: 1,
        supporting_discoveries: [],
        validation_history: [],
        failure_history: [],
        adaptation_history: []
      }

      # Run selection sweep over 10 generations
      {updated_theories, _trace} = TheoryEcology.run_theory_selection([universal, specialized], 10)

      updated_universal = Enum.find(updated_theories, &(&1.theory_id == "theory_universal"))
      updated_specialized = Enum.find(updated_theories, &(&1.theory_id == "theory_specialized"))

      assert updated_universal.population > updated_specialized.population
      assert updated_specialized.population < 100
    end

    test "Q2 — Does recombining parent relations generate child theory tensors with higher fitness / generativity?" do
      parent_a = %TheoryTensor{
        theory_id: "parent_a",
        relations: [%TheoryRelation{lhs: :functor_retention, operator: :dominates, rhs: :mpp, context: :high_volatility, confidence: 0.8}],
        generation: 2,
        generativity: 0.60,
        predictive_power: 0.70,
        transferability: 0.80,
        survivability: 0.75,
        compression_ratio: 3.0,
        supporting_discoveries: [:orbit_selection_physics],
        validation_history: [],
        failure_history: [],
        adaptation_history: []
      }

      parent_b = %TheoryTensor{
        theory_id: "parent_b",
        relations: [%TheoryRelation{lhs: :history, operator: :exceeds, rhs: :state_alone, context: :all, confidence: 0.85}],
        generation: 3,
        generativity: 0.70,
        predictive_power: 0.80,
        transferability: 0.70,
        survivability: 0.85,
        compression_ratio: 4.0,
        supporting_discoveries: [:orbit_genesis],
        validation_history: [],
        failure_history: [],
        adaptation_history: []
      }

      child = TheoryMutator.recombine(parent_a, parent_b)

      # Assert generation incremented and lineage parents recorded
      assert child.generation == 4
      assert child.generativity > parent_a.generativity
      assert child.generativity > parent_b.generativity
      assert Enum.member?(child.parent_theories, "parent_a")
      assert Enum.member?(child.parent_theories, "parent_b")
      
      # Inherited logic relations from both sides
      assert length(child.relations) >= 1
    end

    test "Q3 — Do specialized single-domain theories get refuted when tested in mismatching context volatility domains?" do
      domains = DomainCrucible.all_domains()

      # Select domains based on their deterministic volatility parameters
      low_vol_domain = Enum.find(domains, fn d ->
        seed = :erlang.phash2(d)
        volatility = rem(seed, 100) / 100.0
        volatility < 0.30
      end)

      high_vol_domain = Enum.find(domains, fn d ->
        seed = :erlang.phash2(d)
        volatility = rem(seed, 100) / 100.0
        volatility >= 0.35
      end)

      # 1. Specialized high volatility theory tested in low volatility domain -> refuted!
      theory_high_vol = %TheoryTensor{
        theory_id: "theory_high_vol",
        relations: [%TheoryRelation{lhs: :functor_retention, operator: :dominates, rhs: :mpp, context: :high_volatility, confidence: 0.9}],
        validation_history: [],
        failure_history: [],
        survivability: 0.8
      }

      refuted_high_vol = DomainCrucible.validate_theory(theory_high_vol, low_vol_domain)
      assert length(refuted_high_vol.failure_history) > 0
      assert refuted_high_vol.survivability < theory_high_vol.survivability
      assert Enum.any?(refuted_high_vol.failure_history, &String.contains?(&1.reason, "fails in low-volatility"))

      # 2. Specialized low volatility theory tested in high volatility domain -> refuted!
      theory_low_vol = %TheoryTensor{
        theory_id: "theory_low_vol",
        relations: [%TheoryRelation{lhs: :mpp, operator: :dominates, rhs: :correctness, context: :low_volatility, confidence: 0.9}],
        validation_history: [],
        failure_history: [],
        survivability: 0.8
      }

      refuted_low_vol = DomainCrucible.validate_theory(theory_low_vol, high_vol_domain)
      assert length(refuted_low_vol.failure_history) > 0
      assert refuted_low_vol.survivability < theory_low_vol.survivability
      assert Enum.any?(refuted_low_vol.failure_history, &String.contains?(&1.reason, "fails under high environmental volatility"))
    end

    test "Q4 — Evolving parallel domain runs yields convergence score mappings" do
      domains = DomainCrucible.all_domains()

      # Run evolution over all 20 domains for 2 generations
      domain_theory_maps = Map.new(domains, fn d ->
        {d, DomainCrucible.evolve_theories_in_domain(d, 2)}
      end)

      converged = DomainCrucible.measure_convergence(domain_theory_maps)

      # Assert that we get converged theories back
      assert length(converged) > 0
      
      # At least one theory exhibits cross-domain convergence
      assert Enum.any?(converged, &(&1.convergence_score > 0.10))
    end

    test "Q5 — Variable rankings correlate survival to transferability and convergence rather than predictive power alone" do
      theories = [
        %TheoryTensor{
          theory_id: "t1",
          population: 1000,
          transferability: 0.95,
          convergence_score: 0.90,
          predictive_power: 0.10,
          compression_ratio: 1.0,
          generativity: 0.5
        },
        %TheoryTensor{
          theory_id: "t2",
          population: 750,
          transferability: 0.80,
          convergence_score: 0.75,
          predictive_power: 0.30,
          compression_ratio: 1.0,
          generativity: 0.5
        },
        %TheoryTensor{
          theory_id: "t3",
          population: 500,
          transferability: 0.60,
          convergence_score: 0.60,
          predictive_power: 0.60,
          compression_ratio: 1.0,
          generativity: 0.5
        },
        %TheoryTensor{
          theory_id: "t4",
          population: 100,
          transferability: 0.20,
          convergence_score: 0.10,
          predictive_power: 0.90,
          compression_ratio: 1.0,
          generativity: 0.5
        }
      ]

      rankings = TheoryEcology.rank_theory_predictors(theories)

      transferability_rank = Enum.find_index(rankings, &(&1.variable == :transferability))
      convergence_rank = Enum.find_index(rankings, &(&1.variable == :convergence_score))
      predictive_power_rank = Enum.find_index(rankings, &(&1.variable == :predictive_power))

      # Transferability and convergence score must be ranked above predictive power
      assert transferability_rank < predictive_power_rank
      assert convergence_rank < predictive_power_rank

      # Confirm actual Pearson correlation values
      trans_corr = Enum.find(rankings, &(&1.variable == :transferability)).correlation
      pred_corr = Enum.find(rankings, &(&1.variable == :predictive_power)).correlation

      assert trans_corr > 0.90
      assert pred_corr < 0.0
    end

    test "Q6 — Convergence and selection outcomes generalize across seed variations" do
      dominant = %TheoryTensor{
        theory_id: "dominant",
        predictive_power: 0.90,
        transferability: 0.95,
        survivability: 0.90,
        population: 100
      }
      weak = %TheoryTensor{
        theory_id: "weak",
        predictive_power: 0.30,
        transferability: 0.20,
        survivability: 0.30,
        population: 100
      }

      # Run selection sweep 5 times with random seeds / noise
      results = Enum.map(1..5, fn _ ->
        :rand.seed(:exs1024, {:rand.uniform(1000), :rand.uniform(1000), :rand.uniform(1000)})
        {updated, _} = TheoryEcology.run_theory_selection([dominant, weak], 5, 0.15)
        top = Enum.max_by(updated, & &1.population)
        top.theory_id
      end)

      # The dominant theory should consistently survive/win across all noise instances
      assert Enum.all?(results, &(&1 == "dominant"))
    end

  end
end
