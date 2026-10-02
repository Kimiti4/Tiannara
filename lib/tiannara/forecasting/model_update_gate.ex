defmodule Tiannara.Forecasting.ModelUpdateGate do
  @moduledoc """
  Non-authorizing gate for forecasting model-improvement candidates.

  This module can assemble and validate an evidence packet. It cannot promote,
  deploy, authorize, or mutate a forecasting model.

  A candidate is admissible only when the caller supplies independent evidence
  for temporal performance, calibration, drift/model risk and holdout behavior.
  Missing or ambiguous evidence remains UNKNOWN rather than becoming PASS.
  """

  @required [:candidate_id, :current_model_ref, :proposed_model_ref,
             :temporal_evaluation, :calibration, :drift, :holdout,
             :uncertainty, :multiple_testing]

  @spec assess(map()) :: {:ok, map()} | {:error, term()}
  def assess(packet) when is_map(packet) do
    with :ok <- required_fields(packet),
         :ok <- validate_temporal(packet.temporal_evaluation),
         :ok <- validate_holdout(packet.holdout),
         :ok <- validate_non_certifying_analytics(packet),
         {:ok, disposition} <- disposition(packet) do
      {:ok, %{
        evidence_packet_id: packet.candidate_id,
        current_model_ref: packet.current_model_ref,
        proposed_model_ref: packet.proposed_model_ref,
        disposition: disposition,
        authority: :none,
        authorization: :not_granted,
        deployment: :not_granted,
        production_mutation: :forbidden,
        human_review_required: true,
        acl_required: true,
        oavl_required: true,
        cel_required: true,
        evidence: packet,
        certification_eligible: false
      }}
    end
  end

  def assess(_), do: {:error, :invalid_model_update_packet}

  defp required_fields(packet) do
    case Enum.find(@required, &(not Map.has_key?(packet, &1))) do
      nil -> :ok
      field -> {:error, {:missing_evidence, field}}
    end
  end

  defp validate_temporal(%{holdout_locked: true, holdout_used_for_selection: false}), do: :ok
  defp validate_temporal(_), do: {:error, :temporal_holdout_not_locked}

  defp validate_holdout(%{certification_eligible: false}), do: :ok
  defp validate_holdout(_), do: {:error, :holdout_must_not_self_certify}

  defp validate_non_certifying_analytics(packet) do
    analytics = [:calibration, :drift, :uncertainty, :multiple_testing]

    if Enum.all?(analytics, fn key -> Map.get(packet, key) |> non_certifying? end) do
      :ok
    else
      {:error, :analytics_self_certification_detected}
    end
  end

  defp non_certifying?(%{certification_eligible: false}), do: true
  defp non_certifying?(_), do: false

  defp disposition(packet) do
    holdout = Map.get(packet.holdout, :status)
    temporal = Map.get(packet.temporal_evaluation, :selection_window, %{}) |> Map.get(:status)
    cond do
      holdout != :measured -> {:ok, :insufficient_or_unproven}
      temporal != :measured -> {:ok, :insufficient_or_unproven}
      true -> {:ok, :candidate_for_independent_review}
    end
  end
end
