defmodule TiannaraRuntime.Cognitive.Planning.PlanReplay do
  alias TiannaraRuntime.Cognitive.Planning.PlanningReplay

  def record(session, artifacts) do
    hashes =
      artifacts
      |> Enum.map(fn {key, val} -> {key, hash_artifact(val)} end)
      |> Enum.into(%{})
    replay = %PlanningReplay{
      id: "pr_#{session.session_id || session.id}",
      session_id: session.session_id || session.id,
      root: artifacts,
      sequence: [],
      hashes: hashes,
      fingerprint: "fp_replay_#{session.session_id || session.id}",
      schema_version: 1,
      ontology_version: 1,
      created_with_phase: "18.5",
      migration_version: 0
    }
    {:ok, replay}
  end

  def verify_replay(replay, artifacts) do
    mismatch =
      Enum.find_value(artifacts, fn {key, val} ->
        expected = Map.get(replay.hashes, key)
        actual = hash_artifact(val)
        if expected != actual, do: {key, expected, actual}
      end)
    if is_nil(mismatch), do: {:ok, :verified}, else: {:error, :hash_mismatch}
  end

  defp hash_artifact(value) do
    :crypto.hash(:sha256, inspect(value)) |> Base.encode16(case: :lower)
  end
end
