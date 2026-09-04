defmodule Tiannara.Bench.MutationThroughput do
  use Benchee.Formatters.Console
  import Tiannara.Test.Phase3Helpers

  def run do
    entity = insert_base()

    Benchee.run(
      %{
        "update entity" => fn %{id: eid} ->
          Tiannara.World.UnifiedWorldModel.update_entity(eid, %{
            bench_timestamp: System.system_time(:millisecond),
            updated_at: DateTime.utc_now()
          })
        end,
        "transition stage" => fn %{id: eid} ->
          Tiannara.World.UnifiedWorldModel.transition_stage(eid, :information)
          Tiannara.World.UnifiedWorldModel.transition_stage(eid, :data)
        end
      },
      inputs: %{"single entity" => entity},
      time: 5,
      warmup: 2
    )
  end

  defp insert_base do
    spec = build_entity_spec(:bench, :experiment, :throughput, %{}, id: "mutation_base", confidence: 0.5)
    {:ok, id} = Tiannara.World.UnifiedWorldModel.create_entity(spec)
    %{id: id}
  end
end
