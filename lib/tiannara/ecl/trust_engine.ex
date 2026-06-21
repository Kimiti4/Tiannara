defmodule Tiannara.ECL.TrustEngine do
  @moduledoc """
  Phase ECL-1: Truth-prioritized cross-shard discovery convergence.
  Prevents popularity bias. Rewards demonstrated contact with reality.
  """
  
  @weights %{
    truth_capital: 0.35,
    sentinel_historical_accuracy: 0.25,
    discovery_stability: 0.20,
    lineage_continuity: 0.15,
    influence_capital: 0.05
  }

  @spec compute_trust_score(String.t(), String.t()) :: float()
  def compute_trust_score(civ_id, shard_id) do
    truth = fetch_truth_capital(civ_id)
    accuracy = fetch_sentinel_accuracy(civ_id)
    stability = avg_discovery_stability(civ_id)
    continuity = lineage_continuity_factor(civ_id, shard_id)
    influence = fetch_influence_capital(civ_id)

    # Normalize roughly so the score isn't infinite.
    # Capital can be high, so we might want to log/sigmoid it.
    # For now, let's keep it simple.
    
    score = 
      @weights.truth_capital * truth +
      @weights.sentinel_historical_accuracy * accuracy +
      @weights.discovery_stability * stability +
      @weights.lineage_continuity * continuity +
      @weights.influence_capital * influence

    score
  end

  def award_influence(civ_id, amount) do
    Tiannara.REL.EconomyEngine.grant_influence_capital(civ_id, amount)
  end

  defp fetch_truth_capital(civ_id) do
    budget = Tiannara.REL.EconomyEngine.get_budget(civ_id)
    if budget, do: budget.truth_capital, else: 0.0
  end

  defp fetch_influence_capital(civ_id) do
    budget = Tiannara.REL.EconomyEngine.get_budget(civ_id)
    if budget, do: budget.influence_capital, else: 0.0
  end

  defp fetch_sentinel_accuracy(_civ_id) do
    # Pull from Sentinel D.1A passive telemetry (mocked for now)
    # E.g. Tiannara.Sentinel.MetricsCollector.get_prediction_accuracy
    0.7
  end

  defp avg_discovery_stability(civ_id) do
    known = Tiannara.REL.DiscoveryLedger.get_known_discoveries(civ_id)
    if length(known) > 0 do
      sum = Enum.reduce(known, 0.0, fn d, acc -> acc + Map.get(d, :stability, 0.5) end)
      sum / length(known)
    else
      0.0
    end
  end

  defp lineage_continuity_factor(civ_id, shard_id) do
    # Fetch lineage path from Entity
    case Tiannara.Core.WorldModel.EntityRegistry.get_entity(civ_id, shard_id) do
      {:ok, ent} -> 
        length(Map.get(ent.attributes, :lineage, [])) * 0.1
      _ -> 0.0
    end
  end
end
