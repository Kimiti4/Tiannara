defmodule Tiannara.ASC.Laws.CanonicalPromotionEngine do
  @moduledoc """
  Phase 5I: Canonical Principle Governance.
  Evaluates laws against multi-dimensional criteria to determine if they
  have earned the right to govern civilization-wide behavior.
  
  A Canonical Principle must be:
  - True (high confidence, low contradictions)
  - Useful (high utility score)
  - Stable (survived multiple campaigns without demotion)
  """
  
  alias Tiannara.ASC.Laws.{Registry, Law}
  require Logger

  @doc """
  Runs at the end of a campaign. Evaluates all active laws for promotion
  or demotion based on the full multi-dimensional criteria.
  """
  def evaluate_governance do
    Logger.info("👑 [CanonicalPromotion] Evaluating all active laws for governance status...")
    
    laws = Registry.all()
    
    Enum.each(laws, fn law ->
      # Ensure campaign metrics are updated
      law = %{law | campaigns_tested: (law.campaigns_tested || 0) + 1}
      # If it wasn't refuted this campaign, we assume it survived
      # For now, we will just increment survival
      law = %{law | campaigns_survived: (law.campaigns_survived || 0) + 1}
      
      evaluate_law(law)
    end)
    
    Logger.info("👑 [CanonicalPromotion] Governance evaluation complete.")
  end

  defp evaluate_law(%Law{} = law) do
    # Check for demotion first (laws can lose canonical status)
    if should_demote?(law) do
      demote_law(law)
    else
      # Check for promotion
      cond do
        should_promote_to_canonical?(law) -> promote_law(law, :canonical_principle, :multi_dimensional_validation)
        should_promote_to_established?(law) -> promote_law(law, :established_law, :proven_stability)
        should_promote_to_candidate_law?(law) -> promote_law(law, :candidate_law, :plausible_hypothesis)
        true -> Registry.store(law) # Just save updated metrics
      end
    end
  end

  # --- Promotion Criteria ---

  defp should_promote_to_canonical?(%Law{} = law) do
    law.status != :canonical_principle and
    law.support_count >= 250 and
    law.confidence >= 0.50 and
    contradiction_ratio(law) < 0.10 and
    law.utility_score > 0.0 and # Required utility validation
    law.campaigns_survived >= 10
  end

  defp should_promote_to_established?(%Law{} = law) do
    law.status in [:candidate_law, :candidate_pattern, :under_review] and
    law.support_count >= 50 and
    law.confidence >= 0.30 and
    law.utility_score > 0.0 and
    law.campaigns_survived >= 3
  end
  
  defp should_promote_to_candidate_law?(%Law{} = law) do
    law.status == :candidate_pattern and
    law.support_count >= 10 and
    law.confidence >= 0.15 and
    contradiction_ratio(law) < 0.50
  end

  # --- Demotion Criteria ---

  defp should_demote?(%Law{} = law) do
    cond do
      law.status == :refuted -> false # Already demoted
      
      # High contradiction ratio
      contradiction_ratio(law) > 0.50 -> true
      
      # Utility collapsed
      law.utility_score < 0.0 and law.status not in [:candidate_pattern, :candidate_law] -> true
      
      # Failed recent campaigns
      law.campaigns_tested > 5 and law.campaigns_survived < law.campaigns_tested * 0.5 -> true
      
      true -> false
    end
  end

  defp contradiction_ratio(%Law{} = law) do
    total = law.support_count + law.contradiction_count
    if total > 0, do: law.contradiction_count / total, else: 0.0
  end

  defp promote_law(%Law{status: current_status, statement: statement} = law, new_status, reason) do
    Logger.info("""
    👑 [CanonicalPromotion] PROMOTED: "#{statement}"
       From: #{current_status}
       To:   #{new_status}
       
       Metrics:
         Support: #{law.support_count}
         Confidence: #{Float.round(law.confidence, 3)}
         Contradictions: #{law.contradiction_count}
         Utility Score: #{Float.round(law.utility_score, 2)}
         Campaigns Survived: #{law.campaigns_survived}/#{law.campaigns_tested}
    """)
    
    updated_variables = Map.put(law.variables || %{}, :governance_reason, reason)
    Registry.store(%{law | status: new_status, variables: updated_variables})
  end

  defp demote_law(%Law{status: current_status, statement: statement} = law) do
    {new_status, reason} = case current_status do
      :canonical_principle -> {:established_law, :failed_canonical_criteria}
      :established_law -> {:candidate_law, :failed_established_criteria}
      :candidate_law -> {:refuted, :high_contradiction_ratio}
      :candidate_pattern -> {:refuted, :high_contradiction_ratio}
      :under_review -> {:refuted, :high_contradiction_ratio}
      _ -> {:refuted, :unknown}
    end
    
    Logger.warning("""
    ⚠️ [CanonicalPromotion] DEMOTED: "#{statement}"
       From: #{current_status}
       To:   #{new_status}
       
       Reason: #{reason}
         Support: #{law.support_count}
         Confidence: #{Float.round(law.confidence, 3)}
         Contradictions: #{law.contradiction_count}
         Utility Score: #{Float.round(law.utility_score, 2)}
         Survival Rate: #{Float.round(law.campaigns_survived / max(law.campaigns_tested, 1) * 100, 1)}%
    """)
    
    updated_variables = Map.put(law.variables || %{}, :governance_reason, reason)
    Registry.store(%{law | status: new_status, variables: updated_variables})
  end
end
