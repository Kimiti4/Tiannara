defmodule TiannaraRuntime.Cognitive.Engines.AttentionCoordinator do
  @moduledoc "Phase 18.2 — Deterministic attention allocation engine"

  alias TiannaraRuntime.Cognitive.{AttentionState, CognitiveSerializer}

  def allocate(tasks, priorities, working_memory) do
    tasks_with_order = Enum.map(tasks, fn t ->
      {t, :erlang.unique_integer([:positive])}
    end)
    sorted = Enum.sort_by(tasks_with_order, fn {t, order} ->
      {
        -Map.get(t, :priority, 0),
        length(Map.get(t, :dependencies, [])),
        order,
        CognitiveSerializer.stable_hash(t)
      }
    end)
    allocation = sorted |> Enum.with_index() |> Map.new(fn {{t, _}, idx} -> {idx, t} end)
    {:ok, attention} = AttentionState.new(%{
      allocation: allocation,
      priority_queue: Enum.map(sorted, fn {t, _} -> t end),
      resource_usage: working_memory,
      constraints: []
    })
    {:ok, attention}
  end

  def get_allocation(attention_state) do
    {:ok, attention_state.allocation}
  end
end
