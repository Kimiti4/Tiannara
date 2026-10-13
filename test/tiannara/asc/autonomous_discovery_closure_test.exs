defmodule Tiannara.ASC.AutonomousDiscoveryClosureTest do
  @moduledoc """
  B11/D-A2: one real discover→hypothesize→experiment→validate→evidence→fact→lineage
  vertical slice (physics pilot) plus honesty cases. No fabricated evidence.
  """

  use ExUnit.Case, async: false

  alias Tiannara.ASC.AutonomousDiscovery
  alias Tiannara.Domains.Physics
  alias Tiannara.Memory.KnowledgeStore
  alias Tiannara.MetaScience.PortfolioOptimizer
  alias Tiannara.Reasoning.KnowledgeRepresentation

  @research_dir Application.compile_env(:tiannara, :storage_base, "./test_data/storage")
                |> Path.join("research_facts")

  setup do
    File.rm_rf!(@research_dir)
    File.mkdir_p!(@research_dir)
    :ok
  end

  defp physics_candidate(hypothesis \\ nil, context \\ nil) do
    pilot = Physics.pilot_experiment()

    %{
      experiment: %{
        domain_module: Physics,
        hypothesis: hypothesis || pilot.hypothesis,
        context: context || pilot.context,
        domain_weight: 1.2
      }
    }
  end

  defp research_artifacts do
    {:ok, store} = KnowledgeStore.open(@research_dir)
    KnowledgeStore.all(store)
  end

  defp facts do
    research_artifacts()
    |> Enum.filter(fn a -> a.rung == :principle end)
    |> Enum.map(& &1.content)
  end

  defp rejections do
    research_artifacts()
    |> Enum.filter(fn a -> a.rung == :experiment end)
    |> Enum.map(& &1.content)
  end

  describe "positive real experiment (physics pilot)" do
    test "simulate → validate → evidence → fact with identity and lineage" do
      assert {:ok, :discovery_integrated, fact} =
               AutonomousDiscovery.execute_experiment(physics_candidate())

      assert fact.subject == :mechanics
      assert fact.predicate == :validates
      assert fact.object == :damped_oscillation
      assert is_number(fact.confidence) and fact.confidence >= 0.0 and fact.confidence <= 1.0
      assert fact.confidence == 1.0

      assert is_binary(fact.mission_id)
      assert is_binary(fact.hypothesis_id)
      assert is_binary(fact.experiment_id)
      assert is_binary(fact.execution_id)
      assert String.starts_with?(fact.mission_id, "mission_")
      assert String.starts_with?(fact.hypothesis_id, "hyp_")
      assert String.starts_with?(fact.experiment_id, "exp_")
      assert String.starts_with?(fact.execution_id, "exec_")

      assert fact.lineage == [
               fact.mission_id,
               fact.hypothesis_id,
               fact.experiment_id,
               fact.execution_id
             ]

      assert %{kind: :simulation, evidence_hash: hash} = fact.provenance
      assert is_binary(hash) and byte_size(hash) == 64

      assert fact.evidence.trajectory_points > 0
      assert fact.evidence.method == :rk4
      assert fact.evidence.verification_method == :structural_checks
      assert fact.evidence.checks_total > 0
      assert fact.evidence.checks_passed == fact.evidence.checks_total

      assert fact.validation.valid == true
      assert fact.validation.verification_method == :structural_checks
      assert is_map(fact.params) and fact.params.m == 1.0

      assert fact.constitutional.research_only == true
      assert fact.constitutional.deployment_authority == false

      stored = facts()
      assert length(stored) == 1
      assert hd(stored).mission_id == fact.mission_id
      assert hd(stored).execution_id == fact.execution_id
    end

    test "experiment identity is unique across executions" do
      assert {:ok, :discovery_integrated, fact1} =
               AutonomousDiscovery.execute_experiment(physics_candidate())

      assert {:ok, :discovery_integrated, fact2} =
               AutonomousDiscovery.execute_experiment(physics_candidate())

      refute fact1.mission_id == fact2.mission_id
      refute fact1.execution_id == fact2.execution_id
      refute fact1.experiment_id == fact2.experiment_id
      assert length(facts()) == 2
    end
  end

  describe "negative / falsification experiment" do
    test "unstable (energy-growing) hypothesis is rejected and no fact is asserted" do
      # Inverted spring: energy grows; structural energy check must fail.
      unstable = %{
        subject: :mechanics,
        object: :unstable_growth,
        equations: %{
          type: :first_order_system,
          dimension: 2,
          derivative: fn _t, [x, v] -> [v, 10.0 * x] end,
          params: %{m: 1.0, c: 0.0, k: 4.0, model: :unstable_inverted_spring}
        },
        description: "deliberately invalid: energy not bounded"
      }

      context = %{boundary_conditions: [1.0, 0.0], time_span: %{duration: 2.0, dt: 0.01}}

      assert {:ok, :hypothesis_rejected, counterexamples} =
               AutonomousDiscovery.execute_experiment(physics_candidate(unstable, context))

      assert is_list(counterexamples)
      assert counterexamples != []
      assert Enum.all?(counterexamples, &(&1.within_tolerance == false))

      assert facts() == []
      assert length(rejections()) == 1
      rejection = hd(rejections())
      assert rejection.outcome == :hypothesis_rejected
      assert rejection.object == :unstable_growth
      assert is_binary(rejection.mission_id)
      assert rejection.counterexamples == counterexamples
    end

    test "missing measurement (validation formal unavailable) does not produce a success-shaped fact" do
      # Simulate succeeds (RK4 runs) but params lack m/c/k so structural validation
      # fails closed with :formal_verification_unavailable — no success-shaped fact.
      incomplete = %{
        subject: :mechanics,
        object: :incomplete_measurement,
        equations: %{
          type: :first_order_system,
          dimension: 2,
          derivative: fn _t, [x, v] -> [v, -4.0 * x] end,
          params: %{note: "m/c/k intentionally omitted"}
        },
        description: "simulation without validation params"
      }

      context = %{boundary_conditions: [1.0, 0.0], time_span: %{duration: 1.0, dt: 0.01}}

      assert {:ok, :validation_unavailable, reason} =
               AutonomousDiscovery.execute_experiment(physics_candidate(incomplete, context))

      assert reason == :formal_verification_unavailable
      assert facts() == []
      assert rejections() == []
    end

    test "failed experiment (unsupported ODE) is simulation_unavailable, not success" do
      bad = %{
        subject: :mechanics,
        object: :unsupported,
        equations: [],
        description: "no equations"
      }

      assert {:ok, :simulation_unavailable, reason} =
               AutonomousDiscovery.execute_experiment(physics_candidate(bad, %{}))

      assert reason == :ode_solver_unavailable
      assert facts() == []
      assert rejections() == []
    end
  end

  describe "contradictory and missing evidence remain visible" do
    test "prior fact stays when a later hypothesis is rejected" do
      assert {:ok, :discovery_integrated, fact} =
               AutonomousDiscovery.execute_experiment(physics_candidate())

      unstable = %{
        subject: :mechanics,
        object: :conflicting_claim,
        equations: %{
          type: :first_order_system,
          dimension: 2,
          derivative: fn _t, [x, v] -> [v, 20.0 * x] end,
          params: %{m: 1.0, c: 0.0, k: 4.0}
        }
      }

      context = %{boundary_conditions: [1.0, 0.0], time_span: %{duration: 1.5, dt: 0.01}}

      assert {:ok, :hypothesis_rejected, _} =
               AutonomousDiscovery.execute_experiment(physics_candidate(unstable, context))

      assert length(facts()) == 1
      assert hd(facts()).mission_id == fact.mission_id
      assert length(rejections()) == 1
      assert hd(rejections()).object == :conflicting_claim
    end
  end

  describe "restart / persistence" do
    test "fact identity and contents survive store reload" do
      assert {:ok, :discovery_integrated, fact} =
               AutonomousDiscovery.execute_experiment(physics_candidate())

      # Simulate restart: open a fresh handle on the same directory (no wipe).
      reloaded =
        case KnowledgeStore.open(@research_dir) do
          {:ok, store} -> KnowledgeStore.all(store)
          error -> flunk("reload failed: #{inspect(error)}")
        end

      reloaded_facts =
        reloaded
        |> Enum.filter(&(&1.rung == :principle))
        |> Enum.map(& &1.content)

      match = Enum.find(reloaded_facts, &(&1.mission_id == fact.mission_id))
      assert match != nil, "reloaded store missing fact #{fact.mission_id}"
      assert match.execution_id == fact.execution_id
      assert match.lineage == fact.lineage
      assert match.provenance.evidence_hash == fact.provenance.evidence_hash
      assert match.confidence == fact.confidence
      assert match.evidence == fact.evidence
      assert match.validation == fact.validation
    end

    test "assert_fact fails closed without full identity" do
      assert {:error, {:missing_identity, _}} =
               KnowledgeRepresentation.assert_fact(:a, :b, :c, 0.9, %{})

      assert {:error, :invalid_confidence} =
               KnowledgeRepresentation.assert_fact(:a, :b, :c, 2.0, %{
                 mission_id: "m",
                 hypothesis_id: "h",
                 experiment_id: "e",
                 execution_id: "x",
                 lineage: ["m"],
                 provenance: %{kind: :simulation}
               })
    end
  end

  describe "bounded execution" do
    test "timeout is never success-shaped" do
      result =
        AutonomousDiscovery.execute_experiment(
          %{
            experiment: %{
              domain_module: Tiannara.ASC.AutonomousDiscoveryClosureTest.SlowDomain,
              hypothesis: %{subject: :mechanics, object: :slow},
              context: %{},
              domain_weight: 1.0
            }
          },
          timeout_ms: 50
        )

      assert {:ok, :experiment_timeout, 50} = result
      assert facts() == []
    end

    test "crashing experiment is not success" do
      result =
        AutonomousDiscovery.execute_experiment(
          %{
            experiment: %{
              domain_module: Tiannara.ASC.AutonomousDiscoveryClosureTest.CrashDomain,
              hypothesis: %{subject: :mechanics, object: :boom},
              context: %{},
              domain_weight: 1.0
            }
          },
          timeout_ms: 500
        )

      assert {:ok, :experiment_crashed, _reason} = result
      assert facts() == []
    end
  end

  describe "repeatability" do
    test "two CI runs of the pilot produce the same verdict and confidence" do
      assert {:ok, :discovery_integrated, f1} =
               AutonomousDiscovery.execute_experiment(physics_candidate())

      assert {:ok, :discovery_integrated, f2} =
               AutonomousDiscovery.execute_experiment(physics_candidate())

      assert f1.confidence == f2.confidence
      assert f1.validation == f2.validation
      assert f1.evidence.trajectory_points == f2.evidence.trajectory_points
      assert f1.provenance.evidence_hash == f2.provenance.evidence_hash
      refute f1.mission_id == f2.mission_id
    end
  end

  describe "full discovery cycle wiring" do
    test "run_discovery_cycle selects physics (higher weight) and integrates" do
      # CanonicalRegistry is started by the app supervision tree.
      assert {:ok, :discovery_integrated, fact} = AutonomousDiscovery.run_discovery_cycle()
      assert fact.object == :damped_oscillation
      assert fact.constitutional.deployment_authority == false
    end

    test "portfolio selection is deterministic by domain_weight" do
      candidates = [
        %{domain_weight: 0.5, tag: :low},
        %{domain_weight: 1.2, tag: :high},
        %{domain_weight: 0.9, tag: :mid}
      ]

      assert {:ok, best} = PortfolioOptimizer.select_next_experiment(candidates)
      assert best.experiment.tag == :high
      assert best.utility == 1.2

      assert {:error, :no_candidates} = PortfolioOptimizer.select_next_experiment([])
    end
  end

  describe "constitutional boundary" do
    test "research fact carries no deployment authority" do
      assert {:ok, :discovery_integrated, fact} =
               AutonomousDiscovery.execute_experiment(physics_candidate())

      refute Map.has_key?(fact, :deployment)
      refute Map.has_key?(fact, :deployed)
      assert fact.constitutional == %{research_only: true, deployment_authority: false}
    end
  end
end

defmodule Tiannara.ASC.AutonomousDiscoveryClosureTest.SlowDomain do
  def simulate(_h, _c) do
    Process.sleep(5_000)
    {:ok, %{result: %{}, provenance: nil}}
  end

  def validate(_), do: {:error, :formal_verification_unavailable}
end

defmodule Tiannara.ASC.AutonomousDiscoveryClosureTest.CrashDomain do
  def simulate(_h, _c), do: raise("experiment crash (intentional)")
  def validate(_), do: {:error, :formal_verification_unavailable}
end
