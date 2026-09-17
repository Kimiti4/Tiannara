defmodule Tiannara.Runtime.OED.Adversarial.CSI do
  @moduledoc """
  Phase 5F.8 — Compiler Suspicion Index (CSI)

  Calculates and explains how aware an observer is of the underlying reality compiler.
  """

  @doc """
  Generates suspicion profile explaining contribution of each metric factor.
  """
  def explain(metrics) do
    score = Map.get(metrics, :coordinated_resonance_behavior, 1.0)

    factors =
      Enum.map(metrics, fn {k, v} ->
        {k, %{contribution: v * 0.14}}
      end)
      |> Enum.into(%{})

    %{
      score: score,
      factors: factors
    }
  end
end
