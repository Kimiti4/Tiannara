defmodule Tiannara.SOPL.LawPathology do
  @moduledoc "A structural failure mode in a LawGenome."
  defstruct [:type, :severity, :signature, :detected_at]
end

defmodule Tiannara.SOPL.LawPathologyRegistry do
  @moduledoc """
  SOPL-1.5: Law Pathology Registry
  
  Detects and tracks diseases of physical laws. Identifies Goodhart
  Attractors (like :fitness_hacking and :stability_monoculture) to
  warn the mutation engine away from known fatal regions.
  """
  alias Tiannara.SOPL.LawPathology

  def analyze(law_genome, fitness_evaluation, ecology_telemetry) do
    pathologies = [
      detect_fitness_hacking(law_genome, fitness_evaluation, ecology_telemetry),
      detect_stability_monoculture(fitness_evaluation),
      detect_novelty_explosion(fitness_evaluation, ecology_telemetry),
      detect_causal_drift(law_genome, ecology_telemetry),
      detect_identity_lock(law_genome, fitness_evaluation),
      detect_entropy_collapse(ecology_telemetry)
    ]
    
    Enum.reject(pathologies, &is_nil/1)
  end

  defp detect_fitness_hacking(_law, eval, telemetry) do
    # Goodhart's Law: High fitness but underlying metrics show sterile behavior 
    # e.g., diversity achieved through meaningless operator churn rather than 
    # genuine epistemic divergence.
    churn_rate = Map.get(telemetry, :meaningless_operator_churn, 0.0)
    if eval.total_fitness > 0.8 and churn_rate > 0.6 do
      %LawPathology{
        type: :fitness_hacking,
        severity: churn_rate,
        signature: %{fitness: eval.total_fitness, churn: churn_rate},
        detected_at: DateTime.utc_now()
      }
    else
      nil
    end
  end

  defp detect_stability_monoculture(eval) do
    # High health but zero potential
    if eval.health.score > 0.9 and eval.potential.score < 0.1 do
      %LawPathology{
        type: :stability_monoculture,
        severity: 1.0 - eval.potential.score,
        signature: %{health: eval.health.score, potential: eval.potential.score},
        detected_at: DateTime.utc_now()
      }
    else
      nil
    end
  end

  defp detect_novelty_explosion(eval, telemetry) do
    # Massive novelty but destroying causal reality
    causal_persistence = Map.get(telemetry, :causal_persistence, 1.0)
    if eval.potential.novelty > 0.9 and causal_persistence < 0.2 do
      %LawPathology{
        type: :novelty_explosion,
        severity: 1.0 - causal_persistence,
        signature: %{novelty: eval.potential.novelty, causal_persistence: causal_persistence},
        detected_at: DateTime.utc_now()
      }
    else
      nil
    end
  end

  defp detect_causal_drift(law, telemetry) do
    # Timelines disconnecting due to overly permissive evolution
    if Map.get(law.extinction_model, :causal_tolerance, 0.0) > 0.8 and Map.get(telemetry, :timeline_fractures, 0) > 50 do
      %LawPathology{
        type: :causal_drift, 
        severity: 0.8, 
        signature: %{fractures: Map.get(telemetry, :timeline_fractures, 0)}, 
        detected_at: DateTime.utc_now()
      }
    else
      nil
    end
  end

  defp detect_identity_lock(law, eval) do
    # Extreme identity weights preventing necessary ontological shifts
    if Map.get(law.trust_formula, :identity_persistence_weight, 0.0) > 0.95 and eval.potential.basin_escape < 0.1 do
      %LawPathology{
        type: :identity_lock, 
        severity: 0.9, 
        signature: %{basin_escape: eval.potential.basin_escape}, 
        detected_at: DateTime.utc_now()
      }
    else
      nil
    end
  end

  defp detect_entropy_collapse(telemetry) do
    # Failure to generate novelty, triggering NDE constantly
    nde_triggers = Map.get(telemetry, :nde_trigger_count, 0)
    if nde_triggers > 100 do
      %LawPathology{
        type: :entropy_collapse, 
        severity: min(1.0, nde_triggers / 500.0), 
        signature: %{nde_triggers: nde_triggers}, 
        detected_at: DateTime.utc_now()
      }
    else
      nil
    end
  end
end
