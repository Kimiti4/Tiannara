defmodule Tiannara.ASC.Laws.UtilityTracker do
  @moduledoc """
  Phase 5H: Calculates the pragmatic utility of laws by comparing 
  A/B campaign telemetry. Proves that laws improve civilizational fitness.
  """
  alias Tiannara.ASC.Laws.Registry
  require Logger

  @doc """
  Ingests telemetry from the Control and Guided campaigns.
  Calculates Fitness Gain, Compute Saved, and attributes it to specific laws.
  """
  def calculate_utility_scores(control_telemetry, guided_telemetry) do
    # 1. Calculate Civilizational Deltas
    compute_saved = control_telemetry.compute_cycles - guided_telemetry.compute_cycles
    compute_saved_pct = safe_pct(compute_saved, control_telemetry.compute_cycles)
    
    control_fitness = control_telemetry.successes
    guided_fitness = guided_telemetry.successes
    fitness_gain = guided_fitness - control_fitness
    fitness_gain_pct = safe_pct(fitness_gain, control_fitness)
    
    # Civilizational ROI
    roi_control = if control_telemetry.compute_cycles > 0, do: control_fitness / control_telemetry.compute_cycles, else: 0.0
    roi_guided = if guided_telemetry.compute_cycles > 0, do: guided_fitness / guided_telemetry.compute_cycles, else: 0.0

    Logger.info("""
    ======================================================================
    📊 PHASE 5H: A/B LAW UTILITY VALIDATION REPORT
    ======================================================================
    CONTROL CIVILIZATION (Brute-Force):
      Compute Cycles: #{control_telemetry.compute_cycles} | Fitness: #{control_fitness} | ROI: #{Float.round(roi_control, 5)}
      
    GUIDED CIVILIZATION (Epistemic Routing):
      Compute Cycles: #{guided_telemetry.compute_cycles} | Fitness: #{guided_fitness} | ROI: #{Float.round(roi_guided, 5)}
      
    CIVILIZATIONAL DELTAS:
      💾 Compute Saved: #{compute_saved} (#{compute_saved_pct}%)
      📈 Fitness Gain:  #{fitness_gain} (#{fitness_gain_pct}%)
      🔥 ROI Increase:  #{if roi_control > 0, do: Float.round(roi_guided / roi_control, 2), else: 0.0}x
    ======================================================================
    """)

    # 2. Attribute Utility to Individual Laws
    laws = Registry.all()
    
    Logger.info("⚖️ [UtilityTracker] Attributing utility to specific laws...")
    
    Enum.each(laws, fn law ->
      if :transfer_physics in (law.domain_tags || []) or "transfer_physics" in (law.domain_tags || []) do
        invocations = Map.get(guided_telemetry.law_invocations, law.statement, 0)
        
        total_aborts = guided_telemetry.aborted
        law_compute_share = if total_aborts > 0, do: invocations / total_aborts, else: 0.0
        law_compute_saved = trunc(compute_saved * law_compute_share)
        
        law_fitness_gain = trunc(fitness_gain * law_compute_share)
        
        law_weight = law_weight(law)
        
        # Multidimensional profile
        profile = %{
          fitness_gain: Float.round(law_fitness_gain * 1.0, 2),
          compute_savings: Float.round(law_compute_saved * 1.0, 2),
          success_gain: 0.0, # Approximate or placeholder if we track success rate delta
          confidence: law.confidence
        }
        
        raw_utility = (0.4 * profile.fitness_gain) + (0.4 * profile.compute_savings) + (0.2 * profile.success_gain)
        utility_score = Float.round(raw_utility * law_weight, 2)
        
        updated_law = %{law | utility_profile: profile, utility_score: utility_score}
        Registry.store(updated_law)
        
        Logger.info("  🛠️ '#{law.statement}'")
        Logger.info("      Invocations: #{invocations} | Compute Saved: #{law_compute_saved} | Fitness Gain: #{law_fitness_gain}")
        Logger.info("      Weight: #{law_weight} | Utility Score: #{utility_score}")
      end
    end)
  end

  defp law_weight(law) do
    cond do
      law.status == :canonical_principle -> 4.0
      law.status == :established_law -> 2.0
      true -> 1.0
    end
  end

  defp safe_pct(_, 0), do: 0.0
  defp safe_pct(delta, base), do: Float.round(delta / base * 100, 1)
end
