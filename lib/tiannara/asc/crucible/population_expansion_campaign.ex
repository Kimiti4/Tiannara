defmodule Tiannara.ASC.Crucible.PopulationExpansionCampaign do
  @moduledoc """
  Phase 5C.9: Knowledge Population Expansion Campaign.
  Drives the RepairLibrary from its current baseline to 50+ unique patterns
  by injecting synthetic failures and enforcing evolutionary mutation/crossover.
  """
  
  alias Tiannara.ASC.Crucible.{RepairLibrary, FailureSynthesizer, PatternMutator, RepairPattern}
  alias Tiannara.ASC.Runtime
  require Logger

  @target_population 50
  @max_generations 500
  
  def run do
    Logger.info("🚀 [Phase 5C.9] Initializing Knowledge Population Expansion Campaign")
    Logger.info("Target: #{@target_population} patterns | Max Generations: #{@max_generations}")
    
    # 1. Strict Bootstrap & Integrity Check (Leveraging 5C.8 Guardrails)
    :ok = Runtime.bootstrap()
    
    initial_report = RepairLibrary.population_report()
    if initial_report.has_corruption do
      raise "ABORT: RepairLibrary integrity failure detected. Cannot expand corrupted memory."
    end
    
    Logger.info("Baseline established: #{initial_report.unique_ids} patterns. Memory is healthy.")
    
    # 2. Evolutionary Loop
    execute_generations(0, initial_report.unique_ids, %{
      failures_injected: 0,
      mutations: 0,
      crossovers: 0,
      random_seeds: 0
    })
  end
  
  defp execute_generations(gen, pop, metrics) when pop >= @target_population do
    Logger.info("🎯 [Phase 5C.9] TARGET REACHED! Population: #{pop} at Generation #{gen}")
    print_final_report(gen, pop, metrics)
  end
  
  defp execute_generations(gen, pop, metrics) when gen >= @max_generations do
    Logger.warning("⚠️ [Phase 5C.9] Max generations reached. Final Population: #{pop}")
    print_final_report(gen, pop, metrics)
  end
  
  defp execute_generations(gen, pop, metrics) do
    failure = FailureSynthesizer.generate(gen)
    metrics = Map.update!(metrics, :failures_injected, &(&1 + 1))
    
    case attempt_evolutionary_repair(failure) do
      {:discovered, new_pattern, method} ->
        RepairLibrary.learn(new_pattern)
        new_metrics = Map.update!(metrics, method, &(&1 + 1))
        Logger.info("Gen #{gen}: ✨ Novel pattern discovered via #{method}. Pop: #{pop + 1}")
        execute_generations(gen + 1, pop + 1, new_metrics)
        
      {:failed, method} ->
        new_metrics = Map.update!(metrics, method, &(&1 + 1))
        execute_generations(gen + 1, pop, new_metrics)
    end
  end
  
  defp attempt_evolutionary_repair(failure) do
    patterns = RepairLibrary.get_all_patterns()
    
    case find_closest_matches(patterns, failure) do
      [] ->
        # No existing patterns are even close. Force a random seed mutation.
        seed_pattern = PatternMutator.mutate(get_base_pattern())
        {:discovered, seed_pattern, :random_seeds}
        
      [closest] ->
        # Only one match. Must mutate.
        mutated = PatternMutator.mutate(closest)
        if simulates_success?(mutated, failure) do
          {:discovered, mutated, :mutations}
        else
          {:failed, :mutations}
        end
        
      [closest, second | _] ->
        # Multiple matches. Try crossover first, then mutation.
        crossed = PatternMutator.crossover(closest, second)
        if simulates_success?(crossed, failure) do
          {:discovered, crossed, :crossovers}
        else
          mutated = PatternMutator.mutate(closest)
          if simulates_success?(mutated, failure) do
            {:discovered, mutated, :mutations}
          else
            {:failed, :crossovers}
          end
        end
    end
  end

  # --- Private Helpers ---

  defp get_base_pattern do
    %RepairPattern{
      id: "base", 
      domain: :compute, 
      steps: [%{action: :init}], 
      generation: 0, 
      constraints: [],
      failure_signature: "synthetic:base:pattern",
      confidence: 0.5,
      success_rate: 0.1
    }
  end

  defp find_closest_matches(patterns, failure) do
    patterns
    |> Enum.map(fn p -> {p, calculate_affinity(p, failure)} end)
    |> Enum.filter(fn {_p, score} -> score > 0.3 end) 
    |> Enum.sort_by(fn {_p, score} -> score end, :desc)
    |> Enum.map(fn {p, _score} -> p end)
  end

  defp calculate_affinity(pattern, failure) do
    domain_score = if pattern.domain == failure.domain, do: 0.5, else: 0.0
    p_constraints = Map.get(pattern, :constraints, [])
    constraint_score = length(p_constraints -- (p_constraints -- failure.constraints)) / max(length(failure.constraints), 1) * 0.5
    domain_score + constraint_score
  end

  defp simulates_success?(pattern, failure) do
    # Simulated success based on pattern generation and failure severity
    base_chance = 0.2 + (Map.get(pattern, :generation, 0) * 0.05)
    severity_penalty = failure.severity * 0.3
    :rand.uniform() < max(0.05, base_chance - severity_penalty)
  end

  defp print_final_report(gen, pop, metrics) do
    Logger.info("""
    =========================================
    PHASE 5C.9 FINAL REPORT
    =========================================
    Generations Run: #{gen}
    Final Population: #{pop} / #{@target_population}
    Failures Injected: #{metrics.failures_injected}
    
    Evolutionary Mechanics:
      - Random Seeds: #{metrics.random_seeds}
      - Mutations:    #{metrics.mutations}
      - Crossovers:   #{metrics.crossovers}
    =========================================
    """)
    
    # Final integrity check to ensure 5C.8 guardrails held up under load
    final_report = RepairLibrary.population_report()
    status_str = if final_report.has_corruption, do: "corrupt", else: "healthy"
    Logger.info("Final Memory Integrity Check: #{status_str} (#{final_report.unique_ids} unique patterns)")
  end
end
