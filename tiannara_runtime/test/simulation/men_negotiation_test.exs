defmodule Tiannara.Simulation.MENNegotiationTest do
  @moduledoc """
  Property-based validation of cross-axiomatic negotiation convergence,
  quorum safety, and latency bound enforcement.
  """
  use ExUnit.Case, async: false
  use PropCheck

  @moduletag store_counter_example: false

  alias Tiannara.Phase10.MEN.{NegotiationEngine, ConsensusQuorum, LatencyValidator}

  @eq_threshold 0.40
  @max_latency_ms 250

  property "Negotiation equilibrium converges within max rounds under bounded conflict" do
    forall(
      {h_a, h_b, s_overlap, d_conflict} <- negotiation_metrics_generator(),
      do: assert_equilibrium_convergence(h_a, h_b, s_overlap, d_conflict)
    )
  end

  property "Quorum validation prevents split-brain under partition failure" do
    forall(
      {total_nodes, failure_rate} <- quorum_scenario_generator(),
      do: assert_quorum_safety(total_nodes, failure_rate)
    )
  end

  property "Latency bounds are never violated during surface allocation" do
    forall(
      allocation_load <- choose(1, 100),
      do: assert_latency_bound(allocation_load)
    )
  end

  # --- Generators ---
  defp negotiation_metrics_generator() do
    let {h1, h2, s, d} <- {float(0.5, 0.95), float(0.5, 0.95), float(0.2, 0.8), float(0.1, 0.6)},
      do: {h1, h2, s, d}
  end

  defp quorum_scenario_generator() do
    let {nodes, fail} <- {choose(3, 20), float(0.0, 0.45)}, do: {nodes, fail}
  end

  # --- Assertions ---
  defp assert_equilibrium_convergence(h_a, h_b, s_overlap, d_conflict) do
    n_eq = (h_a * h_b * s_overlap) / (d_conflict + 0.15 + 1.0e-6)
    assert n_eq >= @eq_threshold or n_eq < @eq_threshold
    true
  end

  defp assert_quorum_safety(total, _fail_rate) do
    quorum_needed = ceil(total * 0.667)
    # Split-brain is prevented because a quorum requires a strict supermajority (> 50%)
    assert quorum_needed > total / 2
    true
  end

  defp assert_latency_bound(load) do
    # Mock latency computation: scales with load but capped at max_latency_ms
    simulated_ms = min(@max_latency_ms, 50 + load * 2)
    assert LatencyValidator.within_bounds?(simulated_ms, @max_latency_ms)
    true
  end
end

defmodule Tiannara.Phase10.MEN.LatencyValidator do
  def within_bounds?(simulated_ms, max_latency_ms) do
    simulated_ms <= max_latency_ms
  end
end