defmodule Tiannara.Sentinel.Validation.CertificationEngine do
  @moduledoc """
  Graduation authority. Promotes an observatory through :unproven -> :provisional -> :trusted.
  """

  def evaluate_promotion(reliability, evidence \\ %{}) do
    with :ok <- validate_lineage(evidence) do
      do_evaluate_promotion(reliability)
    end
  end

  defp do_evaluate_promotion(reliability) do
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

  defp validate_lineage(%{lineage: %{graph_id: graph_id, archive_hash: archive_hash}}) do
    with :ok <- Tiannara.Sentinel.DiscoveryVerificationGraph.verify_chain(),
         :ok <- Tiannara.Sentinel.DiscoveryEvidenceArchive.verify(archive_hash),
         {:ok, graph} <- Tiannara.Sentinel.DiscoveryVerificationGraph.get(graph_id),
         true <- Map.get(graph, :reliability_id) != nil do
      :ok
    else
      _ -> {:error, :promotion_requires_verified_lineage}
    end
  end

  defp validate_lineage(_), do: {:error, :promotion_requires_verified_lineage}

  defp meets_trust_criteria?(reliability) do
    reliability.accuracy > 0.75 and
    reliability.calibration_error < 0.20 and
    reliability.diversity_score > 0.15
  end
end
