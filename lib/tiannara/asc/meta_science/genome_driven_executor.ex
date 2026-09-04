defmodule Tiannara.ASC.MetaScience.GenomeDrivenExecutor do
  @moduledoc """
  Phase 7: Universal research executor.
  Reads a ResearchGenome and dynamically constructs an epoch execution plan
  by blending ASC subsystems according to the genome's domain weights and 
  methodology blend.
  """
  
  alias Tiannara.ASC.MetaScience.ResearchGenome
  alias Tiannara.ASC.Research.TelemetrySnapshot
  alias Tiannara.ASC.Crucible.{TransferEcology, RepairLibrary, PatternMutator}
  alias Tiannara.ASC.Laws.{ExperimentDesigner, Discoverer, Registry}
  require Logger

  @doc """
  Executes one epoch of research according to the genome's encoded methodology.
  Returns the telemetry delta.
  """
  def execute_epoch(%ResearchGenome{} = genome, budget) do
    Logger.info("🧬 [Executor] Running genome '#{genome.name}' (Gen #{genome.generation}) | Budget: #{budget}")
    
    snap_before = TelemetrySnapshot.take()
    
    # 1. Allocate budget across domains according to domain_weights
    domain_budgets = allocate_budget_by_domain(budget, genome.domain_weights)
    
    # 2. Execute each domain's share using the methodology blend
    Enum.each(domain_budgets, fn {domain, domain_budget} ->
      execute_domain_research(domain, domain_budget, genome)
    end)
    
    # 3. Run discovery to mint any new laws from accumulated data
    Discoverer.discover_transfer_ecology_laws()
    
    snap_after = TelemetrySnapshot.take()
    TelemetrySnapshot.calculate_delta(snap_before, snap_after)
  end

  # --- Budget Allocation ---

  defp allocate_budget_by_domain(budget, domain_weights) do
    total_weight = Enum.reduce(domain_weights, 0, fn {_k, v}, acc -> acc + v end)
    
    if total_weight == 0 do
      %{}
    else
      Enum.map(domain_weights, fn {domain, weight} ->
        {domain, trunc(budget * (weight / total_weight))}
      end)
      |> Enum.filter(fn {_domain, domain_budget} -> domain_budget > 0 end)
    end
  end

  # --- Domain Execution ---

  defp execute_domain_research(:transfer_physics, budget, genome) do
    experiments_budget = trunc(budget * Map.get(genome.methodology_blend, :targeted_experimentation, 0.0))
    brute_budget = trunc(budget * Map.get(genome.methodology_blend, :brute_force_mutation, 0.0))
    
    # Targeted experimentation: find and fill ecology gaps
    if experiments_budget > 0 do
      gaps = ExperimentDesigner.design_experiments()
      batch_size = max(1, trunc(experiments_budget / genome.compute_efficiency))
      
      gaps
      |> Enum.take(batch_size)
      |> Enum.each(fn exp ->
        # Exploration vs Exploitation: high exploration = try even low-confidence experiments
        # Or focus on highly uncertain gaps
        if genome.exploration_bias > 0.5 or :rand.uniform() < 0.8 do
          execute_single_transfer_experiment(exp)
        end
      end)
    end
    
    # Brute force: random transfer attempts
    if brute_budget > 0 do
      cycles = trunc(brute_budget / genome.compute_efficiency)
      Enum.each(1..cycles, fn _ -> execute_random_transfer_attempt(genome.risk_tolerance) end)
    end
  end

  defp execute_domain_research(:repair_ecology, budget, genome) do
    cycles = trunc(budget / genome.compute_efficiency)
    patterns = RepairLibrary.get_all_patterns()
    
    unless Enum.empty?(patterns) do
      Enum.each(1..max(1, cycles), fn _ ->
        parent = Enum.random(patterns)
        mutant = PatternMutator.mutate(parent)
        
        # Risk tolerance affects acceptance threshold
        acceptance_threshold = 0.30 - (genome.risk_tolerance * 0.15)
        if :rand.uniform() < acceptance_threshold do
          RepairLibrary.learn(mutant)
        end
      end)
    end
  end

  defp execute_domain_research(:architecture, budget, genome) do
    scans = trunc(budget / (genome.compute_efficiency * 2))
    
    Enum.each(1..max(1, scans), fn _ ->
      events = TransferEcology.get_all_events()
      analyze_architectural_patterns(events, genome.exploration_bias)
    end)
  end
  
  defp execute_domain_research(_unknown_domain, _budget, _genome), do: :ok

  # --- Experiment Execution Helpers ---

  defp execute_single_transfer_experiment(experiment) do
    source_domain = Map.get(experiment, :source_domain, :compute)
    target_domain = Map.get(experiment, :target_domain, :compute)
    
    event = %Tiannara.ASC.Crucible.TransferObservation{
      id: "exp_#{Map.get(experiment, :id, :rand.uniform(1000))}_#{:erlang.unique_integer([:positive])}",
      source_classification: %{domain: source_domain, category: :experiment, subcategory: :targeted},
      target_classification: %{domain: target_domain, category: :experiment, subcategory: :targeted},
      semantic_distance: Map.get(experiment, :semantic_distance, 0.5),
      target_constraints: Map.get(experiment, :target_constraints, []),
      adaptation_strategy: "meta_science",
      reuse_count: 0,
      number_of_steps: 1,
      success: :rand.uniform() < 0.35,
      created_at: DateTime.utc_now()
    }
    TransferEcology.record_observation(event)
  end

  defp execute_random_transfer_attempt(risk_tolerance) do
    source_domain = Enum.random([:compute, :network, :storage, :security])
    target_domain = Enum.random([:compute, :network, :storage, :security, :quantum])
    
    event = %Tiannara.ASC.Crucible.TransferObservation{
      id: "rand_#{:erlang.unique_integer([:positive])}",
      source_classification: %{domain: source_domain, category: :experiment, subcategory: :random},
      target_classification: %{domain: target_domain, category: :experiment, subcategory: :random},
      semantic_distance: :rand.uniform(),
      target_constraints: [],
      adaptation_strategy: "meta_science",
      reuse_count: 0,
      number_of_steps: 1,
      success: :rand.uniform() < (0.15 + risk_tolerance * 0.1),
      created_at: DateTime.utc_now()
    }
    TransferEcology.record_observation(event)
  end

  defp analyze_architectural_patterns(events, exploration_bias) when length(events) > 10 do
    failing_domains = 
      events
      |> Enum.reject(& Map.get(&1, :success, false))
      |> Enum.frequencies_by(& Map.get(&1, :target_domain, :unknown))
      |> Enum.filter(fn {_d, c} -> c > 3 end)
      |> Enum.map(fn {d, _} -> d end)

    Enum.each(failing_domains, fn domain ->
      Registry.upsert_law(
        "asc_architecture",
        "Domain #{domain} exhibits systemic transfer resistance",
        %{
          support_count: 5,
          confidence: 0.30 + exploration_bias * 0.15,
          tier: :candidate_pattern,
          tags: [:architecture, :bottleneck],
          utility_score: 100.0
        }
      )
    end)
  end
  defp analyze_architectural_patterns(_events, _exploration), do: :ok
end
