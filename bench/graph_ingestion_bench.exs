defmodule Tiannara.Bench.GraphIngestion do
  use Benchee.Formatters.Console
  import Tiannara.Test.Phase3Helpers

  def run do
    Benchee.run(
      %{
        "create 100 entities" => fn {entity_specs, _} ->
          Enum.each(entity_specs, fn spec ->
            Tiannara.World.UnifiedWorldModel.create_entity(spec)
          end)
        end,
        "create 1000 entities" => fn {entity_specs, _} ->
          Enum.each(entity_specs, fn spec ->
            Tiannara.World.UnifiedWorldModel.create_entity(spec)
          end)
        end
      },
      inputs: %{
        "100 entities" => {build_entity_specs(100), :ok},
        "1000 entities" => {build_entity_specs(1000), :ok}
      },
      time: 5,
      warmup: 2
    )
  end

  defp build_entity_specs(count) do
    Enum.map(1..count, fn i ->
      build_entity_spec(:bench, :fact, :data, %{index: i},
        id: "bench_entity_#{i}", confidence: 0.5)
    end)
  end
end
