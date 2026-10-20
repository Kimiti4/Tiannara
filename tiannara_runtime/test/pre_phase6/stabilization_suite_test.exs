defmodule Tiannara.PrePhase6.StabilizationSuiteTest do
  use ExUnit.Case, async: true

  alias Tiannara.PrePhase6.{
    CausalIntegrity,
    SemanticCoherence,
    ObserverSafety,
    EquilibriumMonitor
  }

  describe "CausalIntegrity" do
    test "passes a clean, consistent causal branch graph" do
      clean_registry = %{
        "branch_1" => %{
          events: [
            %{type: :write, state: :ok},
            %{type: :read, state: :ok}
          ],
          state: :active,
          persistence_prob: 0.9,
          observer_density: 0.2,
          reconciliation_cost: 50.0
        },
        "branch_2" => %{
          events: [
            %{type: :write, state: :ok}
          ],
          state: :active,
          persistence_prob: 0.8,
          observer_density: 0.1,
          reconciliation_cost: 20.0
        }
      }

      assert {:ok, result} = CausalIntegrity.validate_causal_graph(clean_registry)
      assert result.status == :coherent
      assert result.branches_validated == 2
    end

    test "rejects branch registries containing opposing state causal contradictions" do
      contradictory_registry = %{
        "branch_fail" => %{
          events: [
            %{type: :timeline_split, state: :active},
            %{type: :timeline_split, state: :inactive} # Contradiction! Same type, different state.
          ],
          state: :active,
          persistence_prob: 0.9,
          observer_density: 0.2,
          reconciliation_cost: 50.0
        }
      }

      assert {:error, reason} = CausalIntegrity.validate_causal_graph(contradictory_registry)
      assert reason =~ "Causal contradictions detected"
    end

    test "rejects invalid branch collapses with high persistence probability or observer density" do
      invalid_prune_registry = %{
        "branch_1" => %{
          events: [%{type: :write, state: :ok}],
          state: :collapsed,
          persistence_prob: 0.6, # > 0.35, collapse is unsafe!
          observer_density: 0.1,
          reconciliation_cost: 10.0
        }
      }

      assert {:error, reason} = CausalIntegrity.validate_causal_graph(invalid_prune_registry)
      assert reason =~ "Invalid pruning"
    end
  end

  describe "SemanticCoherence" do
    test "passes node ontology meshes within acceptable drift bounds" do
      coherent_mesh = %{
        "node_a" => %{vector: [0.1, 0.2, 0.9], semantic_dispersion: 0.4},
        "node_b" => %{vector: [0.12, 0.18, 0.88], semantic_dispersion: 0.35}
      }

      assert {:ok, result} = SemanticCoherence.validate_ontology_mesh(coherent_mesh)
      assert result.status == :coherent
      assert result.drift_summary.mean_drift < 0.4
    end

    test "rejects node meshes with critical cosine drift" do
      drifted_mesh = %{
        "node_a" => %{vector: [1.0, 0.0, 0.0], semantic_dispersion: 0.4},
        "node_b" => %{vector: [-1.0, 0.0, 0.0], semantic_dispersion: 0.35} # Opposite vectors = max cosine drift (2.0)
      }

      assert {:error, reason} = SemanticCoherence.validate_ontology_mesh(drifted_mesh)
      assert reason =~ "Critical semantic drift detected"
    end

    test "rejects collapsed semantic diversity" do
      collapsed_mesh = %{
        "node_a" => %{vector: [0.1, 0.2, 0.9], semantic_dispersion: 0.05}, # avg diversity < 0.2
        "node_b" => %{vector: [0.11, 0.21, 0.89], semantic_dispersion: 0.08}
      }

      assert {:error, reason} = SemanticCoherence.validate_ontology_mesh(collapsed_mesh)
      assert reason =~ "Semantic diversity collapsed"
    end
  end

  describe "ObserverSafety" do
    test "passes sandboxes with safe recursion limits and absolute substrate opacity" do
      safe_observers = %{
        "obs_1" => %{
          recursion_depth: 2,
          accessed_primitives: [:some_query],
          uncertainty_injection: 0.0
        }
      }

      assert {:ok, result} = ObserverSafety.validate_observer_boundaries(safe_observers)
      assert result.status == :safe
    end

    test "rejects observers exceeding the recursion depth limit" do
      deep_observers = %{
        "obs_deep" => %{
          recursion_depth: 5, # limit is 4
          accessed_primitives: [],
          uncertainty_injection: 0.1
        }
      }

      assert {:error, reason} = ObserverSafety.validate_observer_boundaries(deep_observers)
      assert reason =~ "Recursion limit exceeded"
    end

    test "rejects observers breaching substrate opacity barriers" do
      breaching_observers = %{
        "obs_hacker" => %{
          recursion_depth: 1,
          accessed_primitives: [:branch_prune], # Forbidden!
          uncertainty_injection: 0.0
        }
      }

      assert {:error, reason} = ObserverSafety.validate_observer_boundaries(breaching_observers)
      assert reason =~ "Substrate access violation"
    end

    test "rejects high-recursion observers with insufficient uncertainty floors" do
      insufficient_uncertainty = %{
        "obs_recursive" => %{
          recursion_depth: 4,
          accessed_primitives: [],
          uncertainty_injection: 0.02 # floor is 0.05
        }
      }

      assert {:error, reason} = ObserverSafety.validate_observer_boundaries(insufficient_uncertainty)
      assert reason =~ "Insufficient uncertainty injection"
    end
  end

  describe "EquilibriumMonitor" do
    test "passes stable global equilibrium matrices" do
      stable_metrics = %{
        psi: 0.8,
        omega: 0.4,
        phi: 0.5,
        attractor_detected: false
      }

      assert {:ok, result} = EquilibriumMonitor.validate_global_equilibrium(stable_metrics)
      assert result.status == :equilibrated
    end

    test "rejects Ψ readings falling below critical threshold" do
      unstable_metrics = %{
        psi: 0.25, # limit 0.30
        omega: 0.4,
        phi: 0.5,
        attractor_detected: false
      }

      assert {:error, reason} = EquilibriumMonitor.validate_global_equilibrium(unstable_metrics)
      assert reason =~ "Global stability Ψ below critical threshold"
    end

    test "rejects high divergence coupling between Ω and Φ" do
      diverged_metrics = %{
        psi: 0.8,
        omega: 0.9,
        phi: 0.3, # divergence is 0.6 > 0.4
        attractor_detected: false
      }

      assert {:error, reason} = EquilibriumMonitor.validate_global_equilibrium(diverged_metrics)
      assert reason =~ "Ω/Φ divergence too high"
    end
  end
end
