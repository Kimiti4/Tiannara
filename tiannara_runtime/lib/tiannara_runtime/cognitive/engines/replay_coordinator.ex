defmodule TiannaraRuntime.Cognitive.Engines.ReplayCoordinator do
  @moduledoc "Phase 18.2 — Replay recording and verification engine"

  alias TiannaraRuntime.Cognitive.{ReplayReference, CognitiveSerializer}

  def record(mission_id, fingerprint) do
    {:ok, ref} = ReplayReference.new(%{
      root: mission_id,
      sequence: :erlang.unique_integer([:positive]),
      hash: fingerprint
    })
    {:ok, ref}
  end

  def record_execution(mission_id, task, exec_result) do
    combined = CognitiveSerializer.serialize(task) <> CognitiveSerializer.serialize(exec_result)
    hash = :crypto.hash(:sha256, combined) |> Base.encode16(case: :lower)
    {:ok, ref} = ReplayReference.new(%{
      root: mission_id,
      sequence: :erlang.unique_integer([:positive]),
      hash: hash
    })
    {:ok, ref}
  end

  def reconstruct(replay_reference) do
    {:ok, replay_reference}
  end

  def verify(replay_reference, artifact) do
    artifact_hash =
      case artifact do
        %{fingerprint: fp} -> fp
        %{hash: h} -> h
        _ -> CognitiveSerializer.stable_hash(artifact)
      end
    if artifact_hash == replay_reference.hash do
      {:ok, :verified}
    else
      {:error, :hash_mismatch}
    end
  end
end
