defmodule TiannaraRuntime.Civilization.Portfolio.PortfolioReplay do
  def record(manager, registry, priority_engine) do
    raw = inspect(manager) <> inspect(registry) <> inspect(priority_engine)
    hash = :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower)
    {:ok, %{manager: manager, registry: registry, priority_engine: priority_engine, hash: hash}}
  end

  def verify(replay, manager, registry, priority_engine) do
    raw = inspect(manager) <> inspect(registry) <> inspect(priority_engine)
    hash = :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower)
    if hash == Map.get(replay, :hash) do
      {:ok, :verified}
    else
      {:error, :hash_mismatch}
    end
  end
end
