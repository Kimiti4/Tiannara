defmodule Tiannara.Sentinel.Shadow.TrajectoryRanker do
  @moduledoc """
  Ranks candidate actions based on the aggregate fitness of their simulated futures.
  Outputs the comparative %ShadowResult{}.
  """
  use GenServer

  alias Tiannara.Sentinel.Contracts.ShadowResult
  alias Tiannara.Sentinel.Shadow.OutcomeDistribution
  alias Tiannara.Sentinel.Shadow.ConstitutionalFloor
  alias Tiannara.Sentinel.Immune.RecommendationEngine
  alias Tiannara.Sentinel.Shadow.ShadowCleanup

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def rank_actions(seed, evaluated_set) do
    GenServer.cast(__MODULE__, {:rank, seed, evaluated_set})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:rank, seed, evaluated_set}, state) do
    # Calculate average probability of success and fitness per action
    ranked = 
      evaluated_set
      |> Enum.map(fn action_set ->
        avg_fitness = 
          Enum.map(action_set.trajectories, & &1.fitness.total) 
          |> Enum.sum() 
          |> Kernel./(max(length(action_set.trajectories), 1))
          
        # Calculate probability of success using ConfidenceFusion
        base_confidence = min(avg_fitness * 1.1, 1.0)
        prob_success = Tiannara.Sentinel.Shadow.ConfidenceFusion.fuse_confidence(base_confidence)
        
        %{
          action: action_set.action,
          probability_of_success: prob_success,
          constitutional_fitness: avg_fitness,
          distribution: OutcomeDistribution.aggregate(action_set.trajectories)
        }
      end)
      |> Enum.sort_by(& &1.constitutional_fitness, :desc)

    best_candidate = hd(ranked)
    
    shadow_result = %ShadowResult{
      preferred_action: best_candidate.action,
      ranked_actions: ranked,
      recommendation_class: ConstitutionalFloor.classify(best_candidate.constitutional_fitness),
      outcome_distribution: best_candidate.distribution
    }

    # Attach result back to the Intervention, updating the action to the preferred one
    updated_intervention = %{seed.recommendation | 
      action: shadow_result.preferred_action,
      shadow_result: shadow_result
    }

    # Notify RecommendationEngine that simulation is complete
    RecommendationEngine.finalize_recommendation(updated_intervention)

    # Trigger cleanup
    ShadowCleanup.destroy_sandbox(seed)

    {:noreply, state}
  end
end
