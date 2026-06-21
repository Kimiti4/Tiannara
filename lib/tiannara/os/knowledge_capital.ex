defmodule TiannaraOS.KnowledgeCapital do
  @moduledoc """
  Calculates and manages knowledge capital for Research Programs.
  
  Knowledge capital determines funding allocation and program survival.
  Programs with higher capital get more resources, creating selection pressure.
  """
  
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.State
  
  @doc """
  Calculate knowledge capital for a research program.
  
  Formula:
    (validated_discoveries * 10) +
    (active_theories * 5) +
    (replication_success_rate * 20) +
    (influence_score)
  """
  @spec calculate_capital(ResearchProgram.t(), State.t()) :: float()
  def calculate_capital(%ResearchProgram{} = program, %State{} = state) do
    validated_count = length(program.discoveries)
    
    # Count active theories in program's domain
    active_theories = count_active_theories(program, state)
    
    # Replication success rate from metrics
    replication_rate = program.metrics.replication_rate
    
    # Influence score based on citations/connections
    influence = calculate_influence(program, state)
    
    capital = 
      (validated_count * 10.0) +
      (active_theories * 5.0) +
      (replication_rate * 20.0) +
      influence
    
    max(capital, 0.0)  # Ensure non-negative
  end
  
  @doc """
  Allocate funding to programs based on their relative knowledge capital.
  
  Returns updated state with adjusted funding_scores.
  """
  @spec allocate_funding(State.t()) :: State.t()
  def allocate_funding(%State{} = state) do
    programs = state.research_programs
    
    if map_size(programs) == 0 do
      state
    else
      # Calculate total capital across all programs
      total_capital = 
        programs
        |> Map.values()
        |> Enum.reduce(0.0, fn prog, acc ->
          acc + calculate_capital(prog, state)
        end)
      
      if total_capital == 0 do
        # Equal distribution if no capital yet
        distribute_equally(state)
      else
        # Proportional distribution based on capital share
        distribute_proportionally(state, total_capital)
      end
    end
  end
  
  @doc """
  Update program metrics after validation event.
  
  Tracks conversion rate and strategy effectiveness.
  """
  @spec update_after_validation(ResearchProgram.t(), boolean()) :: ResearchProgram.t()
  def update_after_validation(%ResearchProgram{} = program, validated?) do
    candidates = program.metrics.candidates_produced + 1
    validated_count = 
      if validated? do
        program.metrics.candidates_validated + 1
      else
        program.metrics.candidates_validated
      end
    
    conversion_rate = 
      if candidates > 0 do
        validated_count / candidates
      else
        0.0
      end
    
    new_metrics = %{
      program.metrics |
      candidates_produced: candidates,
      candidates_validated: validated_count,
      conversion_rate: conversion_rate
    }
    
    %ResearchProgram{program | metrics: new_metrics}
  end
  
  @doc """
  Update retention rate after shock event.
  
  Measures how many validated discoveries survived the shock.
  """
  @spec update_retention_after_shock(ResearchProgram.t(), integer(), integer()) :: ResearchProgram.t()
  def update_retention_after_shock(%ResearchProgram{} = program, surviving, total_before) do
    retention_rate = 
      if total_before > 0 do
        surviving / total_before
      else
        1.0  # No losses if nothing to lose
      end
    
    new_metrics = %{
      program.metrics |
      retention_rate: retention_rate
    }
    
    %ResearchProgram{program | metrics: new_metrics}
  end
  
  @doc """
  Record recovery time for a program.
  
  Used to measure adaptation across shocks.
  """
  @spec record_recovery_time(ResearchProgram.t(), integer()) :: ResearchProgram.t()
  def record_recovery_time(%ResearchProgram{} = program, ticks_to_recover) do
    new_metrics = %{
      program.metrics |
      recovery_time_ticks: ticks_to_recover
    }
    
    %ResearchProgram{program | metrics: new_metrics}
  end
  
  @doc """
  Update strategy effectiveness based on performance.
  
  Higher effectiveness → more funding in next allocation cycle.
  """
  @spec update_strategy_effectiveness(ResearchProgram.t(), float()) :: ResearchProgram.t()
  def update_strategy_effectiveness(%ResearchProgram{} = program, effectiveness_score) do
    # Blend old and new scores (70% historical, 30% recent)
    blended = 
      (program.metrics.strategy_effectiveness * 0.7) +
      (effectiveness_score * 0.3)
    
    new_metrics = %{
      program.metrics |
      strategy_effectiveness: blended
    }
    
    %ResearchProgram{program | metrics: new_metrics}
  end
  
  # --- PRIVATE HELPERS ---
  
  defp count_active_theories(%ResearchProgram{} = _program, %State{} = state) do
    # For now, return simple count of theories in evidence graph
    # In future, filter by program's domain/relevance
    state.evidence_graph
    |> Map.values()
    |> Enum.count(fn node -> node.type == :theory end)
  end
  
  defp calculate_influence(%ResearchProgram{} = program, %State{} = _state) do
    # Simple influence metric: number of discoveries owned
    # Future: track citations, cross-program references, etc.
    length(program.discoveries) * 2.0
  end
  
  defp distribute_equally(%State{} = state) do
    programs = state.research_programs
    
    updated_programs = 
      programs
      |> Map.values()
      |> Enum.reduce(programs, fn prog, acc ->
        equal_score = 1.0 / map_size(programs)
        updated = %ResearchProgram{prog | funding_score: equal_score}
        Map.put(acc, prog.id, updated)
      end)
    
    %State{state | research_programs: updated_programs}
  end
  
  defp distribute_proportionally(%State{} = state, total_capital) do
    programs = state.research_programs
    
    updated_programs = 
      programs
      |> Map.values()
      |> Enum.reduce(programs, fn prog, acc ->
        prog_capital = calculate_capital(prog, state)
        funding_share = prog_capital / total_capital
        
        updated = %ResearchProgram{prog | funding_score: funding_share}
        Map.put(acc, prog.id, updated)
      end)
    
    %State{state | research_programs: updated_programs}
  end
end
