defmodule TiannaraRuntime.Civilization.Portfolio.PriorityEngine do
  def initialize() do
    {:ok, %{priorities: [], criteria: %{}}}
  end

  def compute(engine, programs, metrics) do
    scored = Enum.map(programs, fn p ->
      const_priority = Map.get(p, :constitutional_priority, 0)
      dep_depth = Map.get(p, :dependency_depth, 0)
      ts = Map.get(p, :timestamp, 0)
      raw = Map.get(p, :id, "") <> inspect(const_priority) <> inspect(dep_depth) <> inspect(ts)
      fingerprint = :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower)
      {Map.get(p, :id), {const_priority, dep_depth, ts, fingerprint}}
    end)
    ordered = Enum.sort(scored, fn {_id1, {cp1, dd1, ts1, _fp1}}, {_id2, {cp2, dd2, ts2, _fp2}} ->
      cond do
        cp1 != cp2 -> cp1 >= cp2
        dd1 != dd2 -> dd1 >= dd2
        ts1 != ts2 -> ts1 >= ts2
        true -> true
      end
    end)
    ordered_ids = Enum.map(ordered, fn {id, _} -> id end)
    {:ok, %{engine | priorities: ordered_ids}}
  end

  def get_priority(engine, program_id) do
    idx = Enum.find_index(engine.priorities, fn id -> id == program_id end)
    case idx do
      nil -> {:error, :not_found}
      i -> {:ok, i + 1}
    end
  end

  def metrics(engine) do
    top = List.first(engine.priorities)
    {:ok, %{total: length(engine.priorities), top_priority: top}}
  end
end
