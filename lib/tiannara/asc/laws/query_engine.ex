defmodule Tiannara.ASC.Laws.QueryEngine do
  @moduledoc """
  Phase 5G: Epistemic Routing.
  Evaluates proposed transfer contexts against the minted Candidate Laws
  to predict viability and conserve compute cycles on doomed transfers.
  """
  alias Tiannara.ASC.Laws.Registry
  require Logger

  @abort_threshold 0.15 # If predicted success is below this, abort early

  @doc """
  Evaluates a transfer context against the active laws of transfer physics.
  Returns %{viability: :viable | :doomed, probability: float, penalties: [...], supporting_laws: [...]}
  """
  def evaluate_transfer(context) do
    # Fetch the proven laws from the registry
    all_laws = Registry.all()
    laws = Enum.filter(all_laws, fn law ->
      tags = law.domain_tags || []
      :transfer_physics in tags or "transfer_physics" in tags
    end)
    
    if Enum.empty?(laws) do
      # Fallback if no laws are minted yet
      %{
        viability: :viable,
        probability: 0.50,
        penalties: [],
        supporting_laws: []
      }
    else
      base_prob = 0.50
      
      {penalty_score, penalty_reasons, supporting_laws} = calculate_penalties(context, laws)
      
      predicted_prob = max(0.0, base_prob - penalty_score)

      if predicted_prob < @abort_threshold do
        %{
          viability: :doomed,
          probability: Float.round(predicted_prob, 3),
          penalties: penalty_reasons,
          supporting_laws: supporting_laws
        }
      else
        %{
          viability: :viable,
          probability: Float.round(predicted_prob, 3),
          penalties: penalty_reasons,
          supporting_laws: supporting_laws
        }
      end
    end
  end

  defp calculate_penalties(context, laws) do
    # Law 1: Transfer Success Declines With Semantic Distance
    # Base penalty: 0.35, weighted by law confidence
    {p1, r1, s1} = check_law(
      context, laws, 
      "Transfer Success Declines With Semantic Distance", 
      :semantic_distance_decay, 
      0.35, 
      fn ctx -> Map.get(ctx, :semantic_distance, 0.0) > 0.7 end
    )
    
    # Law 2: Domain Resonance Amplifies Transfer Efficacy
    # Base penalty: 0.25, weighted by law confidence
    {p2, r2, s2} = check_law(
      context, laws, 
      "Domain Resonance Amplifies Transfer Efficacy", 
      :domain_dissonance, 
      0.25, 
      fn ctx -> Map.get(ctx, :source_domain) != Map.get(ctx, :target_domain) end
    )
    
    # Law 3: Target Architectural Complexity Imposes a Transfer Penalty
    # Base penalty: 0.20, weighted by law confidence
    {p3, r3, s3} = check_law(
      context, laws, 
      "Target Architectural Complexity Imposes a Transfer Penalty", 
      :complexity_penalty, 
      0.20, 
      fn ctx -> length(Map.get(ctx, :target_constraints, [])) >= 3 end
    )
    
    {
      p1 + p2 + p3,
      Enum.reject([r1, r2, r3], &is_nil/1),
      Enum.reject([s1, s2, s3], &is_nil/1)
    }
  end

  defp check_law(context, laws, law_statement, penalty_name, base_penalty, condition_fn) do
    law = Enum.find(laws, fn l -> 
      # Support both Map representations (if they are basic maps from tests) or Law structs
      stmt = if is_map(l) and Map.has_key?(l, :statement), do: l.statement, else: Map.get(l, "statement") || l.statement
      stmt == law_statement 
    end)
    
    if law && condition_fn.(context) do
      # Weight by confidence or fallback to 1.0
      confidence = if is_map(law) and Map.has_key?(law, :confidence), do: law.confidence, else: Map.get(law, "confidence") || law.confidence || 1.0
      weight = confidence_to_weight(confidence)
      penalty = base_penalty * weight
      
      {penalty, penalty_name, law_statement}
    else
      {0.0, nil, nil}
    end
  end

  # Convert confidence into a scaling weight
  # Candidate (~0.15 - 0.4) -> 0.5
  # Established (~0.4 - 0.85) -> 1.0
  # Canonical (> 0.85) -> 2.0
  defp confidence_to_weight(confidence) do
    cond do
      confidence >= 0.85 -> 2.0
      confidence >= 0.40 -> 1.0
      true -> 0.5
    end
  end
end
