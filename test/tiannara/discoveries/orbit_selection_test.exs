defmodule Tiannara.REA.OrbitSelectionTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.OrbitMemorySelection
  alias Tiannara.REA.OrbitMemoryFitnessAnalyzer
  alias Tiannara.REA.OrbitMemoryRadiation
  alias Tiannara.REA.OrbitMemoryNiches

  setup_all do
    species = OrbitMemorySelection.load_species()
    {:ok, %{species: species}}
  end

  describe "Phase 11.13 Orbit Memory Selection Physics Suite" do

    test "Q1 — Do fitter species dominate?", %{species: species} do
      # Run selection sweep for 15 generations
      {final_pop, _trace} = OrbitMemorySelection.run_selection_sweep(species, 15, 0.0)

      # Find a high-fitness species (e.g., generalist_species_upsilon: fitness 0.85)
      # and a low-fitness species (e.g., collapse_species_omega: fitness 0.18)
      high_fit_s = Enum.find(final_pop, &(&1.species_id == "generalist_species_upsilon"))
      low_fit_s = Enum.find(final_pop, &(&1.species_id == "collapse_species_omega"))

      assert high_fit_s.population > 0
      assert low_fit_s.population == 0 or high_fit_s.population > low_fit_s.population
      
      # Assert the overall population is dominated by high-fitness lineages
      total_pop = Enum.sum(Enum.map(final_pop, & &1.population))
      assert high_fit_s.population / total_pop >= 0.25
    end

    test "Q2 — Which variable best predicts survival?", %{species: species} do
      rankings = OrbitMemoryFitnessAnalyzer.rank_fitness_invariants(species)
      
      # Assert rankings exist and are sorted by correlation in descending order
      assert length(rankings) == 6
      correlations = Enum.map(rankings, & &1.correlation)
      assert correlations == Enum.sort(correlations, :desc)

      # The top variable should be a positive predictor of survival
      top_predictor = hd(rankings)
      assert top_predictor.correlation > 0.0
      assert top_predictor.variable in [:mpp, :functor_retention, :inheritance_stability]
    end

    test "Q3 — Can low-MPP species survive through transferability?" do
      # Create a custom population to isolate the transferability effect
      # Species A: low MPP, high functor retention (transferability)
      # Species B: low MPP, low functor retention
      custom_pop = [
        %{species_id: "low_mpp_high_trans", parent_species: "root", population: 100, fitness: 0.60, mpp: 0.30, mes: 0.50, functor_retention: 0.90, compression_ratio: 2.0, inheritance_stability: 0.80, domain_coverage: 4, mutation_recovery: 0.60, extinction_risk: 0.10},
        %{species_id: "low_mpp_low_trans", parent_species: "root", population: 100, fitness: 0.30, mpp: 0.30, mes: 0.50, functor_retention: 0.20, compression_ratio: 2.0, inheritance_stability: 0.80, domain_coverage: 1, mutation_recovery: 0.60, extinction_risk: 0.60}
      ]

      # Under environmental volatility (which makes transferability crucial), run sweep
      {final_pop, _trace} = OrbitMemorySelection.run_selection_sweep(custom_pop, 10, 0.20)

      surviving_a = Enum.find(final_pop, &(&1.species_id == "low_mpp_high_trans"))
      surviving_b = Enum.find(final_pop, &(&1.species_id == "low_mpp_low_trans"))

      assert surviving_a.population > surviving_b.population
      assert surviving_b.population == 0 or surviving_a.population > 0
    end

    test "Q4 — Are generalists or specialists favored?", %{species: species} do
      # 1. Under zero volatility (constant single-domain basin), specialists (high compression ratio) thrive
      # We check the default niches
      niches = OrbitMemoryNiches.classify_niches(species)
      assert length(niches.generalists) > 0
      assert length(niches.specialists) > 0

      # 2. Simulate sweep under high volatility (favors generalists)
      # Generalist species has high domain coverage (6) and functor retention (0.88)
      # Specialist species has low domain coverage (2)
      {final_pop_volatile, _trace} = OrbitMemorySelection.run_selection_sweep(species, 15, 0.30)
      
      gen_s = Enum.find(final_pop_volatile, &(&1.species_id == "generalist_species_upsilon"))
      spec_s = Enum.find(final_pop_volatile, &(&1.species_id == "specialist_species_sigma"))

      # Check population survival ratio: generalist should decline less or grow more than specialist
      gen_ratio = gen_s.population / 150.0
      spec_ratio = spec_s.population / 90.0
      assert gen_ratio > spec_ratio
    end

    test "Q5 — Can adaptive radiation be reproduced?", %{species: species} do
      # Detect radiation in the population
      rad_report = OrbitMemoryRadiation.detect_adaptive_radiation(species)
      
      assert rad_report.radiation_events_count > 0
      first_radiation = hd(rad_report.radiations)
      assert first_radiation.parent_species == "stability_species_root"
      assert length(first_radiation.children) >= 2
      assert first_radiation.divergence_score > 0.0
    end

    test "Q6 — Do discovered selection laws generalize across random seeds?", %{species: species} do
      # Run selection sweep under 5 different random noise environments
      # and verify that the relative rank of functor_retention and mpp remains high.
      results =
        Enum.map(1..5, fn seed ->
          # Simulate sweep with a pseudo-random seed (simulated by volatility & step offsets)
          {final_pop, _trace} = OrbitMemorySelection.run_selection_sweep(species, 10, 0.15 + seed * 0.02)
          rankings = OrbitMemoryFitnessAnalyzer.rank_fitness_invariants(final_pop)
          
          # Find ranking position of functor_retention and mpp (0-indexed)
          idx_trans = Enum.find_index(rankings, &(&1.variable == :functor_retention))
          idx_mpp = Enum.find_index(rankings, &(&1.variable == :mpp))
          {idx_trans, idx_mpp}
        end)

      Enum.each(results, fn {idx_trans, idx_mpp} ->
        # Both must rank in the top 3 (indices 0, 1, or 2)
        assert idx_trans <= 2
        assert idx_mpp <= 2
      end)
    end

  end
end
