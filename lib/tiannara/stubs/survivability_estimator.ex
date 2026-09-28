defmodule Tiannara.Twp.SurvivabilityEstimator do
  @moduledoc "Bounded survivability estimator based on explicit branch-state evidence."

  def estimate(state) when is_map(state) do
    entropy = number(state, :entropy, 0.0)
    coherence = number(state, :coherence, 1.0)
    stress = number(state, :stress, 0.0)
    score = (0.45 * clamp(coherence) + 0.35 * (1.0 - clamp(entropy)) + 0.20 * (1.0 - clamp(stress)))
    {:ok, %{score: Float.round(clamp(score), 6), evidence: [:coherence, :entropy, :stress]}}
  end
  def estimate(_), do: {:error, :insufficient_branch_state}

  defp number(map, key, default) do
    case Map.get(map, key, default) do
      x when is_number(x) -> x
      _ -> default
    end
  end
  defp clamp(x), do: x |> max(0.0) |> min(1.0)
end
