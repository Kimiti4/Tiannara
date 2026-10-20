defmodule Tiannara.Simulation.REGEpistemicTest do
  @moduledoc "Property-based validation of drift bounds, consistency, & convergence."
  use ExUnit.Case, async: true
  use PropCheck

  alias Tiannara.Phase14.REG.{ConsistencyProver, DriftController}

  @consistency_threshold 0.92
  @max_drift 0.35

  property "Generated axioms remain within drift bounds under stochastic mutation" do
    forall(
      {base, novel} <- axiom_pair_generator(),
      do: assert_drift_bounded(base, novel)
    )
  end

  property "Axiomatic consistency stays above threshold across generation cycles" do
    forall(
      axioms <- axiom_set_generator(),
      do: assert_consistency_holds(axioms)
    )
  end

  defp axiom_pair_generator() do
    let size <- integer(3, 10) do
      base = generate_mock_axioms(size)
      novel = mutate_one_key(base)
      {base, novel}
    end
  end

  defp mutate_one_key(base) do
    keys = Map.keys(base)
    if keys == [] do
      base
    else
      key = Enum.random(keys)
      Map.put(base, key, Enum.random([:linear, :nonlinear, :recursive, :observer_relative]))
    end
  end

  defp generate_mock_axioms(n) do
    Enum.map(1..n, &{"key_#{&1}", Enum.random([:linear, :nonlinear, :recursive, :observer_relative])}) |> Map.new()
  end

  defp axiom_set_generator(), do: let(n <- integer(3, 10), do: generate_mock_axioms(n))

  defp assert_drift_bounded(base, novel) do
    DriftController.compute_drift(base, novel) <= @max_drift
  end

  defp assert_consistency_holds(axioms) do
    ConsistencyProver.verify(axioms) >= @consistency_threshold
  end
end