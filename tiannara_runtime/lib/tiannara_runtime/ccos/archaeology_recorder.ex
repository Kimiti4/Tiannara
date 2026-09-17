defmodule TiannaraRuntime.CCOS.ArchaeologyRecorder do
  @moduledoc """
  Phase 18.2 Archaeology Recorder.

  Captures mission, task, dispatch, evidence, and replay lineage from supplied
  artifacts.
  """

  alias TiannaraRuntime.CCOS.Artifact

  @spec record(map()) :: {:ok, map()} | {:error, String.t()}
  def record(lineage) when is_map(lineage) do
    with {:ok, mission_state} <- Artifact.require_map(lineage, :mission_state),
         {:ok, dispatch_root} <- Artifact.require_map(lineage, :dispatch_root),
         {:ok, evidence_chain} <- Artifact.require_list(lineage, :evidence_chain),
         {:ok, replay_root} <- Artifact.require_map(lineage, :replay_root) do
      archaeology = %{
        mission_ref: Artifact.fingerprint(mission_state),
        dispatch_ref: Artifact.fingerprint(dispatch_root),
        evidence_refs: Enum.map(evidence_chain, &Artifact.fingerprint/1),
        replay_ref: Artifact.fingerprint(replay_root)
      }

      {:ok, Map.put(archaeology, :archaeology_id, Artifact.content_id("cckarch", archaeology))}
    end
  end

  def record(_lineage),
    do: {:error, "ArchaeologyRecorder.record requires a lineage map"}
end
