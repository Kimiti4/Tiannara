defmodule TiannaraOS.WorldMemory do
  @moduledoc """
  Tracks civilization-level learning at the world level.
  
  Worlds remember:
  - Which domains lead to success
  - Which domains lead to failure
  - Recurring bottlenecks (persistent unsolved needs)
  - Adaptation patterns over time
  
  This influences future program spawning and need evolution,
  creating selection pressure at the world level, not just program level.
  
  ## Key Concepts
  
  - **World Memory**: Meta-knowledge accumulated across all programs in a world
  - **Successful Domains**: Domains where programs consistently thrive
  - **Failed Domains**: Domains with high mortality rates
  - **Recurring Bottlenecks**: Needs that remain unsatisfied for long periods
  - **Adaptation History**: Timeline of major shifts in world strategy
  """
  
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  
  # Threshold for detecting recurring bottleneck (ticks)
  @bottleneck_threshold_ticks 20_000
  
  # Minimum memory updates before considering pattern reliable
  @min_memory_updates 3
  
  # Weight given to world memory when biasing genomes
  @world_memory_influence 0.3
  
  @doc """
  Update world memory based on program outcomes.
  
  Called periodically (every 5000 ticks) to aggregate learnings from
  graveyard analysis and active program performance.
  
  ## Parameters
  
  - `state`: Current simulation state
  - `world_id`: Target world identifier
  
  ## Returns
  
  Updated state with world memory enhanced.
  """
  @spec update_world_memory(State.t(), atom()) :: State.t()
  def update_world_memory(%State{} = state, world_id) do
    world = Map.get(state.worlds, world_id)
    
    if world == nil do
      state
    else
      # Analyze graveyard for this world
      world_graveyard = filter_graveyard_by_world(state.program_graveyard, world_id)
      
      # Analyze active programs for this world
      active_programs = filter_programs_by_world(state.research_programs, world_id)
      
      # Extract patterns from batch analysis
      successful_domains = analyze_successful_domains(active_programs, world_graveyard)
      failed_domains = analyze_failed_domains(world_graveyard)
      recurring_bottlenecks = detect_recurring_bottlenecks(world, world_graveyard)
      
      # Merge with any real-time discovery data accumulated this period
      existing_memory = world.memory || %{}
      
      updated_memory = %{
        successful_domains: merge_counts(
          merge_counts(Map.get(existing_memory, :successful_domains, %{}), successful_domains),
          Map.get(existing_memory, :realtime_successes, %{})
        ),
        failed_domains: merge_counts(
          Map.get(existing_memory, :failed_domains, %{}),
          failed_domains
        ),
        recurring_bottlenecks: recurring_bottlenecks,
        adaptation_history: add_adaptation_event(Map.get(existing_memory, :adaptation_history, []), state.economy.tick),
        last_updated_tick: state.economy.tick,
        realtime_successes: %{}  # Reset after batch incorporation
      }
      
      updated_world = %{world | memory: updated_memory}
      updated_worlds = Map.put(state.worlds, world_id, updated_world)
      
      %{state | worlds: updated_worlds}
    end
  end

  @doc """
  Record a successful discovery in world memory (real-time, not batch).

  Called immediately after each successful discovery to accumulate domain
  success data between batch memory updates. This transforms WorldMemory
  from archival to evolutionary: memory now influences future behavior.

  ## Parameters

  - `state`: Current simulation state
  - `world_id`: World where the discovery occurred
  - `domain`: The research domain of the discovery
  """
  @spec record_discovery_success(State.t(), atom(), atom()) :: State.t()
  def record_discovery_success(%State{} = state, world_id, domain) do
    world = Map.get(state.worlds, world_id)
    if world == nil do
      state
    else
      memory = world.memory || %{}
      realtime = Map.get(memory, :realtime_successes, %{})
      updated_realtime = Map.update(realtime, domain, 1, &(&1 + 1))
      updated_memory = Map.put(memory, :realtime_successes, updated_realtime)
      updated_world = %{world | memory: updated_memory}
      %{state | worlds: Map.put(state.worlds, world_id, updated_world)}
    end
  end

  @doc """
  Record a failed/abandoned discovery domain in world memory (real-time).

  ## Parameters

  - `state`: Current simulation state
  - `world_id`: World where the failure occurred
  - `domain`: The research domain that failed
  """
  @spec record_discovery_failure(State.t(), atom(), atom()) :: State.t()
  def record_discovery_failure(%State{} = state, world_id, domain) do
    world = Map.get(state.worlds, world_id)
    if world == nil do
      state
    else
      memory = world.memory || %{}
      failed = Map.get(memory, :failed_domains, %{})
      updated_failed = Map.update(failed, domain, 1, &(&1 + 1))
      updated_memory = Map.put(memory, :failed_domains, updated_failed)
      updated_world = %{world | memory: updated_memory}
      %{state | worlds: Map.put(state.worlds, world_id, updated_world)}
    end
  end

  
  @doc """
  Use world memory to influence new program spawning.
  
  Worlds bias toward strategies that historically succeeded in their environment.
  
  ## Parameters
  
  - `base_genome`: Original genome from parent or random generation
  - `world_memory`: World's accumulated memory
  
  ## Returns
  
  Adjusted genome biased toward historically successful strategies.
  """
  @spec bias_genome_toward_success(map(), map()) :: map()
  def bias_genome_toward_success(base_genome, world_memory) do
    memory = world_memory || %{}
    successful_domains = Map.get(memory, :successful_domains, %{})
    realtime_successes = Map.get(memory, :realtime_successes, %{})
    
    # Merge batch and realtime domain scores
    all_successes = merge_counts(successful_domains, realtime_successes)
    
    if map_size(all_successes) == 0 do
      base_genome  # No history yet — unbiased
    else
      # Weight top-3 successful domains proportionally rather than just top-1
      # This creates more nuanced, multi-domain evolutionary pressure
      total_score = Enum.sum(Map.values(all_successes))
      top_domains = all_successes
        |> Enum.sort_by(fn {_domain, count} -> -count end)
        |> Enum.take(3)
      
      Enum.reduce(top_domains, base_genome, fn {domain, count}, genome_acc ->
        influence = (count / total_score) * @world_memory_influence
        adjust_genome_for_domain(genome_acc, domain, influence)
      end)
    end
  end
  
  @doc """
  Detect if world is stuck in recurring bottleneck.
  
  Returns true if same need remains unsatisfied for >20k ticks.
  
  ## Parameters
  
  - `world`: World state with memory
  - `graveyard`: Filtered graveyard records
  
  ## Returns
  
  Boolean indicating if world is stuck.
  """
  @spec stuck_in_bottleneck?(map(), list()) :: boolean()
  def stuck_in_bottleneck?(world, graveyard) do
    recurring = Map.get(world.memory || %{}, :recurring_bottlenecks, [])
    
    # If same bottleneck persists across multiple memory updates
    length(recurring) > @min_memory_updates
  end
  
  @doc """
  Get world's historical success rate by domain.
  
  Useful for reporting and analysis.
  
  ## Parameters
  
  - `world_memory`: World's accumulated memory
  
  ## Returns
  
  Map of domain => {success_count, failure_count, success_rate}
  """
  @spec get_domain_performance(map()) :: map()
  def get_domain_performance(world_memory) do
    memory = world_memory || %{}
    successful = Map.get(memory, :successful_domains, %{})
    failed = Map.get(memory, :failed_domains, %{})
    
    all_domains = Map.keys(successful) ++ Map.keys(failed)
    |> Enum.uniq()
    
    Enum.reduce(all_domains, %{}, fn domain, acc ->
      success_count = Map.get(successful, domain, 0)
      failure_count = Map.get(failed, domain, 0)
      total = success_count + failure_count
      
      success_rate = if total > 0 do
        Float.round(success_count / total, 3)
      else
        0.0
      end
      
      Map.put(acc, domain, %{
        success_count: success_count,
        failure_count: failure_count,
        success_rate: success_rate
      })
    end)
  end
  
  @doc """
  Summarize world memory for reporting.
  
  Returns human-readable summary of world's accumulated wisdom.
  """
  @spec summarize_world_memory(map()) :: String.t()
  def summarize_world_memory(world_memory) do
    memory = world_memory || %{}
    successful = Map.get(memory, :successful_domains, %{})
    failed = Map.get(memory, :failed_domains, %{})
    recurring = Map.get(memory, :recurring_bottlenecks, [])
    
    lines = [
      "=== World Memory Summary ===",
      "Last updated: tick #{Map.get(memory, :last_updated_tick, 0)}",
      "",
      "Successful Domains:",
      format_domain_counts(successful),
      "",
      "Failed Domains:",
      format_domain_counts(failed),
      "",
      "Recurring Bottlenecks (#{length(recurring)}):",
      format_bottlenecks(recurring),
      "",
      "Adaptation Events: #{length(Map.get(memory, :adaptation_history, []))}"
    ]
    
    Enum.join(lines, "\n")
  end
  
  # ============================================================================
  # Private Helper Functions
  # ============================================================================
  
  @spec filter_graveyard_by_world(map(), atom()) :: list()
  defp filter_graveyard_by_world(graveyard, world_id) do
    if graveyard == nil do
      []
    else
      graveyard
        |> Map.values()
        |> Enum.filter(fn record ->
          record.world_id == world_id
        end)
    end
  end
  
  @spec filter_programs_by_world(map(), atom()) :: list()
  defp filter_programs_by_world(programs, world_id) do
    if programs == nil do
      []
    else
      programs
        |> Map.values()
        |> Enum.filter(fn program ->
          program.world_id == world_id && program.status == :active
        end)
    end
  end
  
  @spec analyze_successful_domains(list(), list()) :: map()
  defp analyze_successful_domains(active_programs, _graveyard) do
    # For now, count active programs by their primary domain
    # Can be enhanced to consider lifespan, asset count, etc.
    
    Enum.reduce(active_programs, %{}, fn program, acc ->
      domain = infer_program_domain(program)
      current_count = Map.get(acc, domain, 0)
      Map.put(acc, domain, current_count + 1)
    end)
  end
  
  @spec analyze_failed_domains(list()) :: map()
  defp analyze_failed_domains(graveyard) do
    # Count deaths by domain
    Enum.reduce(graveyard, %{}, fn record, acc ->
      # Extract primary_domain from strategy_genome or use :unknown as fallback
      domain = case record do
        %{primary_domain: dom} when not is_nil(dom) -> dom
        %{strategy_genome: %{primary_domain: dom}} when not is_nil(dom) -> dom
        _ -> :unknown
      end
      current_count = Map.get(acc, domain, 0)
      Map.put(acc, domain, current_count + 1)
    end)
  end
  
  @spec detect_recurring_bottlenecks(map(), list()) :: list()
  defp detect_recurring_bottlenecks(world, _graveyard) do
    # Check which needs have remained high (>0.7) for extended periods
    current_needs = world.needs_vector || %{}
    
    current_needs
      |> Enum.filter(fn {_domain, value} -> value > 0.7 end)
      |> Enum.map(fn {domain, _value} -> domain end)
  end
  
  @spec merge_counts(map(), map()) :: map()
  defp merge_counts(existing_counts, new_counts) do
    Map.merge(existing_counts, new_counts, fn _key, existing_val, new_val ->
      existing_val + new_val
    end)
  end
  
  @spec add_adaptation_event(list(), integer()) :: list()
  defp add_adaptation_event(history, tick) do
    [%{tick: tick, event: :memory_update} | history]
    |> Enum.take(100)  # Keep only last 100 events
  end
  
  @spec infer_program_domain(ResearchProgram.t()) :: atom()
  defp infer_program_domain(%ResearchProgram{} = program) do
    # Infer primary domain from strategy genome
    genome = program.strategy_genome || %{}
    
    cond do
      Map.get(genome, :exploration_rate, 0.5) > 0.7 -> :exploration
      Map.get(genome, :validation_priority, 0.5) > 0.7 -> :validation
      Map.get(genome, :cross_domain_synthesis, 0.5) > 0.7 -> :synthesis
      Map.get(genome, :anomaly_sensitivity, 0.5) > 0.7 -> :anomaly_detection
      Map.get(genome, :risk_tolerance, 0.5) > 0.7 -> :high_risk
      true -> :general
    end
  end
  
  @spec adjust_genome_for_domain(map(), atom(), float()) :: map()
  defp adjust_genome_for_domain(genome, domain, influence \\ @world_memory_influence) do
    # Compute target adjustment for the given domain
    adjusted = case domain do
      :exploration    -> %{genome | exploration_rate:        min(1.0, genome.exploration_rate + 0.1)}
      :validation     -> %{genome | validation_priority:     min(1.0, genome.validation_priority + 0.1)}
      :synthesis      -> %{genome | cross_domain_synthesis:  min(1.0, genome.cross_domain_synthesis + 0.1)}
      :anomaly_detection -> %{genome | anomaly_sensitivity:  min(1.0, genome.anomaly_sensitivity + 0.1)}
      :high_risk      -> %{genome | risk_tolerance:          min(1.0, genome.risk_tolerance + 0.1)}
      _other          -> genome
    end
    
    # Blend at the provided influence weight (proportional, not fixed @world_memory_influence)
    Enum.reduce(adjusted, genome, fn {trait, adjusted_value}, acc ->
      original_value = Map.get(acc, trait, 0.5)
      blended = original_value * (1.0 - influence) + adjusted_value * influence
      Map.put(acc, trait, Float.round(blended, 3))
    end)
  end
  
  @spec format_domain_counts(map()) :: String.t()
  defp format_domain_counts(domain_counts) do
    if map_size(domain_counts) == 0 do
      "  (none recorded)"
    else
      domain_counts
        |> Enum.sort_by(fn {_domain, count} -> -count end)
        |> Enum.map_join("\n", fn {domain, count} ->
          "  #{String.pad_trailing(to_string(domain), 20)} #{count}"
        end)
    end
  end
  
  @spec format_bottlenecks(list()) :: String.t()
  defp format_bottlenecks(bottlenecks) do
    if Enum.empty?(bottlenecks) do
      "  (no recurring bottlenecks)"
    else
      bottlenecks
        |> Enum.map_join("\n", fn domain ->
          "  - #{domain}"
        end)
    end
  end
end
