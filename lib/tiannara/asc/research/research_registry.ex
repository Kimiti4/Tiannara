defmodule Tiannara.ASC.Research.ResearchRegistry do
  @moduledoc """
  Phase 6: Manages competing research programs and their resource allocation.
  Tracks program fitness and enables evolutionary selection of scientific methodologies.
  """
  use GenServer
  require Logger

  @table_name :research_programs

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table_name, [:named_table, :set, :public])
    :ets.new(:research_genomes, [:named_table, :set, :public])
    {:ok, %{epoch: 0, total_budget: 10000}}
  end

  @doc """
  Registers a new research program.
  """
  def register_program(%Tiannara.ASC.Research.ResearchProgram{} = program) do
    program = %{program | 
      id: program.id || generate_program_id(program.name),
      created_at: System.system_time(:millisecond),
      last_active: System.system_time(:millisecond)
    }
    :ets.insert(@table_name, {program.id, program})
    Logger.info("🔬 [ResearchRegistry] Registered program: #{program.name} (Domain: #{program.domain})")
    {:ok, program.id}
  end

  @doc """
  Updates program metrics after an epoch of research.
  """
  def update_program_metrics(program_id, metrics) do
    case :ets.lookup(@table_name, program_id) do
      [{^program_id, program}] ->
        updated = %{program |
          experiments_run: program.experiments_run + Map.get(metrics, :experiments_run, 0),
          laws_generated: program.laws_generated + Map.get(metrics, :laws_generated, 0),
          laws_survived: program.laws_survived + Map.get(metrics, :laws_survived, 0),
          utility_generated: program.utility_generated + Map.get(metrics, :utility_generated, 0.0),
          compute_consumed: program.compute_consumed + Map.get(metrics, :compute_consumed, 0),
          last_active: System.system_time(:millisecond)
        }
        
        # Calculate program fitness
        fitness = calculate_fitness(updated)
        updated = %{updated | program_fitness: fitness}
        
        :ets.insert(@table_name, {program_id, updated})
        {:ok, updated}
        
      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Returns all active research programs sorted by fitness.
  """
  def get_programs_by_fitness do
    :ets.tab2list(@table_name)
    |> Enum.map(fn {_id, program} -> program end)
    |> Enum.sort_by(& &1.program_fitness, :desc)
  end

  @doc """
  Phase 8A: Stores surviving ResearchGenomes from a MetaScienceCampaign epoch.
  """
  def store_surviving_genomes(genomes) do
    Enum.each(genomes, fn genome ->
      :ets.insert(:research_genomes, {genome.id, genome})
    end)
    :ok
  end

  @doc """
  Phase 8A: Retrieves surviving ResearchGenomes to be used for Autonomous Engineering.
  """
  def get_surviving_genomes do
    :ets.tab2list(:research_genomes)
    |> Enum.map(fn {_id, genome} -> genome end)
    |> Enum.filter(&(&1.status == :active))
  end

  @doc """
  Phase 8A: Applies Engineering ROI back to the originating ResearchGenome's fitness.
  """
  def apply_engineering_roi(genome_id, roi) do
    case :ets.lookup(:research_genomes, genome_id) do
      [{^genome_id, genome}] ->
        updated = %{genome | fitness: genome.fitness + roi}
        :ets.insert(:research_genomes, {genome_id, updated})
        {:ok, updated}
      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Calculates resource allocation for the next epoch based on program fitness.
  Higher fitness programs receive larger budgets.
  """
  def allocate_resources(total_budget) do
    programs = get_programs_by_fitness()
    
    if Enum.empty?(programs) do
      %{}
    else
      total_fitness = Enum.sum(Enum.map(programs, & &1.program_fitness))
      
      Enum.reduce(programs, %{}, fn program, acc ->
        fitness_share = if total_fitness > 0, do: program.program_fitness / total_fitness, else: 1.0 / length(programs)
        allocated_budget = trunc(total_budget * fitness_share)
        
        Map.put(acc, program.id, allocated_budget)
      end)
    end
  end

  defp calculate_fitness(program) do
    # Composite fitness: Utility per compute + Law survival rate + Experiment efficiency
    utility_per_compute = if program.compute_consumed > 0, 
      do: program.utility_generated / program.compute_consumed, 
      else: 0.0
    
    law_survival_rate = if program.laws_generated > 0,
      do: program.laws_survived / program.laws_generated,
      else: 0.0
    
    experiment_efficiency = if program.experiments_run > 0,
      do: program.laws_generated / program.experiments_run,
      else: 0.0
    
    # Weighted composite (utility is most important)
    (utility_per_compute * 100) + (law_survival_rate * 50) + (experiment_efficiency * 20)
  end

  defp generate_program_id(name) do
    "prog_#{name |> String.downcase() |> String.replace(" ", "_")}_#{:erlang.unique_integer([:positive])}"
  end
end
