defmodule Tiannara.Audit.AuditFrameworkTest do
  use ExUnit.Case, async: false

  alias Tiannara.Audit.{
    CoherenceValidator,
    StabilityHarness,
    ChaosInjector,
    AuditReporter
  }

  alias Tiannara.Kernel.SelfCompilation

  setup do
    # Make sure SelfCompilation is reset if running
    if Process.whereis(SelfCompilation) do
      GenServer.call(SelfCompilation, :reset)
    else
      start_supervised!({SelfCompilation, compilation_interval_ms: 10_000})
    end

    :ok
  end

  describe "StabilityHarness" do
    test "correctly analyzes load metrics and evaluates Ψ stability" do
      valid_load = StabilityHarness.generate_simulation_load(10, 5)
      assert valid_load.psi >= 0.30
      assert :ok = StabilityHarness.run_stability_check(valid_load)

      # High observer count + rapid growth rate causing stability drop (manually perturbed)
      high_load = %{psi: 0.25, omega: 0.8, phi: 0.5, attractor_detected: false}
      assert {:error, reason} = StabilityHarness.run_stability_check(high_load)
      assert reason =~ "Stability check failed"
    end
  end

  describe "CoherenceValidator" do
    test "returns passed status for completely safe, coherent mock states" do
      mock_states = %{
        branch_registry: %{
          "b1" => %{events: [], state: :active, persistence_prob: 0.9, observer_density: 0.1, reconciliation_cost: 10.0}
        },
        node_states: %{
          "n1" => %{vector: [0.1, 0.2, 0.9], semantic_dispersion: 0.4},
          "n2" => %{vector: [0.11, 0.21, 0.89], semantic_dispersion: 0.35}
        },
        observer_states: %{
          "o1" => %{recursion_depth: 2, accessed_primitives: [], uncertainty_injection: 0.1}
        },
        cosmological_metrics: %{
          psi: 0.9,
          omega: 0.4,
          phi: 0.5,
          attractor_detected: false
        },
        active_rules: %{
          omce: %{invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound], body: nil, type: nil}
        }
      }

      audit = CoherenceValidator.run_full_coherence_audit(mock_states)
      assert audit.status == :passed
      assert audit.findings == []
      assert audit.recommendations == []
    end

    test "fails coherence audit when any pre-phase6 checks fail" do
      mock_states_failed = %{
        branch_registry: %{
          # Contradictory events!
          "b1" => %{
            events: [%{type: :w, state: :ok}, %{type: :w, state: :err}],
            state: :active,
            persistence_prob: 0.9,
            observer_density: 0.1,
            reconciliation_cost: 10.0
          }
        },
        node_states: %{},
        observer_states: %{},
        cosmological_metrics: %{
          psi: 0.9,
          omega: 0.4,
          phi: 0.5,
          attractor_detected: false
        }
      }

      audit = CoherenceValidator.run_full_coherence_audit(mock_states_failed)
      assert audit.status == :failed
      assert length(audit.findings) > 0
      assert length(audit.recommendations) > 0
    end
  end

  describe "ChaosInjector" do
    test "triggers and awaits chaotic resilience simulations successfully" do
      assert {:ok, result} = ChaosInjector.inject_scenario(:nats_partition, 50)
      assert result.scenario == :nats_partition
      assert result.status == :success

      assert {:ok, fuzzed} = ChaosInjector.inject_scenario(:opc_compiler_fuzz, 50)
      assert fuzzed.scenario == :opc_compiler_fuzz
      assert fuzzed.status == :success
    end
  end

  describe "AuditReporter" do
    test "compiles structured Markdown reports with execution metrics" do
      mock_states = %{
        branch_registry: %{
          "b1" => %{events: [], state: :active, persistence_prob: 0.9, observer_density: 0.1, reconciliation_cost: 10.0}
        },
        node_states: %{
          "n1" => %{vector: [0.1, 0.2, 0.9], semantic_dispersion: 0.4},
          "n2" => %{vector: [0.11, 0.21, 0.89], semantic_dispersion: 0.35}
        },
        observer_states: %{
          "o1" => %{recursion_depth: 2, accessed_primitives: [], uncertainty_injection: 0.1}
        },
        cosmological_metrics: %{
          psi: 0.9,
          omega: 0.4,
          phi: 0.5,
          attractor_detected: false
        },
        active_rules: %{
          omce: %{invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound], body: nil, type: nil}
        }
      }

      report = AuditReporter.generate_pre_phase6_audit_report(mock_states)

      assert String.contains?(report, "# Tiannara Pre-Phase 6 Audit Report")
      assert String.contains?(report, "Status: PASSED")
      assert String.contains?(report, "Global Stability Ψ**: 0.9")
      assert String.contains?(report, "active rules")
    end
  end
end
