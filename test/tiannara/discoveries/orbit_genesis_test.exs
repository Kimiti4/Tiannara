defmodule Tiannara.REA.OrbitGenesisTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.OrbitGenesis
  alias Tiannara.REA.OrbitGenesis.Causal
  alias Tiannara.REA.OrbitGenesis.Predictor

  setup_all do
    # Perform a fast sweep to make sure database is ready
    {:ok, records} = OrbitGenesis.run_full_sweeps(10)
    {:ok, %{records: records}}
  end

  describe "Phase 11.10 Orbit Genesis & Attractor Design Suite" do

    test "Q1 — Constitutional Genesis: GSI/Robustness configurations map to expected prediction bounds" do
      config_stable = [gsi: 0.85, robustness: 0.80, generativity: 0.10, identity_persistence: 0.90, return_time: 2]
      pred = Predictor.predict(config_stable)
      assert pred.orbit_prediction == :stability_orbit
      assert pred.confidence > 0.80
    end

    test "Q2 & Q3 — Topological/Identity Genesis: Low identity persistence defaults to decay state" do
      config_decay = [gsi: 0.50, robustness: 0.40, generativity: 0.10, identity_persistence: 0.15, return_time: 5]
      pred = Predictor.predict(config_decay)
      assert pred.orbit_prediction == :other_orbit_1
    end

    test "Q4 — Optionality Genesis: Generative states lead to collapse-recovery prediction" do
      config_col_rec = [gsi: 0.70, robustness: 0.60, generativity: 0.50, identity_persistence: 0.80, return_time: 4]
      pred = Predictor.predict(config_col_rec)
      assert pred.orbit_prediction == :collapse_recovery_orbit
    end

    test "Q5 — History vs State Separation: Same coordinates, different history, different orbits" do
      separation = Causal.run_separation_experiment()
      
      # Assert endpoints are mathematically identical
      assert separation.world_a["terminal_coordinates"] == separation.world_b["terminal_coordinates"]
      
      # Assert emergent orbits differ because history shapes the attractor basin
      assert separation.world_a["orbit_outcome"] != separation.world_b["orbit_outcome"]
      assert separation.conclusion == :history_dominance
    end

    test "Q6 — Orbit Twins Memory: divergent transition histories generate divergent future retention probability" do
      twins = Causal.run_orbit_twins_experiment()

      assert twins.twin_a.future_retention_probability != twins.twin_b.future_retention_probability
      assert twins.結論 == :memory_exists
    end

    test "Q7 — Pre-simulation prediction sweep verification" do
      # Test predictor classifier across multiple randomized configurations
      configs = for _ <- 1..20, do: OrbitGenesis.generate_random_config()
      
      success_count =
        Enum.count(configs, fn config ->
          pred = Predictor.predict(config)
          # Ensure a prediction and confidence are generated
          assert pred.orbit_prediction in [:stability_orbit, :collapse_recovery_orbit, :other_orbit_0, :other_orbit_1]
          assert pred.confidence > 0.75
          true
        end)

      # 100% of prediction formatting validated
      assert success_count == 20
    end
  end
end
