defmodule TiannaraRuntime.Cognitive.Planning.AlternativeGenerator do
  alias TiannaraRuntime.Cognitive.Planning.Alternative

  defp make_alt(plan_id, desc, task_graph, score) do
    %Alternative{
      id: "alt_#{plan_id}_#{desc}",
      plan_id: plan_id,
      description: desc,
      task_graph: task_graph,
      constraints: %{},
      score: score,
      fingerprint: "fp_alt_#{plan_id}_#{desc}",
      schema_version: 1,
      ontology_version: 1,
      created_with_phase: "18.5",
      migration_version: 0
    }
  end

  def generate(task_graph) do
    plans = Map.get(task_graph, :plans, ["approach_a", "approach_b", "approach_c"])
    plan_id = Map.get(task_graph, :plan_id, "plan_1")
    alternatives =
      Enum.with_index(plans, fn desc, idx ->
        score = rem(:erlang.unique_integer([:positive]), 100) / 100.0 * (1.0 - idx * 0.1)
        make_alt(plan_id, desc, task_graph, max(0.0, score))
      end)
    {:ok, alternatives}
  end
end
