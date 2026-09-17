defmodule TiannaraRuntime.Civilization.Coordination.CoordinationReplay do
  def record(coordinator, collab_engine, dep_coordinator) do
    raw = inspect(coordinator) <> inspect(collab_engine) <> inspect(dep_coordinator)
    hash = :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower)
    {:ok, %{coordinator: coordinator, collab_engine: collab_engine, dep_coordinator: dep_coordinator, hash: hash}}
  end

  def verify(replay, coordinator, collab_engine, dep_coordinator) do
    raw = inspect(coordinator) <> inspect(collab_engine) <> inspect(dep_coordinator)
    hash = :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower)
    if hash == Map.get(replay, :hash) do
      {:ok, :verified}
    else
      {:error, :hash_mismatch}
    end
  end
end
