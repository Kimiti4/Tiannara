defmodule Tiannara.Forecasting.Counterforecast do
  @moduledoc """
  Adversarial forecast generation.

  This module creates explicit alternative hypotheses and does not decide which
  hypothesis is true. It is intended to force model-risk examination.
  """

  def build(primary, alternatives) when is_map(primary) and is_list(alternatives) do
    {:ok, %{
      primary: primary,
      alternatives: Enum.map(alternatives, &normalize/1),
      required_tests: [:disconfirming_evidence, :baseline_comparison,
                        :temporal_leakage_check, :regime_sensitivity],
      status: :adversarial_review_required
    }}
  end

  defp normalize(candidate) when is_map(candidate),
    do: Map.put_new(candidate, :role, :counterforecast)
  defp normalize(candidate), do: %{candidate: candidate, role: :counterforecast}
end
