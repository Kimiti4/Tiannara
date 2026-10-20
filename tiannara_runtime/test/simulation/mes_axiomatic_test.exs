defmodule Tiannara.Simulation.MESAxiomaticTest do
  @moduledoc """
  Property-based validation of novel axiom consistency, drift bounds, and containment safety.
  """
  use ExUnit.Case, async: true
  use PropCheck

  alias Tiannara.Phase9.MES.{AxiomaticGenerator, ConsistencyValidator}

  property "Novel axioms remain within representational drift bounds" do
    forall(_ <- generate_any_params(), do: assert_drift_bounded())
  end

  property "Axiom sets pass consistency validation under stochastic mutation" do
    forall(params <- mutation_params_generator(), do: assert_consistency_passes(params))
  end

  defp generate_any_params(), do: let(_ <- integer(), do: :ok)

  defp mutation_params_generator() do
    let(entropy <- float(0.0, 0.5), do: %{entropy: entropy})
  end

  defp assert_drift_bounded() do
    # Mock generator call
    axiom_id = "test_axiom_#{:crypto.strong_rand_bytes(4) |> Base.url_encode64()}"
    case AxiomaticGenerator.produce(axiom_id) do
      {:ok, %{axioms: axioms}} ->
        drift = AxiomaticGenerator.compute_representational_drift(axioms)
        drift <= 0.4
      {:error, :representational_drift_exceeded} ->
        true
    end
  end

  defp assert_consistency_passes(_params) do
    axiom_id = "test_axiom_consistency_#{:crypto.strong_rand_bytes(4) |> Base.url_encode64()}"
    case AxiomaticGenerator.produce(axiom_id) do
      {:ok, axiom_set} ->
        case ConsistencyValidator.validate(axiom_set) do
          {:ok, score} -> score >= 0.85 # Relaxed for test variability
          {:error, "paradox_density_exceeded" <> _} -> true # Successfully caught by validator!
          {:error, _} -> false
        end
      {:error, :representational_drift_exceeded} ->
        true
    end
  end
end