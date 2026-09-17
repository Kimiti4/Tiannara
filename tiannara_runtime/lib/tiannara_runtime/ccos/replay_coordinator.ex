defmodule TiannaraRuntime.CCOS.ReplayCoordinator do
  @moduledoc """
  Phase 18.2 Replay Coordinator.

  Builds replay roots from immutable evidence artifacts.
  """

  alias TiannaraRuntime.CCOS.Artifact

  @spec build([map()]) :: {:ok, map()} | {:error, String.t()}
  def build(evidence_chain) when is_list(evidence_chain) do
    with :ok <- require_evidence_ids(evidence_chain) do
      replay = %{
        evidence_ids: Enum.map(evidence_chain, &Map.fetch!(&1, :evidence_id)),
        evidence_hashes: Enum.map(evidence_chain, &Artifact.fingerprint/1)
      }

      {:ok, Map.put(replay, :replay_root_id, Artifact.content_id("cckreplay", replay))}
    end
  end

  def build(_evidence_chain),
    do: {:error, "ReplayCoordinator.build requires an evidence chain list"}

  defp require_evidence_ids(evidence_chain) do
    if Enum.all?(evidence_chain, &Map.has_key?(&1, :evidence_id)) do
      :ok
    else
      {:error, "all evidence artifacts must contain evidence_id"}
    end
  end
end
