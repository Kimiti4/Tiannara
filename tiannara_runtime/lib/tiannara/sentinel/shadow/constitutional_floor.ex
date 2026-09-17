defmodule Tiannara.Sentinel.Shadow.ConstitutionalFloor do
  @moduledoc """
  Centralizes constitutional policy for grading interventions.
  """

  @doc """
  Classifies a constitutional fitness score into a recommendation class.
  Classes:
    >= 0.85 -> :strong
    >= 0.70 -> :recommended
    >= 0.55 -> :weak
    >= 0.40 -> :high_risk
    < 0.40  -> :observation_only
  """
  def classify(fitness_score) do
    cond do
      fitness_score >= 0.85 -> :strong
      fitness_score >= 0.70 -> :recommended
      fitness_score >= 0.55 -> :weak
      fitness_score >= 0.40 -> :high_risk
      true -> :observation_only
    end
  end
end
