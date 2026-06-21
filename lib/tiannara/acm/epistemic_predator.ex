defmodule Tiannara.ACM.EpistemicPredator do
  @moduledoc """
  Generates adversarial traps targeted at specific epistemic biases.
  These are false patterns that cost a civilization Compute and Attention to process,
  forcing them to either correctly reject them based on other robust traits, or waste resources.
  """

  require Logger
  alias Tiannara.REL.EconomyEngine

  @doc "Examines a civilization's genome and active operators to generate an adversarial trap."
  def attack(shard_id, civ_id, genome) do
    # Fetch active operators from registry since genome no longer holds them
    active_operators = get_active_operators(civ_id, shard_id)

    trap_type = select_trap(genome)
    
    if trap_type do
      Logger.info("🕸️ [ACM] Launching #{trap_type} attack against #{civ_id}")
      
      damage = calculate_damage(trap_type, active_operators, genome)
      
      if damage > 0 do
        Logger.debug("🕸️ [ACM] #{civ_id} fell for #{trap_type}, wasting #{damage} compute/attention.")
        EconomyEngine.consume(civ_id, %{compute: damage, attention: damage})
        
        EconomyEngine.penalize_truth_capital(civ_id, 30.0)
        
        {:hit, trap_type, damage}
      else
        Logger.debug("🛡️ [ACM] #{civ_id} successfully rejected #{trap_type}.")
        
        EconomyEngine.grant_truth_capital(civ_id, 20.0)
        
        # D.2 Telemetry: All known stable discoveries survive this ACM attack
        known = Tiannara.REL.DiscoveryLedger.get_known_discoveries(civ_id)
        Enum.each(known, fn disc -> 
          if Map.get(disc, :stability, 0.5) >= 0.8 do
            Tiannara.Sentinel.D2.TruthRetentionMatrix.record_acm_survival(disc.id)
          end
        end)

        {:resisted, trap_type}
      end
    else
      :no_attack
    end
  end

  defp get_active_operators(civ_id, shard_id) do
    case Tiannara.Core.WorldModel.EntityRegistry.get_entity(civ_id, shard_id) do
      {:ok, ent} -> Map.get(ent.attributes, :active_operators, [])
      _ -> []
    end
  end

  defp select_trap(genome) do
    # Traps are invited by meta-biases
    cond do
      Map.get(genome, :novelty_seeking, 0.5) > 0.8 -> :pattern_mirage
      Map.get(genome, :empiricism_bias, 0.5) > 0.8 -> :measurement_noise
      Map.get(genome, :abstraction_bias, 0.5) > 0.8 -> :elegant_false_theory
      Map.get(genome, :contradiction_tolerance, 0.5) > 0.8 -> :infinite_paradox_loop
      true -> nil
    end
  end

  defp calculate_damage(:pattern_mirage, active_operators, genome) do
    # Resisted by statistical or constraint reasoning
    if Enum.any?(active_operators, &String.contains?(&1, "statistical") or String.contains?(&1, "constraint")) or Map.get(genome, :statistical_reasoning, 0.0) > 0.8, do: 0, else: 500
  end

  defp calculate_damage(:measurement_noise, active_operators, genome) do
    # Resisted by analogical or symbolic reasoning
    if Enum.any?(active_operators, &String.contains?(&1, "analogical") or String.contains?(&1, "symbolic")) or Map.get(genome, :empiricism_bias, 0.0) > 0.8, do: 0, else: 400
  end

  defp calculate_damage(:elegant_false_theory, active_operators, genome) do
    # Resisted by adversarial or causal reasoning
    if Enum.any?(active_operators, &String.contains?(&1, "adversarial") or String.contains?(&1, "causal")) or Map.get(genome, :causal_reasoning, 0.0) > 0.8, do: 0, else: 600
  end

  defp calculate_damage(:infinite_paradox_loop, active_operators, genome) do
    # Resisted by recursive or topological reasoning
    if Enum.any?(active_operators, &String.contains?(&1, "recursive") or String.contains?(&1, "topological")) or Map.get(genome, :contradiction_tolerance, 1.0) < 0.2, do: 0, else: 800
  end
end
