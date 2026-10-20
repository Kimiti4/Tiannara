defmodule Tiannara.Kernel.SelfCompilationTest do
  use ExUnit.Case, async: false

  alias Tiannara.Kernel.{
    SelfCompilation,
    RuleExtractor,
    MutationEngine,
    ValidationGate,
    DeploymentOrchestrator
  }

  setup do
    # Make sure SelfCompilation is restarted/reset between tests if running
    if Process.whereis(SelfCompilation) do
      GenServer.call(SelfCompilation, :reset)
    else
      start_supervised!({SelfCompilation, compilation_interval_ms: 10_000})
    end

    :ok
  end

  describe "RuleExtractor" do
    test "extracts rules from active configuration map into standard ASTs" do
      active_rules = %{
        omce: %{compression_strategy: :adaptive, threshold: 0.7},
        olef: %{diffusion_rate: 0.05, pressure_cap: 1.0},
        hsv: %{curvature_threshold: 12.0, archive_retention_ms: 86_400_000},
        ctl: %{stress_threshold: 0.75, reconciliation_budget: 100.0}
      }

      assert {:ok, asts} = RuleExtractor.extract(active_rules)
      assert map_size(asts) == 4

      # Verify OMCE extraction
      assert asts.omce.type == :compression_policy
      assert elem(asts.omce.body, 0) == :if
      assert :causal_conservation in asts.omce.invariants

      # Verify OLEF extraction
      assert asts.olef.type == :diffusion_policy
      assert elem(asts.olef.body, 0) == :diffuse
    end
  end

  describe "MutationEngine" do
    test "applies dampening mutation bounds relative to cycle depth" do
      rules = %{
        omce: %{
          type: :compression_policy,
          body: {:if, {:>, :ontology_density, 0.7}, {:apply, :adaptive, [:aggressive]}, {:apply, :adaptive, [:conservative]}},
          invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
        }
      }

      # Run multiple generations to observe mutation behavior at depth 0
      {:ok, mutated_depth_0} = MutationEngine.generate(rules, 0)
      assert Map.has_key?(mutated_depth_0, :omce)

      # Run generations at high depth (should be highly dampened/conserved)
      {:ok, mutated_depth_10} = MutationEngine.generate(rules, 10)
      # At depth 10, the mutation rate is 0.5 / 11 = ~0.045. It should mostly remain unchanged.
      assert Map.has_key?(mutated_depth_10, :omce)
    end
  end

  describe "ValidationGate" do
    test "passes valid candidate rules preserving all core invariants" do
      candidate_rules = %{
        omce: %{
          type: :compression_policy,
          body: {:if, {:>, :ontology_density, 0.7}, {:apply, :adaptive, [:aggressive]}, {:apply, :adaptive, [:conservative]}},
          invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
        }
      }

      assert {:ok, _} = ValidationGate.verify(candidate_rules, 0.30)
    end

    test "rejects rules with missing invariants" do
      invalid_rules = %{
        omce: %{
          type: :compression_policy,
          body: {:if, {:>, :ontology_density, 0.7}, {:apply, :adaptive, [:aggressive]}, {:apply, :adaptive, [:conservative]}},
          invariants: [:causal_conservation] # Missing observer_safety etc.
        }
      }

      assert {:error, reason} = ValidationGate.verify(invalid_rules, 0.30)
      assert reason =~ "Missing required invariants"
    end

    test "rejects rules violating observer safety constraints" do
      unsafe_rules = %{
        omce: %{
          type: :compression_policy,
          body: {:apply, :bypass_osl, [123]},
          invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
        }
      }

      assert {:error, reason} = ValidationGate.verify(unsafe_rules, 0.30)
      assert reason =~ "Observer safety violation"
    end

    test "rejects rules that would destabilize global Ψ below threshold" do
      # Adjust threshold down drastically to simulate high perturbation
      perturbed_rules = %{
        hsv: %{
          type: :horizon_gc_policy,
          body: {:if, {:>, :curvature_stress, 0.05}, {:archive, 100}, :ignore}, # Huge drop from 12.0
          invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
        }
      }

      assert {:error, reason} = ValidationGate.verify(perturbed_rules, 0.01)
      assert reason =~ "destabilize Ψ below threshold"
    end
  end

  describe "DeploymentOrchestrator" do
    test "performs hitless hot-swaps using topological ordering" do
      valid_rules = %{
        omce: %{
          type: :compression_policy,
          body: {:if, {:>, :ontology_density, 0.7}, {:apply, :adaptive, [:aggressive]}, {:apply, :adaptive, [:conservative]}},
          invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
        },
        olef: %{
          type: :diffusion_policy,
          body: {:diffuse, :pressure_field, 0.05, {:cap, 1.0}},
          invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
        }
      }

      assert {:ok, results} = DeploymentOrchestrator.hot_swap(valid_rules, :tiannara_nats)
      assert Map.has_key?(results, :omce)
      assert Map.has_key?(results, :olef)
    end
  end

  describe "SelfCompilation GenServer" do
    test "exposes active rules and cycle counters" do
      active = SelfCompilation.active_rules()
      assert Map.has_key?(active, :omce)
      assert Map.has_key?(active, :olef)

      # Trigger compile cycle manually
      send(SelfCompilation, :compile_cycle)
      # Verify it ticks or is queryable
      new_active = SelfCompilation.active_rules()
      assert is_map(new_active)
    end

    test "tracks success and failure feedback loops in sliding history" do
      # Query initial state
      state = :sys.get_state(SelfCompilation)
      assert state.compilation_success_history == []

      # Force run compile cycle (which will succeed given base rules are valid)
      send(SelfCompilation, :compile_cycle)
      # Wait a brief moment for async cast/hot swap logic to complete if any
      Process.sleep(100)

      updated_state = :sys.get_state(SelfCompilation)
      # Should record at least one success/failure outcome
      assert length(updated_state.compilation_success_history) > 0
      assert hd(updated_state.compilation_success_history) in [:success, :failure]
    end
  end

  describe "ValidationGate integration with CategoryTheoreticValidator" do
    test "rejects rules violating category-theoretic composition boundaries" do
      invalid_composition_rules = %{
        olef: %{
          type: :diffusion_policy,
          body: {:diffuse, :pressure_field, 0.05, {:cap, -10.0}}, # invalid negative cap composition
          invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
        }
      }

      assert {:error, reason} = ValidationGate.verify(invalid_composition_rules, 0.30)
      assert reason =~ "composition morphism is non-homomorphic" or reason =~ "Identity morphism violation"
    end
  end
end
