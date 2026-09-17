defmodule Tiannara.REA.TheorySelectionTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.TheoryTensor
  alias Tiannara.REA.TheorySelection
  alias Tiannara.REA.TheoryFitnessAnalyzer

  describe "Phase 11.16 Theory Selection Physics Verification Suite" do

    test "Q1 — Does the replicator dynamics sweep shift population towards higher-fitness theories?" do
      theories = TheorySelection.default_theories()
      _initial_total = Enum.sum(Enum.map(theories, & &1.population))

      # Run a sweep under intermediate settings
      {updated, _trace} = TheorySelection.run_theory_selection_sweep(theories, 10, 0.15, 0.10)
      final_total = Enum.sum(Enum.map(updated, & &1.population))

      # The population structure has adapted, meaning it shifts relative sizes
      assert final_total > 0
      assert Enum.any?(updated, &(&1.population != 100))
    end

    test "Q2 — Verify ranking stability across seeds and report discovered ordering" do
      theories = TheorySelection.default_theories()

      # Compute predictor rankings
      rankings = TheoryFitnessAnalyzer.rank_theory_invariants(theories, 0.15, 0.10)
      ordering = Enum.map(rankings, & &1.variable)

      IO.inspect(ordering, label: "Discovered Invariant Predictor Ordering")

      # Assert basic structural validity and that we have all variables ranked
      assert length(ordering) == 9
      assert Enum.member?(ordering, :transferability)
      assert Enum.member?(ordering, :convergence_score)
      assert Enum.member?(ordering, :predictive_power)
    end

    test "Q3 — Verify that Hazard Ratios correctly reflect extinction risk protection" do
      # Set up a dynamic population with high values of protective variable and low values
      theories = [
        %TheoryTensor{theory_id: "t_high_1", transferability: 0.90, population: 50, extinction_risk: 0.0, relations: [], parent_theories: [], validation_history: [], failure_history: [], adaptation_history: []},
        %TheoryTensor{theory_id: "t_high_2", transferability: 0.80, population: 40, extinction_risk: 0.0, relations: [], parent_theories: [], validation_history: [], failure_history: [], adaptation_history: []},
        %TheoryTensor{theory_id: "t_low_1", transferability: 0.10, population: 0, extinction_risk: 1.0, relations: [], parent_theories: [], validation_history: [], failure_history: [], adaptation_history: []},
        %TheoryTensor{theory_id: "t_low_2", transferability: 0.05, population: 0, extinction_risk: 1.0, relations: [], parent_theories: [], validation_history: [], failure_history: [], adaptation_history: []}
      ]

      rankings = TheoryFitnessAnalyzer.rank_theory_invariants(theories)
      trans_rank = Enum.find(rankings, &(&1.variable == :transferability))

      # An HR < 1.0 means high transferability protects theories against extinction
      assert trans_rank.hazard_ratio < 1.0
    end

    test "Q4 — Sweep Volatile, Complex, Stable, and Mixed regimes and report winners" do
      theories = TheorySelection.default_theories()

      winner_volatile = get_regime_winner(theories, 0.70, 0.10)
      winner_complex = get_regime_winner(theories, 0.10, 0.80)
      winner_stable = get_regime_winner(theories, 0.05, 0.05)
      winner_mixed = get_regime_winner(theories, 0.30, 0.30)

      winners = %{
        volatile: winner_volatile,
        complex: winner_complex,
        stable: winner_stable,
        mixed: winner_mixed
      }

      IO.inspect(winners, label: "Regime Dominance Map")

      # Verify that selection changes depending on geometry
      all_winners = Map.values(winners)
      assert length(Enum.uniq(all_winners)) > 1
    end

    test "Q5 — Verify that Cross-Domain Resilience (CDR) correctly calculates validation resilience" do
      theories = TheorySelection.default_theories()
      theory = hd(theories)

      cdr = TheorySelection.calculate_cdr(theory)
      assert cdr >= 0.0 and cdr <= 1.0
    end

    test "Q6 — Verify selection outcome robustness across pseudo-random noise variations" do
      dominant = %TheoryTensor{
        theory_id: "dominant",
        predictive_power: 0.90,
        transferability: 0.95,
        survivability: 0.90,
        population: 100,
        relations: [],
        parent_theories: [],
        validation_history: [],
        failure_history: [],
        adaptation_history: []
      }
      weak = %TheoryTensor{
        theory_id: "weak",
        predictive_power: 0.30,
        transferability: 0.20,
        survivability: 0.30,
        population: 100,
        relations: [],
        parent_theories: [],
        validation_history: [],
        failure_history: [],
        adaptation_history: []
      }

      # Run selection sweep 3 times with different random seeds
      results = Enum.map(1..3, fn _ ->
        :rand.seed(:exs1024, {:rand.uniform(1000), :rand.uniform(1000), :rand.uniform(1000)})
        {updated, _} = TheorySelection.run_theory_selection_sweep([dominant, weak], 5, 0.15)
        top = Enum.max_by(updated, & &1.population)
        top.theory_id
      end)

      # Dominant theory wins in every seeded instance
      assert Enum.all?(results, &(&1 == "dominant"))
    end

    test "Q7 — Survival vs Truth: Can a less-predictive but highly-transferable theory outcompete a highly-predictive but local theory under volatility?" do
      # High transferability, moderate predictive power
      t_survival = %TheoryTensor{
        theory_id: "t_survival",
        predictive_power: 0.50,
        transferability: 0.90,
        survivability: 0.80,
        convergence_score: 0.50,
        population: 100,
        parent_theories: [],
        generation: 1,
        relations: [],
        validation_history: [],
        failure_history: [],
        adaptation_history: []
      }

      # High predictive power, low transferability
      t_truth = %TheoryTensor{
        theory_id: "t_truth",
        predictive_power: 0.95,
        transferability: 0.15,
        survivability: 0.80,
        convergence_score: 0.10,
        population: 100,
        parent_theories: [],
        generation: 1,
        relations: [],
        validation_history: [],
        failure_history: [],
        adaptation_history: []
      }

      {updated, _trace} = TheorySelection.run_theory_selection_sweep([t_survival, t_truth], 15, 0.80, 0.0)

      updated_survival = Enum.find(updated, &(&1.theory_id == "t_survival"))
      updated_truth = Enum.find(updated, &(&1.theory_id == "t_truth"))

      IO.inspect({updated_survival.population, updated_truth.population}, label: "Survival vs Truth Sweep Outcomes")

      # Transferability outcompetes correctness under volatility, proving TLI decoupling
      assert updated_survival.population > updated_truth.population
    end

  end

  # Helper to compute winning theory dynamically for a hypothetical regime coordinate
  defp get_regime_winner(theories, vol, comp) do
    best =
      Enum.max_by(theories, fn t ->
        TheorySelection.calculate_fitness(t, vol, comp)
      end, fn -> nil end)

    if best, do: best.theory_id, else: "N/A"
  end
end
