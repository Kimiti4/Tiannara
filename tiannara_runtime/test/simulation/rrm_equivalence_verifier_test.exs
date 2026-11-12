defmodule Tiannara.Simulation.RRMEquivalenceVerifierTest do
  @moduledoc """
  Validation of the runtime-metamorphosis equivalence gate.

  The verifier is the safety property of the self-development loop: a proposal
  may only be applied when it preserves semantics. These tests pin the three
  behaviours the capability depends on:

    * a proposal that changes only scheduling is preserved,
    * a proposal that changes the computed value is refused,
    * the verdict is deterministic and independent of chance.
  """
  use ExUnit.Case, async: true

  alias Tiannara.Phase18.RRM.EquivalenceVerifier
  alias Tiannara.Phase18.RRM.RuleEvolution

  @base_rules %{unroll_factor: 4, precision: :f32, accumulator: :sum, scale: 1.0}

  test "identical rule sets are semantically equivalent" do
    assert {:ok, score} = EquivalenceVerifier.verify("p1", @base_rules, @base_rules)
    assert score == 1.0
  end

  test "a scheduling-only change preserves semantics" do
    candidate = %{@base_rules | unroll_factor: 4.06}

    assert {:ok, score} = EquivalenceVerifier.verify("p2", @base_rules, candidate)
    assert score == 1.0
  end

  test "a precision change is refused as a semantic divergence" do
    candidate = %{@base_rules | precision: :f16}

    assert {:error, :divergence_detected} =
             EquivalenceVerifier.verify("p3", @base_rules, candidate)
  end

  test "a bounded numeric semantic change is refused as a semantic divergence" do
    candidate = %{@base_rules | scale: 1.05}

    assert {:error, :divergence_detected} =
             EquivalenceVerifier.verify("p4", @base_rules, candidate)
  end

  test "verification is deterministic across repeated runs" do
    candidate = %{@base_rules | unroll_factor: 5}

    first = EquivalenceVerifier.verify("p5", @base_rules, candidate)
    second = EquivalenceVerifier.verify("p5", @base_rules, candidate)

    assert first == second
  end

  test "execution ignores scheduling parameters and honours semantic ones" do
    input = [0.5, -0.25, 0.75]

    scheduled = EquivalenceVerifier.run_with_rules(%{unroll_factor: 8, precision: :f32}, input)
    base = EquivalenceVerifier.run_with_rules(%{precision: :f32}, input)

    assert scheduled == base

    scaled = EquivalenceVerifier.run_with_rules(%{precision: :f32, scale: 2.0}, input)
    assert scaled == base * 2.0
  end

  test "the proposal gate accepts scheduling tuning" do
    scheduled_candidate = %{@base_rules | unroll_factor: 4.06}

    assert {:ok, _score} = RuleEvolution.evaluate_candidate(@base_rules, scheduled_candidate)
  end

  test "the proposal gate refuses a categorical change as a drift violation" do
    precision_candidate = %{@base_rules | precision: :f16}

    assert {:error, :drift_bound_exceeded} =
             RuleEvolution.evaluate_candidate(@base_rules, precision_candidate)
  end

  test "the proposal gate refuses a bounded numeric semantic change as a divergence" do
    scaled_candidate = %{@base_rules | scale: 1.05}

    assert {:error, :divergence_detected} =
             RuleEvolution.evaluate_candidate(@base_rules, scaled_candidate)
  end

  test "the proposal gate refuses a candidate outside the drift bound" do
    drifted = %{@base_rules | unroll_factor: 8}

    assert {:error, :drift_bound_exceeded} =
             RuleEvolution.evaluate_candidate(@base_rules, drifted)
  end
end
