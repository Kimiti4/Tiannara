defmodule Tiannara.MCALv2.SurvivalEvaluator do
  @moduledoc """
  MCAL v2: Survival Evaluator.
  
  Evaluates identity fitness across worlds using simulated CIS signals 
  to determine survival robustness.
  """
  
  require Logger

  @doc """
  Scores an identity's fitness based on how its cognitive policy and causal bias
  handle the current environmental stress.
  """
  def evaluate(identity, environment_stress) do
    Logger.debug("⚖️ [MCAL v2 Evaluator] Scoring fitness for identity #{identity.id} under stress #{inspect(environment_stress)}")
    
    # Base fitness
    base = 50.0
    
    # Evaluate policy match to stress
    policy_score = case {identity.cognitive_policy, environment_stress} do
      {:collapse_adaptive, :high_stress} -> 30.0
      {:exploration, :monoculture} -> 30.0
      {:stabilization, :stable} -> 20.0
      _ -> -10.0
    end
    
    # Role synergy (randomized for simulation)
    role_score = :rand.uniform() * 15.0
    
    # Causal bias penalty (extreme biases are penalized)
    causal_penalty = abs(identity.causal_bias - 0.5) * 20.0
    
    final_score = base + policy_score + role_score - causal_penalty
    
    %{identity | fitness_score: Float.round(final_score, 2)}
  end
end
