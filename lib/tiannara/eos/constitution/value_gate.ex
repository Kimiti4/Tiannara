defmodule Tiannara.EOS.Constitution.ValueGate do
  @moduledoc """
  Constitutional Clause 21: autonomous actions must increase either knowledge
  quality, explanatory power, or verification confidence — and never merely
  increase artifact count.

  Sits on the publish path of all artifact-minting events.

  Constitutional mandate: "Never optimize for appearing correct. Optimize for
  being correct." / "Capability must never outpace verification."
  """

  @quality_metrics ~w(explanatory_power prediction_accuracy compression_efficiency
                      verification_confidence epistemic_debt_reduction)a

  @doc """
  Every minting event must declare which quality metric it improves
  and by what estimated margin. Count-based justifications are rejected
  structurally — there is no `artifact_count` metric.
  """
  def validate_mint(%{value_justification: justification}) do
    cond do
      is_nil(justification) ->
        {:error, :missing_value_justification}

      justification.metric not in @quality_metrics ->
        {:error, {:non_quality_metric, justification.metric}}

      justification.estimated_gain <= 0 ->
        {:error, :no_positive_quality_gain}

      true ->
        :ok
    end
  end
end
