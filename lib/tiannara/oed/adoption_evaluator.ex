defmodule Tiannara.OED.AdoptionEvaluator do
  @moduledoc """
  Evaluates the systemic impact if a discovery is widely adopted.
  OAVL asks "Is it coherent?" OED asks "What happens if everyone adopts it?"
  If deemed dangerous, the originating civilization's shard is quarantined.
  """

  require Logger

  @dangerous_keywords ["Paradox", "Infinite", "Quantum", "Recombination", "Self-Sealing"]

  @doc "Evaluates adoption impact only when an evidence-backed risk provider is available."
  def evaluate(_civ_id, _shard_id, _discovery) do
    {:error, :adoption_risk_provider_unavailable}
  end

  defp trigger_quarantine(civ_id, shard_id, discovery) do
    Logger.error("🚨 [OED] CATASTROPHIC ADOPTION RISK DETECTED in #{civ_id} from #{discovery.name}!")
    Logger.error("🚨 [OED] Initiating QUARANTINE on shard #{shard_id}.")
    
    # In reality, this would talk to ECL or the ShardManager to block migration/trade.
    # For now, we update the civilization's status.
    case Tiannara.Core.WorldModel.EntityRegistry.get_entity(civ_id, shard_id) do
      {:ok, ent} ->
        new_attrs = Map.put(ent.attributes, :quarantined, true)
        Tiannara.Core.WorldModel.EntityRegistry.update_entity(civ_id, %{attributes: new_attrs}, shard_id)
      _ -> :ok
    end
  end
end
