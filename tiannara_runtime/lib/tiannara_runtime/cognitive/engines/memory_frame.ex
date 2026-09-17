defmodule TiannaraRuntime.Cognitive.Engines.MemoryFrame do
  @moduledoc "Phase 18.3 — Memory Frame"

  def create_frame(mission_id, owner, dependencies \\ []) do
    frame = %{
      frame_id: :erlang.unique_integer([:positive]),
      mission_id: mission_id,
      owner: owner,
      created_at: :erlang.unique_integer([:positive]),
      dependencies: dependencies,
      evidence_refs: [],
      replay_refs: [],
      archaeology_refs: [],
      expiration: :active,
      status: :active
    }
    {:ok, frame}
  end

  def add_evidence(frame, evidence_ref) do
    {:ok, %{frame | evidence_refs: frame.evidence_refs ++ [evidence_ref]}}
  end

  def add_replay(frame, replay_ref) do
    {:ok, %{frame | replay_refs: frame.replay_refs ++ [replay_ref]}}
  end

  def add_archaeology(frame, archaeology_ref) do
    {:ok, %{frame | archaeology_refs: frame.archaeology_refs ++ [archaeology_ref]}}
  end

  def expire(frame) do
    {:ok, %{frame | status: :expired}}
  end

  def get_fingerprint(frame) do
    canonical =
      frame
      |> Map.drop([:frame_id, :fingerprint])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end
end
