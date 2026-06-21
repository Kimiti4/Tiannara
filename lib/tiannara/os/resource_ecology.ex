defmodule TiannaraOS.ResourceEcology do
  @moduledoc """
  Manages resource consumption and production in research ecosystems.
  
  Programs don't die from arbitrary caps—they die from resource exhaustion.
  Strong programs survive by producing discoveries that generate royalties.
  
  This creates natural selection based on economic viability, not artificial limits.
  """
  
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.State
  
  @type resource_type :: :funding | :compute | :attention | :credibility
  @type t :: %{
    funding: float(),
    compute: float(),
    attention: float(),
    credibility: float()
  }
  
  @doc """
  Calculate resource consumption for a program based on its strategy genome.
  
  Different strategies have different resource costs:
  - Explorers: High experiment cost, low validation cost
  - Validators: Low experiment cost, high validation cost
  - Synthesizers: Moderate costs across all dimensions
  """
  @spec calculate_resource_consumption(ResearchProgram.t()) :: t()
  def calculate_resource_consumption(%ResearchProgram{strategy_genome: genome}) do
    # Exploration is expensive but not prohibitive
    exploration_cost = genome.exploration_rate * 0.06
    
    # Validation is moderate (replication studies)
    validation_cost = genome.validation_priority * 0.04
    
    # Synthesis is expensive (cross-domain integration requires expertise)
    synthesis_cost = genome.cross_domain_synthesis * 0.05
    
    # Anomaly hunting is moderately expensive
    anomaly_cost = genome.anomaly_sensitivity * 0.04
    
    total_experiment_cost = exploration_cost + anomaly_cost
    total_validation_cost = validation_cost + synthesis_cost
    
    %{
      funding: total_experiment_cost + total_validation_cost,
      compute: total_experiment_cost * 2.0 + total_validation_cost * 0.8,
      attention: total_experiment_cost * 1.0 + total_validation_cost * 1.2,
      credibility: 0.02  # Credibility drain increases with activity
    }
  end
  
  @doc """
  Calculate resource production from validated discoveries.
  
  Each validated discovery generates royalties that replenish resources.
  High-quality discoveries (high confidence) generate more resources.
  """
  @spec calculate_resource_production(ResearchProgram.t(), State.t()) :: t()
  def calculate_resource_production(%ResearchProgram{} = program, %State{} = state) do
    # Count newly validated discoveries this cycle
    new_discoveries = program.metrics.candidates_validated
    
    if new_discoveries == 0 do
      %{funding: 0.0, compute: 0.0, attention: 0.0, credibility: 0.0}
    else
      # Calculate average quality of discoveries
      avg_confidence = calculate_avg_discovery_confidence(program, state)
      
      # Royalty formula: quality × quantity × base_rate
      # Base rate is LOW to create economic pressure
      base_royalty_rate = 0.03
      
      %{
        funding: new_discoveries * avg_confidence * base_royalty_rate * 1.5,
        compute: new_discoveries * avg_confidence * base_royalty_rate * 1.2,
        attention: new_discoveries * avg_confidence * base_royalty_rate * 0.8,
        credibility: new_discoveries * avg_confidence * base_royalty_rate * 0.4
      }
    end
  end
  
  @doc """
  Calculate ROI (Return on Investment) for a program.
  
  ROI > 1.0 → Program is profitable, will survive
  ROI < 1.0 → Program is losing resources, may die
  ROI < 0.5 → Program is failing, likely to die soon
  """
  @spec calculate_roi(t(), t()) :: float()
  def calculate_roi(%{} = production, %{} = consumption) do
    total_production = production.funding + production.compute + production.attention
    total_consumption = consumption.funding + consumption.compute + consumption.attention
    
    if total_consumption == 0 do
      1.0  # No consumption = infinite ROI (shouldn't happen)
    else
      total_production / total_consumption
    end
  end
  
  @doc """
  Apply resource economics to a program.
  
  Returns updated program with adjusted budget and survival status.
  """
  @spec apply_resource_economics(ResearchProgram.t(), State.t()) :: ResearchProgram.t()
  def apply_resource_economics(%ResearchProgram{} = program, %State{} = state) do
    consumption = calculate_resource_consumption(program)
    production = calculate_resource_production(program, state)
    roi = calculate_roi(production, consumption)
    
    # Update budget based on net resource flow
    net_funding = production.funding - consumption.funding
    net_compute = production.compute - consumption.compute
    net_attention = production.attention - consumption.attention
    
    updated_budget = %{
      credits: max(program.budget.credits + net_funding, 0.0),
      compute: max(program.budget.compute + net_compute, 0.0),
      attention: max(program.budget.attention + net_attention, 0.0)
    }
    
    # Determine survival based on ROI and resource levels
    survival_status = determine_survival(program, roi, updated_budget)
    
    %ResearchProgram{
      program |
      budget: updated_budget,
      status: survival_status.status,
      outcome: survival_status.outcome,
      metrics: Map.put(program.metrics, :roi, roi)
    }
  end
  
  @doc """
  Determine if a program survives based on ROI and resource levels.

  Survival is gated by developmental stage — younger programs are protected
  to allow an actual developmental economy to form:

  - :newborn    → fully immune (survive at all costs)
  - :juvenile   → fully immune (acquiring capabilities, not yet productive)
  - :apprentice → only credits checked (building first economic output)
  - :adult      → full pressure (credits + compute + attention + ROI)
  """
  @spec determine_survival(ResearchProgram.t(), float(), map()) :: %{status: atom(), outcome: atom()}
  def determine_survival(%ResearchProgram{} = program, roi, budget) do
    life_stage = program.life_stage || :adult
    min_resources = 0.1

    case life_stage do
      stage when stage in [:newborn, :juvenile] ->
        # DEVELOPMENTAL IMMUNITY: Never suspended by resource economics
        %{status: :active, outcome: nil}

      :apprentice ->
        # PARTIAL PRESSURE: Only credit starvation can kill apprentices
        # compute/attention/ROI checks are waived — they're still learning to produce
        if budget.credits < min_resources do
          %{status: :suspended, outcome: :resource_exhaustion}
        else
          %{status: :active, outcome: nil}
        end

      _adult ->
        # FULL SELECTION PRESSURE: All resource dimensions enforced
        cond do
          budget.credits < min_resources or budget.compute < min_resources or budget.attention < min_resources ->
            %{status: :suspended, outcome: :resource_exhaustion}
          roi < 0.3 ->
            %{status: :suspended, outcome: :economic_failure}
          true ->
            %{status: :active, outcome: nil}
        end
    end
  end
  
  @doc """
  Calculate average confidence of program's discoveries.
  """
  @spec calculate_avg_discovery_confidence(ResearchProgram.t(), State.t()) :: float()
  defp calculate_avg_discovery_confidence(%ResearchProgram{} = program, %State{} = state) do
    if length(program.discoveries) == 0 do
      0.5  # Default moderate confidence
    else
      confidences = Enum.map(program.discoveries, fn disc_id ->
        case Map.get(state.discoveries, disc_id) do
          nil -> 0.5
          discovery -> discovery.confidence
        end
      end)
      
      Enum.sum(confidences) / length(confidences)
    end
  end
  
  @doc """
  Replenish world resources periodically.
  
  Worlds receive baseline resource injections to prevent total collapse.
  This simulates external funding sources (government grants, private investment).
  """
  @spec replenish_world_resources(State.t(), atom(), float()) :: State.t()
  def replenish_world_resources(%State{} = state, world_id, replenishment_rate) do
    programs_in_world = get_programs_in_world(state, world_id)
    
    updated_programs = Enum.reduce(programs_in_world, state.research_programs, fn prog, acc_programs ->
      if prog.status == :active do
        # Add baseline resources proportional to past performance
        performance_bonus = prog.metrics.strategy_effectiveness * replenishment_rate
        
        updated_budget = %{
          prog.budget |
          credits: prog.budget.credits + performance_bonus,
          compute: prog.budget.compute + (performance_bonus * 0.5),
          attention: prog.budget.attention + (performance_bonus * 0.3)
        }
        
        updated_prog = %ResearchProgram{prog | budget: updated_budget}
        Map.put(acc_programs, prog.id, updated_prog)
      else
        acc_programs
      end
    end)
    
    %{state | research_programs: updated_programs}
  end
  
  @doc """
  Get all active programs in a specific world.
  """
  @spec get_programs_in_world(State.t(), atom()) :: [ResearchProgram.t()]
  defp get_programs_in_world(%State{} = state, world_id) do
    state.research_programs
    |> Map.values()
    |> Enum.filter(fn prog ->
      prog.world_id == world_id and prog.status == :active
    end)
  end
end
