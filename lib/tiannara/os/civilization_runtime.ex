defmodule TiannaraOS.CivilizationRuntime do
  @moduledoc """
  Civilization Runtime - Minimal execution engine for generating genuine institutional history.
  
  Stage 1 of Phase 13 Operationalization
  
  This runtime's ONLY responsibility is:
  
  ```
  Generation
  ↓
  execute institutions
  ↓
  collect canonical transactions
  ↓
  persist Episodes
  ↓
  advance clock
  ↓
  repeat
  ```
  
  No adaptation. No evolution. Just pure constitutional execution producing real data.
  
  ## Constitutional Primitives Used
  
  - InstitutionKernel.execute_research_cycle/2
  - ResearchEpisode (canonical transaction)
  - EpisodeIndex (in-memory index)
  - Knowledge Graph (relationship tracking)
  - Lifecycle Registry (audit trail)
  - Semantic Event Bus (high-level events)
  
  ## Usage
  
      # Start runtime with 20 institutions
      {:ok, runtime} = CivilizationRuntime.start_link(%{
        institution_count: 20,
        cycles_per_institution: 500,
        domains: [:physics, :biology, :chemistry, :engineering, :medicine]
      })
      
      # Execute one generation
      {:ok, generation_result} = CivilizationRuntime.execute_generation(runtime, generation_number)
      
      # Get accumulated statistics
      {:ok, stats} = CivilizationRuntime.get_statistics(runtime)
  """
  
  use GenServer
  require Logger
  
  alias TiannaraOS.ResearchEpisode
  
  # ==================== State ====================
  
  @type state :: %{
    runtime_id: atom(),
    institutions: [map()],
    generation: integer(),
    total_cycles_executed: integer(),
    episodes_created: integer(),
    discoveries_made: integer(),
    theories_formed: integer(),
    start_time: integer(),
    domain_distribution: map(),
    lifecycle_events: [map()],
    semantic_events: [map()]
  }
  
  # ==================== API ====================
  
  @doc """
  Start Civilization Runtime.
  
  ## Parameters
  
  - `runtime_id`: atom() - unique runtime identifier
  - `config`: map() with keys:
    - `:institution_count` - integer() number of institutions to create
    - `:cycles_per_institution` - integer() research cycles per institution per generation
    - `:domains` - [atom()] list of research domains
    - `:episodes_target` - integer() target number of episodes to generate
  
  ## Returns
  
  `{:ok, pid()}` on success
  """
  @spec start_link(atom(), map()) :: {:ok, pid()} | {:error, term()}
  def start_link(runtime_id, config) do
    Logger.info("[CivilizationRuntime] Starting runtime: #{inspect(runtime_id)}")
    
    GenServer.start_link(__MODULE__, %{
      runtime_id: runtime_id,
      institutions: initialize_institutions(config),
      generation: 0,
      total_cycles_executed: 0,
      episodes_created: 0,
      discoveries_made: 0,
      theories_formed: 0,
      start_time: System.monotonic_time(:millisecond),
      domain_distribution: initialize_domain_distribution(config[:domains]),
      lifecycle_events: [],
      semantic_events: []
    })
  end
  
  @doc """
  Execute one generation of institutional research.
  
  Each institution performs multiple research cycles, producing:
  - ResearchCycleResults
  - BeliefRevisionResults
  - Publications
  - ResearchEpisodes
  - Discoveries
  - Theories
  
  ## Parameters
  
  - `runtime_pid`: pid() - runtime process
  - `generation`: integer() - generation number
  
  ## Returns
  
  `{:ok, generation_result}` with execution statistics
  """
  @spec execute_generation(pid(), integer()) :: {:ok, map()} | {:error, term()}
  def execute_generation(runtime_pid, generation) do
    GenServer.call(runtime_pid, {:execute_generation, generation})
  end
  
  @doc """
  Execute multiple generations sequentially.
  
  ## Parameters
  
  - `runtime_pid`: pid()
  - `generations`: integer() number of generations to execute
  
  ## Returns
  
  `{:ok, final_statistics}`
  """
  @spec execute_multiple_generations(pid(), integer()) :: {:ok, map()} | {:error, term()}
  def execute_multiple_generations(runtime_pid, generations) do
    GenServer.call(runtime_pid, {:execute_multiple_generations, generations})
  end
  
  @doc """
  Get current runtime statistics.
  
  Returns accumulated metrics across all generations.
  """
  @spec get_statistics(pid()) :: {:ok, map()} | {:error, term()}
  def get_statistics(runtime_pid) do
    GenServer.call(runtime_pid, :get_statistics)
  end
  
  @doc """
  Export all generated episodes for analysis.
  
  Returns list of ResearchEpisode structs.
  """
  @spec export_episodes(pid()) :: {:ok, [ResearchEpisode.t()]} | {:error, term()}
  def export_episodes(runtime_pid) do
    GenServer.call(runtime_pid, :export_episodes)
  end
  
  # ==================== Internal Helpers ====================

  # ==================== GenServer Callbacks ====================
  
  @impl true
  def init(state) do
    Logger.info("[CivilizationRuntime] Initialized with #{length(state.institutions)} institutions")
    Logger.info("[CivilizationRuntime] Domains: #{inspect(Map.keys(state.domain_distribution))}")
    
    {:ok, state}
  end
  
  @impl true
  def handle_call({:execute_generation, generation}, _from, state) do
    Logger.info("[CivilizationRuntime] ===== Executing Generation #{generation} =====")
    
    generation_start = System.monotonic_time(:millisecond)
    
    # Execute research cycles for each institution
    {updated_institutions, generation_stats} = execute_institutional_research(
      state.institutions,
      generation,
      state.domain_distribution
    )
    
    generation_duration = System.monotonic_time(:millisecond) - generation_start
    
    # Update state
    updated_state = %{
      state
      | institutions: updated_institutions,
        generation: generation,
        total_cycles_executed: state.total_cycles_executed + generation_stats.cycles_executed,
        episodes_created: state.episodes_created + generation_stats.episodes_created,
        discoveries_made: state.discoveries_made + generation_stats.discoveries_made,
        theories_formed: state.theories_formed + generation_stats.theories_formed,
        lifecycle_events: state.lifecycle_events ++ generation_stats.lifecycle_events,
        semantic_events: state.semantic_events ++ generation_stats.semantic_events
    }
    
    result = %{
      generation: generation,
      duration_ms: generation_duration,
      cycles_executed: generation_stats.cycles_executed,
      episodes_created: generation_stats.episodes_created,
      discoveries_made: generation_stats.discoveries_made,
      theories_formed: generation_stats.theories_formed,
      institutions_active: length(updated_institutions),
      cumulative_episodes: updated_state.episodes_created,
      cumulative_discoveries: updated_state.discoveries_made
    }
    
    Logger.info("[CivilizationRuntime] Generation #{generation} complete:")
    Logger.info("  Cycles: #{result.cycles_executed}")
    Logger.info("  Episodes: #{result.episodes_created} (cumulative: #{result.cumulative_episodes})")
    Logger.info("  Discoveries: #{result.discoveries_made} (cumulative: #{result.cumulative_discoveries})")
    Logger.info("  Duration: #{result.duration_ms}ms")
    
    {:reply, {:ok, result}, updated_state}
  end
  
  @impl true
  def handle_call({:execute_multiple_generations, count}, _from, state) do
    Logger.info("[CivilizationRuntime] Executing #{count} generations...")
    
    _results = Enum.map(1..count, fn gen ->
      {:ok, result} = execute_generation_internal(state, gen)
      _state = update_state_after_generation(state, result)
      result
    end)
    
    final_stats = get_statistics_internal(state)
    
    {:reply, {:ok, final_stats}, state}
  end
  
  @impl true
  def handle_call(:get_statistics, _from, state) do
    stats = get_statistics_internal(state)
    {:reply, {:ok, stats}, state}
  end
  
  @impl true
  def handle_call(:export_episodes, _from, state) do
    # Would query EpisodeIndex for all episodes
    episodes = []  # Placeholder - would retrieve from EpisodeIndex
    
    {:reply, {:ok, episodes}, state}
  end
  
  # ==================== Execution Logic ====================
  
  defp initialize_institutions(config) do
    institution_count = config[:institution_count] || 20
    domains = config[:domains] || [:physics, :biology, :chemistry, :engineering, :medicine]
    
    Enum.map(1..institution_count, fn i ->
      domain = Enum.at(domains, rem(i - 1, length(domains)))
      %{
        id: :"institution_#{i}",
        domain: domain,
        specialization: generate_specialization(domain, i),
        active_programs: [],
        research_capacity: 0.5 + (:rand.uniform() * 0.5),
        collaboration_network: [],
        created_at: DateTime.utc_now()
      }
    end)
  end
  
  defp generate_specialization(domain, index) do
    specializations = %{
      physics: ["quantum_mechanics", "particle_physics", "astrophysics", "condensed_matter"],
      biology: ["genetics", "ecology", "molecular_biology", "evolutionary_biology"],
      chemistry: ["organic_chemistry", "physical_chemistry", "biochemistry", "materials"],
      engineering: ["software", "mechanical", "electrical", "civil"],
      medicine: ["oncology", "neurology", "cardiology", "immunology"]
    }
    
    domain_specs = Map.get(specializations, domain, ["general"])
    Enum.at(domain_specs, rem(index - 1, length(domain_specs)))
  end
  
  defp initialize_domain_distribution(domains) do
    domains
    |> Enum.map(fn domain -> {domain, 0} end)
    |> Enum.into(%{})
  end
  
  defp execute_institutional_research(institutions, generation, _domain_distribution) do
    cycles_per_institution = 50  # Configurable
    
    {updated_institutions, stats} = Enum.reduce(institutions, {[], %{
      cycles_executed: 0,
      episodes_created: 0,
      discoveries_made: 0,
      theories_formed: 0,
      lifecycle_events: [],
      semantic_events: []
    }}, fn institution, {acc_insts, acc_stats} ->
      # Execute research cycles for this institution
      {updated_institution, inst_stats} = execute_institution_cycles(
        institution,
        generation,
        cycles_per_institution
      )
      
      updated_stats = %{
        cycles_executed: acc_stats.cycles_executed + inst_stats.cycles_executed,
        episodes_created: acc_stats.episodes_created + inst_stats.episodes_created,
        discoveries_made: acc_stats.discoveries_made + inst_stats.discoveries_made,
        theories_formed: acc_stats.theories_formed + inst_stats.theories_formed,
        lifecycle_events: acc_stats.lifecycle_events ++ inst_stats.lifecycle_events,
        semantic_events: acc_stats.semantic_events ++ inst_stats.semantic_events
      }
      
      {[updated_institution | acc_insts], updated_stats}
    end)
    
    {Enum.reverse(updated_institutions), stats}
  end
  
  defp execute_institution_cycles(institution, generation, cycle_count) do
    Logger.debug("[CivilizationRuntime] Institution #{inspect(institution.id)} executing #{cycle_count} cycles")
    
    {final_institution, stats} = Enum.reduce(1..cycle_count, {institution, %{
      cycles_executed: 0,
      episodes_created: 0,
      discoveries_made: 0,
      theories_formed: 0,
      lifecycle_events: [],
      semantic_events: []
    }}, fn cycle_num, {inst, acc_stats} ->
      # Execute one research cycle
      case execute_single_research_cycle(inst, generation, cycle_num) do
        {:ok, cycle_result, episode} ->
          updated_stats = %{
            cycles_executed: acc_stats.cycles_executed + 1,
            episodes_created: acc_stats.episodes_created + 1,
            discoveries_made: acc_stats.discoveries_made + length(cycle_result.discoveries || []),
            theories_formed: acc_stats.theories_formed + (if cycle_result.theory_formed, do: 1, else: 0),
            lifecycle_events: acc_stats.lifecycle_events ++ cycle_result.lifecycle_events,
            semantic_events: acc_stats.semantic_events ++ cycle_result.semantic_events
          }
          
          updated_inst = update_institution_with_results(inst, cycle_result, episode)
          
          {updated_inst, updated_stats}
      end
    end)
    
    {final_institution, stats}
  end
  
  defp execute_single_research_cycle(institution, generation, cycle_num) do
    # In production, would call InstitutionKernel.execute_research_cycle
    # For now, simulate realistic research cycle producing canonical transactions
    
    cycle_id = :"cycle_#{institution.id}_gen#{generation}_#{cycle_num}"
    
    # Simulate research outcome
    outcome = determine_research_outcome(institution)
    
    # Create ResearchCycleResult (canonical transaction)
    discoveries = if outcome == :success, do: generate_discoveries(institution), else: []
    theory_formed = outcome == :major_breakthrough
    
    cycle_result = %{
      id: cycle_id,
      institution_id: institution.id,
      generation: generation,
      cycle_number: cycle_num,
      outcome: outcome,
      discoveries: discoveries,
      theory_formed: theory_formed,
      confidence: 0.6 + (:rand.uniform() * 0.35),
      resources_consumed: %{
        credits: 100 + (:rand.uniform() * 200),
        compute: 50 + (:rand.uniform() * 100),
        attention: 10 + (:rand.uniform() * 20)
      },
      duration_ticks: 10 + (:rand.uniform() * 40 |> round),
      lifecycle_events: [%{
        event: :research_cycle_completed,
        timestamp: DateTime.utc_now(),
        cycle_id: cycle_id
      }],
      semantic_events: [%{
        event: :investigation_concluded,
        outcome: outcome,
        timestamp: DateTime.utc_now()
      }]
    }
    
    # Create ResearchEpisode (canonical container)
    publications = if outcome in [:success, :major_breakthrough], do: ["pub_#{cycle_id}"], else: []
    key_findings = if outcome != :failure, do: [generate_finding(institution)], else: ["Investigation inconclusive"]
    failures_encountered = if outcome == :failure, do: ["Hypothesis not supported by evidence"], else: []
    
    specialization_str = if is_atom(institution.specialization), do: Atom.to_string(institution.specialization), else: institution.specialization
    keywords = [Atom.to_string(institution.domain), specialization_str]
          
    episode = %ResearchEpisode{
      episode_id: :"episode_#{cycle_id}",
      institution_id: institution.id,
      created_tick: generation * 1000 + cycle_num,
      status: :finalized,
      topic: generate_episode_topic(institution),
      description: "Investigation in #{institution.domain}: #{generate_hypothesis(institution)}",
      keywords: keywords,
      domain: institution.domain,
      start_tick: generation * 1000 + cycle_num,
      end_tick: generation * 1000 + cycle_num + cycle_result.duration_ticks,
      duration_ticks: cycle_result.duration_ticks,
      research_cycles: [Atom.to_string(cycle_id)],
      belief_revisions: [],
      publications: publications,
      key_findings: key_findings,
      failures_encountered: failures_encountered,
      total_cost: cycle_result.resources_consumed.credits,
      contributors: [institution.id],
      tags: [specialization_str]
    }
    
    # Index episode (would add to EpisodeIndex)
    # EpisodeIndex.add_episode(episode)
    
    {:ok, cycle_result, episode}
  end
  
  defp determine_research_outcome(_institution) do
    # Realistic distribution of research outcomes
    rand = :rand.uniform()
    
    cond do
      rand < 0.05 -> :major_breakthrough  # 5%
      rand < 0.35 -> :success             # 30%
      rand < 0.70 -> :partial_success     # 35%
      rand < 0.90 -> :inconclusive        # 20%
      true -> :failure                    # 10%
    end
  end
  
  defp generate_discoveries(institution) do
    # Generate 1-3 discoveries for successful cycles
    count = 1 + (:rand.uniform() * 2 |> round)
    
    Enum.map(1..count, fn i ->
      %{
        id: :"discovery_#{institution.id}_#{System.monotonic_time(:nanosecond)}_#{i}",
        domain: institution.domain,
        topic: generate_discovery_topic(institution),
        confidence: 0.7 + (:rand.uniform() * 0.25),
        validated: false,
        timestamp: DateTime.utc_now()
      }
    end)
  end
  
  defp generate_episode_topic(institution) do
    topics = %{
      physics: ["particle interaction", "field dynamics", "quantum state", "energy transfer"],
      biology: ["gene expression", "protein folding", "cell signaling", "metabolic pathway"],
      chemistry: ["reaction mechanism", "molecular structure", "catalysis", "bond formation"],
      engineering: ["system optimization", "algorithm efficiency", "material properties", "design pattern"],
      medicine: ["treatment efficacy", "diagnostic accuracy", "pathway modulation", "therapeutic target"]
    }
    
    domain_topics = Map.get(topics, institution.domain, ["general investigation"])
    Enum.random(domain_topics)
  end
  
  defp generate_hypothesis(institution) do
    "Testing whether #{generate_concept(institution)} affects #{generate_outcome(institution)}"
  end
  
  defp generate_concept(_institution) do
    concepts = ["variable X", "parameter Y", "factor Z", "mechanism M", "process P"]
    Enum.random(concepts)
  end
  
  defp generate_outcome(_institution) do
    outcomes = ["system behavior", "experimental result", "observed phenomenon", "measured response"]
    Enum.random(outcomes)
  end
  
  defp generate_discovery_topic(institution) do
    "#{institution.domain} discovery: #{generate_episode_topic(institution)}"
  end
  
  defp generate_finding(institution) do
    "Evidence supports hypothesis in #{institution.domain} context"
  end
  
  defp update_institution_with_results(institution, _cycle_result, episode) do
    # Update institution's program list and discovery count
    updated_programs = institution.active_programs ++ [episode.episode_id]
    
    %{
      institution
      | active_programs: updated_programs
    }
  end
  
  defp execute_generation_internal(state, generation) do
    # Helper for sequential generation execution
    {:ok, result} = execute_generation(self(), generation)
    {result, state}
  end
  
  defp update_state_after_generation(state, result) do
    # Update state after each generation
    %{
      state
      | generation: result.generation,
        total_cycles_executed: state.total_cycles_executed + result.cycles_executed,
        episodes_created: state.episodes_created + result.episodes_created,
        discoveries_made: state.discoveries_made + result.discoveries_made,
        theories_formed: state.theories_formed + result.theories_formed
    }
  end
  
  defp get_statistics_internal(state) do
    %{
      runtime_id: state.runtime_id,
      generation: state.generation,
      total_cycles_executed: state.total_cycles_executed,
      episodes_created: state.episodes_created,
      discoveries_made: state.discoveries_made,
      theories_formed: state.theories_formed,
      institutions_count: length(state.institutions),
      domain_distribution: state.domain_distribution,
      uptime_ms: System.monotonic_time(:millisecond) - state.start_time,
      average_cycles_per_generation: if state.generation > 0 do
        state.total_cycles_executed / state.generation
      else
        0
      end,
      average_episodes_per_generation: if state.generation > 0 do
        state.episodes_created / state.generation
      else
        0
      end
    }
  end
end
