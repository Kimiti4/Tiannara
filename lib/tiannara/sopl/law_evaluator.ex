defmodule Tiannara.SOPL.LawEvaluator do
  @moduledoc """
  SOPL-1: Law Fitness Evaluator
  
  A LawGenome is evaluated not by its internal math, but by the ecosystem it produces.
  Fitness is split between Health (conserving the core) and Potential (discovering the new)
  to prevent over-optimization toward sterile stability.
  """
  require Logger

  def evaluate(law_genome, telemetry_source \\ Tiannara.Sentinel.D2.AnalyticsEngine) do
    # 1. Fetch D.2 Telemetry
    gate = telemetry_source.evaluate_graduation_gate()
    health_metrics = gate.health
    readiness = gate.readiness
    
    # 2. Extract Health Metrics
    # In a full simulation these would be precise integrals over the epoch.
    truth_retention = 0.85 # Mapped from attractor truth retention
    resilience = readiness.avg_epistemic_resilience
    stability = readiness.species_stability
    
    health_score = (truth_retention + resilience + stability) / 3.0

    # 3. Extract Potential Metrics
    basin_escape = min(1.0, readiness.basin_escape_rate + readiness.productive_escape_rate)
    breakthroughs = min(1.0, health_metrics.breakthrough_velocity / 50.0)
    novelty = readiness.species_diversity
    unknown_coverage = min(1.0, length(gate.unknowns) / 5.0)

    potential_score = (basin_escape + breakthroughs + novelty + unknown_coverage) / 4.0

    # 4. Final Composite 50/50 Split
    total_fitness = (0.5 * health_score) + (0.5 * potential_score)
    
    # 5. Apply constitutional margin penalty if danger-close to bounds
    # Assuming margin goes from 0.0 to 1.0, we penalize heavily if < 0.1
    margin_penalty = if law_genome.constitutional_margin < 0.1, do: 0.5, else: 1.0
    final_score = total_fitness * margin_penalty

    Logger.debug("📊 [SOPL] Evaluated Law #{law_genome.id} | Health: #{Float.round(health_score, 3)} | Potential: #{Float.round(potential_score, 3)} | Final: #{Float.round(final_score, 3)}")

    %{
      total_fitness: final_score,
      raw_fitness: total_fitness,
      margin_penalty: margin_penalty,
      health: %{
        score: health_score,
        truth_retention: truth_retention,
        resilience: resilience,
        stability: stability
      },
      potential: %{
        score: potential_score,
        basin_escape: basin_escape,
        breakthroughs: breakthroughs,
        novelty: novelty,
        unknown_coverage: unknown_coverage
      }
    }
  end
end
