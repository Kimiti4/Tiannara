defmodule Tiannara.EID.BenchTest do
  use ExUnit.Case
  alias Tiannara.EID.Bench
  alias Tiannara.EGL.FeedbackLoop
  alias Tiannara.EID.ProofSystem
  alias Tiannara.EID.AdversarialBench

  setup do
    mock_state = %{
      worlds: %{
        "world_1" => %{
          id: "world_1",
          entropy: 0.75,
          coherence: 0.82,
          semantic_diversity: 0.78,
          attractor_convergence: 0.35,
          stabilizer_overreach: 0.25,
          msg_pressure: 0.32,
          active_branches: 15,
          fitness: 0.85
        },
        "world_2" => %{
          id: "world_2",
          entropy: 0.65,
          coherence: 0.88,
          semantic_diversity: 0.72,
          attractor_convergence: 0.30,
          stabilizer_overreach: 0.20,
          msg_pressure: 0.28,
          active_branches: 12,
          fitness: 0.90
        }
      }
    }

    {:ok, state: mock_state}
  end

  test "EID.Bench calculates sigmoid correctly" do
    assert Bench.sigmoid(0.0) == 0.5
    assert Bench.sigmoid(10.0) > 0.99
    assert Bench.sigmoid(-10.0) < 0.01
  end

  test "EID.Bench evaluates state and classifies correctly", %{state: state} do
    {classification, score} = Bench.evaluate(state)
    assert is_atom(classification)
    assert is_float(score)
    assert score >= 0.0 and score <= 1.0
  end

  test "EGL.FeedbackLoop runs successfully with state", %{state: state} do
    # Can run reinforcement or stabilization
    result = FeedbackLoop.run(state)
    assert result == :ok or match?({:ok, :applied, _}, result)
  end

  test "EID.ProofSystem validates behavior patterns correctly" do
    valid_behavior = %{
      duration: 5,
      transferred_worlds_count: 3,
      complexity_delta: -0.15,
      self_predictive_accuracy: 0.85
    }

    invalid_behavior = %{
      duration: 1,
      transferred_worlds_count: 0,
      complexity_delta: 0.05,
      self_predictive_accuracy: 0.40
    }

    assert ProofSystem.validate(valid_behavior) == :emergent
    assert ProofSystem.validate(invalid_behavior) == :non_emergent
  end

  test "EID.AdversarialBench validates all perturbation benchmarks", %{state: state} do
    assert AdversarialBench.run(state) == :pass
  end
end
