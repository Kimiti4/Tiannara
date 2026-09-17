defmodule TiannaraRuntime.Civilization.Planning.PlanningReplay do
  def record(planner, objective_engine, horizon_planner) do
    planner_hash = planner |> :erlang.term_to_binary() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
    objective_hash = objective_engine |> :erlang.term_to_binary() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
    horizon_hash = horizon_planner |> :erlang.term_to_binary() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
    combined = planner_hash <> objective_hash <> horizon_hash
    overall = combined |> :erlang.term_to_binary() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
    replay = %{
      id: "replay_#{:erlang.unique_integer([:positive])}",
      planner_hash: planner_hash,
      objective_hash: objective_hash,
      horizon_hash: horizon_hash,
      overall_hash: overall
    }
    {:ok, replay}
  end

  def verify(replay, planner, objective_engine, horizon_planner) do
    {:ok, recorded} = record(planner, objective_engine, horizon_planner)
    if Map.get(recorded, :overall_hash) == Map.get(replay, :overall_hash) do
      {:ok, :verified}
    else
      {:error, :hash_mismatch}
    end
  end
end
