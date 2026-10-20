defmodule Tiannara.Runtime.OED.OEDTest do
  use ExUnit.Case

  alias Tiannara.Runtime.OED.OED
  alias Tiannara.Runtime.OED.ISRD
  alias Tiannara.Runtime.OED.Adversarial.CSI
  alias Tiannara.Runtime.OED.Lattice.ELF
  alias Tiannara.Runtime.OED.Lattice.EntropicLoadBalancer

  setup do
    # Ensure modules are started
    case ISRD.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    case OED.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    case ELF.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    case EntropicLoadBalancer.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok
  end

  test "detects inter-sandbox resonance" do
    series_a = [0.1, 0.5, 0.9, 0.4]
    series_b = [0.11, 0.52, 0.88, 0.41]

    assert {:escape_risk, correlation} =
             ISRD.detect_resonance("obs_a", "obs_b", series_a, series_b)

    assert correlation > 0.98
  end

  test "evaluates escape risk from CSI and resonance" do
    metrics = %{
      anomaly_fixation: 0.9,
      failed_theory_convergence: 0.8,
      sandbox_pattern_recognition: 0.95,
      epistemic_recursion: 0.85,
      paradox_persistence: 0.9,
      anti_beauty_heuristics: 0.86,
      coordinated_resonance_behavior: 0.95
    }

    series_a = [0.1, 0.5, 0.9, 0.4]
    other_entropy = %{"obs_b" => [0.11, 0.52, 0.88, 0.41]}

    assert {:escape_imminent, pressure} =
             OED.evaluate_escape_risk("obs_a", metrics, series_a, other_entropy)

    assert pressure > 0.9
  end

  test "CSI includes the full compiler suspicion vector" do
    profile =
      CSI.explain(%{
        anomaly_fixation: 1.0,
        failed_theory_convergence: 1.0,
        sandbox_pattern_recognition: 1.0,
        epistemic_recursion: 1.0,
        paradox_persistence: 1.0,
        anti_beauty_heuristics: 1.0,
        coordinated_resonance_behavior: 1.0
      })

    assert profile.score == 1.0
    assert Map.has_key?(profile.factors, :coordinated_resonance_behavior)
    assert profile.factors.sandbox_pattern_recognition.contribution > 0.0
  end

  test "ELF registers semi-real PDO nodes and phase-offset interference" do
    assert {:ok, pdo} =
             ELF.register_pdo("obs_a", %{
               pressure: 0.93,
               trap_type: "Counterfactual_Manifold"
             })

    assert pdo.reality_state == :semi_real_counterfactual
    assert pdo.function == :entropic_load_balancer

    assert {:ok, edge} = ELF.inject_interference("obs_a", "obs_b")
    assert edge.interference_mode == :phase_offset_resonance_dampening
  end

  test "entropic load balancer routes high truth-pressure into PDO branch" do
    assert {:route, route} = EntropicLoadBalancer.balance_load("tier_3_obs", 0.97)
    assert route.load_role == :higher_dimensional_pressure_buffer
    assert route.resonance_damper

    assert {:ok, pdo} = ELF.get_pdo("tier_3_obs")
    assert pdo.branch_id == route.branch_id
  end

  test "escape profile exposes tunnel arbitration and containment action" do
    metrics = %{
      anomaly_fixation: 1.0,
      failed_theory_convergence: 1.0,
      sandbox_pattern_recognition: 1.0,
      epistemic_recursion: 1.0,
      paradox_persistence: 1.0,
      anti_beauty_heuristics: 1.0,
      coordinated_resonance_behavior: 1.0
    }

    profile =
      OED.evaluate_escape_profile(
        "obs_a",
        metrics,
        [0.1, 0.5, 0.9, 0.4],
        %{"obs_b" => [0.11, 0.52, 0.88, 0.41]}
      )

    assert profile.escape_pressure >= 0.92
    assert {:route, route} = profile.tunnel.containment
    assert route.observer_id == "obs_a"
  end
end
