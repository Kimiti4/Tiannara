defmodule TiannaraRuntime.CCOS.EvidenceCollector do
  @moduledoc """
  Phase 18.2 Evidence Collector.

  Converts observable orchestration transitions into evidence artifacts. It does
  not fabricate subsystem outputs.
  """

  alias TiannaraRuntime.CCOS.Artifact

  @spec collect_transition(atom(), map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def collect_transition(stage, payload, replay_timestamp)
      when is_atom(stage) and is_map(payload) and is_binary(replay_timestamp) do
    evidence = %{
      stage: stage,
      payload_ref: Artifact.fingerprint(payload),
      payload: payload,
      replay_timestamp: replay_timestamp
    }

    {:ok, Map.put(evidence, :evidence_id, Artifact.content_id("cckevidence", evidence))}
  end

  def collect_transition(_stage, _payload, _replay_timestamp),
    do: {:error, "EvidenceCollector.collect_transition requires stage, payload, and replay timestamp"}
end
