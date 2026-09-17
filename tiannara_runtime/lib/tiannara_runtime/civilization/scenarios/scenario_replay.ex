defmodule TiannaraRuntime.Civilization.Scenarios.ScenarioReplay do
  def record(engine, generator, comparator) do
    engine_hash = engine |> :erlang.term_to_binary() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
    generator_hash = generator |> :erlang.term_to_binary() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
    comparator_hash = comparator |> :erlang.term_to_binary() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
    combined = engine_hash <> generator_hash <> comparator_hash
    overall = combined |> :erlang.term_to_binary() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
    replay = %{
      id: "sreplay_#{:erlang.unique_integer([:positive])}",
      engine_hash: engine_hash,
      generator_hash: generator_hash,
      comparator_hash: comparator_hash,
      overall_hash: overall
    }
    {:ok, replay}
  end

  def verify(replay, engine, generator, comparator) do
    {:ok, recorded} = record(engine, generator, comparator)
    if Map.get(recorded, :overall_hash) == Map.get(replay, :overall_hash) do
      {:ok, :verified}
    else
      {:error, :hash_mismatch}
    end
  end
end
