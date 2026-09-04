defmodule Tiannara.Discovery.Validation.ReplicationPlanner do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Validation.Domain.ReplicationPlan

  @min_replications 2

  @spec plan(Discovery.t()) :: ReplicationPlan.t()
  def plan(%Discovery{} = disc) do
    original_experiments = disc.experiments

    replication_experiments =
      original_experiments
      |> Enum.take(3)
      |> Enum.with_index()
      |> Enum.flat_map(fn {exp, idx} ->
        generate_replications(exp, idx)
      end)

    ReplicationPlan.new(%{
      discovery_id: disc.id,
      original_experiment_ids: Enum.map(original_experiments, & &1.id),
      replication_experiments: replication_experiments,
      independence_criteria: build_independence_criteria(),
      success_criteria: build_success_criteria(disc),
      status: :planned
    })
  end

  @spec sufficiently_replicated?(Discovery.t()) :: boolean()
  def sufficiently_replicated?(%Discovery{} = disc) do
    replication_evidence = Enum.filter(disc.evidence, fn result ->
      Enum.any?(result.evidence, fn ev -> Map.get(ev, :type) == :replication end)
    end)
    length(replication_evidence) >= @min_replications
  end

  defp generate_replications(exp, idx) do
    [
      %{
        id: "repl_#{exp.id}_method_#{idx}",
        original_experiment_id: exp.id,
        type: :methodological_replication,
        description: "Replicate #{exp.id} using a different methodology",
        methodology_change: select_alternative_methodology(exp.type),
        independence: :methodology,
        success_criteria: "Result consistent with original within 20% tolerance"
      },
      %{
        id: "repl_#{exp.id}_data_#{idx}",
        original_experiment_id: exp.id,
        type: :data_replication,
        description: "Replicate #{exp.id} using independent data sources",
        data_source_change: :independent_source,
        independence: :data,
        success_criteria: "Result directionally consistent with original"
      }
    ]
  end

  defp select_alternative_methodology(:controlled_simulation), do: :observation
  defp select_alternative_methodology(:observation), do: :controlled_simulation
  defp select_alternative_methodology(:historical_replay), do: :data_mining
  defp select_alternative_methodology(:data_mining), do: :historical_replay
  defp select_alternative_methodology(_), do: :controlled_simulation

  defp build_independence_criteria do
    [
      "Different methodology from original experiment",
      "Independent data source or collection method",
      "Different analyst or analysis approach",
      "No shared assumptions with original experiment",
      "Blind to original results where possible"
    ]
  end

  defp build_success_criteria(%Discovery{} = disc) do
    [
      "At least #{@min_replications} independent replications completed",
      "Replication results directionally consistent with original",
      "Effect size within 30% of original estimate",
      "No systematic bias detected between original and replications",
      "Combined confidence across replications > #{Float.round(disc.confidence * 0.8, 2)}"
    ]
  end
end
