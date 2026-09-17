defmodule TiannaraRuntime.Cognitive.Engines.ContextReplay do
  @moduledoc "Phase 18.3 — Context Replay"

  def record(state, context_snapshot) do
    replay_record = %{
      replay_id: :erlang.unique_integer([:positive]),
      snapshot_id: context_snapshot.fingerprint,
      state: state,
      recorded_at: :erlang.unique_integer([:positive])
    }
    {:ok, replay_record}
  end

  def reconstruct(replay_record) do
    {:ok, replay_record.snapshot_id}
  end

  def verify_state(state, expected_fingerprint) do
    canonical =
      state
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    actual = :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
    if actual == expected_fingerprint do
      {:ok, :verified}
    else
      {:error, :hash_mismatch}
    end
  end
end
