defmodule Tiannara.ERO.CognitiveEvolutionEngine do
  @moduledoc """
  Phase 9 ERO: Manages the Operator Graph. 
  Generates new Epistemic Reasoning Operators when civilizations experience moderate tension.
  """
  require Logger
  alias Tiannara.Core.WorldModel.ReasoningOperator

  @operator_classes [
    :causal, :analogical, :counterfactual, :symbolic, :recursive,
    :adversarial, :topological, :narrative, :abductive, :systems,
    :probabilistic, :constraint
  ]

  @doc """
  Called by the EconomyEngine when epistemic tension is moderate.
  Consults Phase 10 Meta-Cognition for evolutionary variants (epistemologies).
  If proposals pass ESG shadow validation, deploys them as new competing species.
  """
  def check_emergence(civ_id, shard_id, tension) do
    # Fetch genome to check meta-biases
    genome = get_genome(civ_id, shard_id)
    
    # Base probability for meta-cognitive emergence
    base_prob = if tension > 40.0 and tension < 80.0, do: 0.2, else: 0.05
    
    if :rand.uniform() < base_prob do
      # 1. Gather D.2 Telemetry
      d2_analytics = Tiannara.Sentinel.D2.AnalyticsEngine.evaluate_graduation_gate()
      
      # 2. Consult MetaCognition (Evolutionary)
      active_ops = get_active_operators(civ_id, shard_id)
      candidates = Tiannara.MetaCognition.generate_candidate_epistemologies(active_ops, d2_analytics)
      
      # 3. Deploy Survivors as new species (No Direct Replacement)
      Enum.each(candidates, fn {strategy, variant_ops} ->
        Logger.info("🌌 [Phase 10] Meta-Cognition proposed #{strategy} variant for #{civ_id}. Spawning new species.")
        
        # Construct variant genome based on parent but with new operators
        variant_genome = Map.put(genome, :active_operators, variant_ops)
        
        # Deploy as a competing civilization
        # Assuming EvolutionEngine has a reproduce(parent_id, shard_id, variant_genome) function
        # For simulation purposes, we log it and mock the API call
        Tiannara.ROS.EvolutionEngine.reproduce(civ_id, shard_id, variant_genome)
      end)
    end
  end

  defp get_active_operators(civ_id, shard_id) do
    case Tiannara.Core.WorldModel.EntityRegistry.get_entity(civ_id, shard_id) do
      {:ok, ent} -> Map.get(ent.attributes, :active_operators, ["empirical", "causal"])
      _ -> ["empirical", "causal"]
    end
  end

  defp get_genome(civ_id, shard_id) do
    case Tiannara.Core.WorldModel.EntityRegistry.get_entity(civ_id, shard_id) do
      {:ok, ent} -> Map.get(ent.attributes, :epistemic_genome, %{})
      _ -> %{}
    end
  end

  defp add_operator_to_civ(civ_id, shard_id, operator_id) do
    case Tiannara.Core.WorldModel.EntityRegistry.get_entity(civ_id, shard_id) do
      {:ok, ent} ->
        active_ops = Map.get(ent.attributes, :active_operators, [])
        new_attrs = Map.put(ent.attributes, :active_operators, [operator_id | active_ops])
        Tiannara.Core.WorldModel.EntityRegistry.update_entity(civ_id, %{attributes: new_attrs}, shard_id)
        
        # D.2 Telemetry: Record epistemology and synergies
        Tiannara.Sentinel.D2.EpistemologyGraph.record_epistemology(civ_id, [operator_id | active_ops], %{})
        
        # Check for synergies (mocking that every new op interacts with existing)
        Enum.each(active_ops, fn existing_op ->
          Tiannara.Sentinel.D2.OperatorGenealogy.record_ecology_interaction(operator_id, existing_op, :synergy)
        end)
      _ -> :ok
    end
  end

  defp format_name(class) do
    class |> Atom.to_string() |> String.capitalize() |> Kernel.<>(" Reasoning")
  end
end
