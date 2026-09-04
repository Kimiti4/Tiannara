defmodule Tiannara.MetaCognition do
  @moduledoc """
  Phase 10: Evolutionary Meta-Cognition.
  
  Observes the evolving reasoning ecosystem (D.2) and proposes
  candidate evolutionary leaps (epistemologies). It does NOT force adoption,
  but rather proposes new variants to be spawned into the ecology.
  """
  
  alias Tiannara.Sentinel.D2.{SpeciesAtlas, OperatorEcology}
  alias Tiannara.EDM.DiseaseEngine

  defstruct [
    :last_consultation,
    :d2_snapshot,
    :pipeline_telemetry
  ]

  @doc "Initialize evolutionary meta-cognition."
  def new do
    %__MODULE__{
      last_consultation: nil,
      d2_snapshot: %{},
      pipeline_telemetry: %{}
    }
  end

  @doc """
  Queries D.2 telemetry to inform evolutionary proposals.
  We do not store the ecology, we just read the fitness landscape.
  """
  def consult_ecology(meta_cog, d2_analytics) do
    %{meta_cog | 
      last_consultation: DateTime.utc_now(),
      d2_snapshot: d2_analytics
    }
  end

  @doc """
  Observes deep pipeline telemetry (from REG, TCL, REA, RRM) 
  to detect runtime instability and guide epistemic evolution.
  """
  def observe_pipeline(meta_cog, pipeline_metrics) do
    %{meta_cog | pipeline_telemetry: pipeline_metrics}
  end

  @doc """
  Generates candidate epistemologies (operator sets) for a given species
  based on the current D.2 fitness landscape and deep pipeline stability.
  """
  def generate_candidate_epistemologies(meta_cog, species_operators, d2_analytics) do
    candidates = [
      {:pruning, apply_pruning(species_operators, d2_analytics)},
      {:hybridization, apply_hybridization(species_operators, d2_analytics)},
      {:mutation, apply_mutation(species_operators, d2_analytics)},
      {:synthesis, apply_synthesis(d2_analytics)},
      {:migration, apply_migration(species_operators, d2_analytics)},
      {:stabilization, apply_stabilization(species_operators, meta_cog.pipeline_telemetry)}
    ]
    
    # Filter out empty or unchanged candidates, then evaluate fitness
    candidates
    |> Enum.filter(fn {_, ops} -> length(ops) > 0 and ops != species_operators end)
    |> Enum.map(fn {strategy, ops} -> 
      {strategy, Enum.uniq(ops)}
    end)
    |> evaluate_candidate_fitness()
  end

  # --- Strategies ---

  defp apply_pruning(operators, d2) do
    ecology = Map.get(d2, :ecology, %OperatorEcology{})
    antagonisms = Map.get(ecology, :antagonisms, %{})
    
    # Remove operators that have high antagonistic relationships
    Enum.reject(operators, fn op ->
      Map.has_key?(antagonisms, op) and antagonisms[op] < -0.5
    end)
  end

  defp apply_hybridization(operators, d2) do
    atlas = Map.get(d2, :atlas, %SpeciesAtlas{})
    # Find a highly successful dominant species to hybridize with
    case List.first(atlas.dominant_species) do
      nil -> operators
      dominant -> 
        # Take half of our operators, half of theirs
        half_ours = Enum.take_random(operators, max(1, div(length(operators), 2)))
        half_theirs = Enum.take_random(dominant.operators, max(1, div(length(dominant.operators), 2)))
        half_ours ++ half_theirs
    end
  end

  defp apply_mutation(operators, d2) do
    unknowns = Map.get(d2, :unknowns, [])
    # Add a high-priority operator from the unknown region
    case Enum.sort_by(unknowns, & &1.exploration_priority, :desc) |> List.first() do
      nil -> operators
      unknown_region -> 
        new_op = Enum.random(unknown_region.operator_combination)
        operators ++ [new_op]
    end
  end

  defp apply_synthesis(d2) do
    topology = Map.get(d2, :landscape_topology, %{})
    gradient = Map.get(topology, :fitness_gradient, %{})
    
    # Assemble entirely from positive gradient operators
    positive_ops = Enum.filter(gradient, fn {_op, score} -> score > 0.0 end) |> Enum.map(fn {op, _} -> op end)
    
    if length(positive_ops) > 0 do
      Enum.take_random(positive_ops, 3)
    else
      ["empirical", "causal"] # fallback
    end
  end

  defp apply_migration(operators, d2) do
    atlas = Map.get(d2, :atlas, %SpeciesAtlas{})
    # Horizontal transfer: entirely adopt a niche specialist's operators
    case List.first(atlas.niche_specialists) do
      nil -> operators
      specialist -> specialist.operators
    end
  end

  defp apply_stabilization(operators, telemetry) do
    # If the deep pipeline is throwing instability (drift > 0.5 or resonance conflicts),
    # propose a shift to logic/causal operators to stabilize the species.
    drift = Map.get(telemetry, :drift_variance, 0.0)
    conflicts = Map.get(telemetry, :arbitration_conflicts, 0)
    
    if drift > 0.5 or conflicts > 5 do
      # Merge in stabilizing operators
      Enum.uniq(operators ++ ["logic", "causal", "temporal"])
    else
      operators
    end
  end

  # --- ESG Shadow Validation ---

  defp evaluate_candidate_fitness(candidates) do
    # Reject structurally impossible paths via EDM precheck
    Enum.filter(candidates, fn {_strategy, ops} -> 
      DiseaseEngine.precheck(ops) == :ok
    end)
    # Further probabilistic scoring could happen here.
    # For now, if it passes precheck, we return it as a viable proposal.
  end

  def consult_world_model(_query, _opts), do: {:ok, :stub}
end
