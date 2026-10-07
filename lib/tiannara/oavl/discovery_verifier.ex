defmodule Tiannara.OAVL.DiscoveryVerifier do
  @moduledoc """
  Ontological Adversarial Validation Layer boundary for discovery candidates.

  OAVL never manufactures a stability/confidence value. A candidate is only
  admitted when structural evidence and validation probes are available.
  """

  require Logger

  @spec evaluate(map()) :: {:ok, map()} | {:error, term()}
  def evaluate(discovery) when is_map(discovery) do
    with :ok <- require_identity(discovery),
         :ok <- require_evidence(discovery),
         {:ok, result} <- run_structural_validation(discovery) do
      {:ok, Map.put(discovery, :oavl, result)}
    end
  end

  def evaluate(_), do: {:error, :invalid_discovery_candidate}

  defp require_identity(discovery) do
    if is_binary(Map.get(discovery, :id)) and is_binary(Map.get(discovery, :name)) and not is_nil(Map.get(discovery, :domain)),
      do: :ok,
      else: {:error, :missing_discovery_identity}
  end

  defp require_evidence(discovery) do
    evidence = Map.get(discovery, :evidence, Map.get(discovery, :evidence_ids, []))
    if is_list(evidence) and evidence != [], do: :ok, else: {:error, :missing_structural_evidence}
  end

  defp run_structural_validation(_discovery) do
    Logger.warning("[OAVL] Structural discovery validation provider is unavailable; candidate remains unvalidated")
    {:error, :oavl_validation_provider_unavailable}
  end
end
