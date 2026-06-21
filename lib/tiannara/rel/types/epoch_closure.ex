defmodule Tiannara.REL.Types.EpochClosure do
  @moduledoc """
  Canonical event emitted at extinction. Single source of truth for SEA, LEOC, ECL, Sentinel.
  """
  
  @type collapse_signature :: :resource_exhaustion | :ontological_drift | :synchronization_failure | 
                              :competitive_displacement | :maintenance_cascade | :unknown

  @type t :: %__MODULE__{
    civ_id: String.t(),
    shard_id: String.t(),
    final_genome: map(),
    final_budget: map(),
    truth_capital: float(),
    influence_capital: float(),
    fitness_score: float(),
    continuity_score: float(),
    discoveries: [String.t()],
    relic_discoveries: [String.t()],
    collapse_signature: collapse_signature(),
    lineage_path: [String.t()],
    epoch_duration: integer(),
    generation_count: integer(),
    diseases: [String.t()],
    operators: [String.t()],
    compressed_to_latent: boolean(),
    timestamp: integer()
  }

  @enforce_keys [:civ_id, :shard_id, :final_fitness, :collapse_signature]
  defstruct [
    :civ_id, :shard_id, :final_genome, :final_budget,
    :truth_capital, :influence_capital, :fitness_score, :continuity_score,
    :discoveries, :relic_discoveries, :collapse_signature,
    :lineage_path, :epoch_duration, :generation_count, :diseases, :operators,
    :compressed_to_latent, :timestamp,
    # Kept for backward compatibility during refactor, mapped to fitness_score
    :final_fitness 
  ]

  @spec from_civilization(map(), map()) :: t()
  def from_civilization(civ_state, context) do
    fitness = Map.get(context, :fitness_score, 0.0)
    %__MODULE__{
      civ_id: civ_state.id,
      shard_id: civ_state.shard_id,
      final_genome: context.identity_seed,
      final_budget: Map.get(civ_state, :resource_budget, %{}),
      truth_capital: Map.get(context, :truth_capital, 0.0),
      influence_capital: Map.get(context, :influence_capital, 0.0),
      fitness_score: fitness,
      final_fitness: fitness,
      continuity_score: Map.get(context, :continuity_score, 0.0),
      discoveries: Map.get(civ_state, :discovery_portfolio, []),
      relic_discoveries: Map.get(context, :relic_discoveries, []),
      collapse_signature: classify_collapse(civ_state, context),
      lineage_path: Map.get(civ_state, :lineage, []),
      epoch_duration: Map.get(context, :epoch_duration, 0),
      generation_count: Map.get(context, :generation_count, 0),
      diseases: Map.get(context, :diseases, []),
      operators: Map.get(context, :operators, []),
      compressed_to_latent: false,
      timestamp: System.system_time(:millisecond)
    }
  end

  defp classify_collapse(civ, ctx) do
    budget = Map.get(civ, :resource_budget, %{energy: 0})
    cond do
      budget.energy <= 0 and Map.get(ctx, :maintenance_drain, 0) > 0 -> :resource_exhaustion
      Map.get(ctx, :ontology_drift, 0) > Map.get(ctx, :drift_threshold, 100) -> :ontological_drift
      Map.get(ctx, :sync_failures, 0) > 5 -> :synchronization_failure
      Map.get(civ, :fitness_score, 0.0) < 0.2 and Map.get(ctx, :competitive_pressure, 0.0) > 0.8 -> :competitive_displacement
      true -> :maintenance_cascade
    end
  end
end
