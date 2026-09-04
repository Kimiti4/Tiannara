defmodule Tiannara.Bench.QueryLatency do
  use Benchee.Formatters.Console
  import Tiannara.Test.Phase3Helpers

  def run do
    entities = build_and_insert(500)

    Benchee.run(
      %{
        "get entity by ID" => fn {entities, _} ->
          Enum.each(entities, fn e ->
            Tiannara.World.UnifiedWorldModel.get_entity(e.id)
          end)
        end,
        "get dependency graph" => fn {entities, _} ->
          Enum.each(entities, fn e ->
            Tiannara.World.UnifiedWorldModel.get_dependency_graph(e.id)
          end)
        end
      },
      inputs: %{"500 entities" => {entities, :ok}},
      time: 5,
      warmup: 2
    )
  end

  defp build_and_insert(count) do
    Enum.map(1..count, fn i ->
      spec = build_entity_spec(:bench, :fact, :latency, %{index: i},
        id: "latency_entity_#{i}", confidence: 0.5)
      {:ok, id} = Tiannara.World.UnifiedWorldModel.create_entity(spec)
      %{id: id}
    end)
  end
end
