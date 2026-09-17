defmodule Tiannara.Sentinel.Validation.CertificationEngine do
  @moduledoc """
  Graduation authority. Promotes an observatory through :unproven -> :provisional -> :trusted.
  """

  def evaluate_promotion(reliability) do
    cond do
      reliability.evaluations >= 100 ->
        if meets_trust_criteria?(reliability) do
          %{reliability | status: :trusted}
        else
          %{reliability | status: :provisional}
        end

      reliability.evaluations >= 25 ->
        %{reliability | status: :provisional}

      true ->
        %{reliability | status: :unproven}
    end
  end

  defp meets_trust_criteria?(reliability) do
    reliability.accuracy > 0.75 and
    reliability.calibration_error < 0.20 and
    reliability.diversity_score > 0.15
  end
end
