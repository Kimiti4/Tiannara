defmodule Tiannara.Simulation.MultiWorld.WorldForker do
  alias Tiannara.Simulation.MultiWorld.Domain.WorldFork

  @spec fork(String.t(), String.t(), [map()], map()) :: WorldFork.t()
  def fork(baseline_snapshot_id, name, changes, parameters \\ %{}) do
    WorldFork.new(%{
      parent_snapshot_id: baseline_snapshot_id,
      name: name,
      description: "Fork '#{name}' from snapshot #{baseline_snapshot_id} with #{length(changes)} changes",
      divergence_point: DateTime.utc_now(),
      injected_changes: changes,
      parameters: parameters
    })
  end

  @spec fork_parallel(String.t(), String.t(), [map()], [map()]) :: [WorldFork.t()]
  def fork_parallel(baseline_snapshot_id, base_name, shared_changes, parameter_variants) do
    parameter_variants
    |> Enum.with_index()
    |> Enum.map(fn {params, idx} ->
      fork(
        baseline_snapshot_id,
        "#{base_name}_variant_#{idx}",
        shared_changes,
        params
      )
    end)
  end

  @spec fork_counterfactual(String.t(), String.t(), map()) :: WorldFork.t()
  def fork_counterfactual(baseline_snapshot_id, question, single_change) do
    WorldFork.new(%{
      parent_snapshot_id: baseline_snapshot_id,
      name: "Counterfactual: #{String.slice(question, 0, 60)}",
      description: "What if: #{question}",
      divergence_point: DateTime.utc_now(),
      injected_changes: [single_change],
      parameters: %{counterfactual: true, question: question}
    })
  end

  @spec validate(WorldFork.t()) :: :ok | {:error, term()}
  def validate(%WorldFork{} = fork) do
    cond do
      fork.parent_snapshot_id == nil -> {:error, :missing_parent_snapshot}
      fork.seed == nil -> {:error, :missing_seed}
      fork.injected_changes == [] and not Map.get(fork.parameters, :counterfactual, false) ->
        {:error, :no_changes_injected}
      true -> :ok
    end
  end
end
