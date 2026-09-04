defmodule Tiannara.ASC.Civilization.AdaptiveOrchestrator do
  @moduledoc """
  Phase 15: Assembles mission pipelines using fitness-weighted capability selection.
  Balances exploitation (proven capabilities) with exploration (new/LLM-synthesized).
  Considers Ecological Niches for selection.
  """
  alias Tiannara.ASC.Ecology.{CapabilityRegistry, CapabilityFitness}
  require Logger

  @exploration_rate 0.15 # 15% chance to try lower-fitness or new capabilities

  def execute(task, mission_context) do
    Logger.info("🌊 [AdaptiveOrchestrator] Assembling fitness-weighted pipeline...")
    
    baseline_roles = CapabilityRegistry.get_by_type(:agent_role)
    candidate_tools = CapabilityRegistry.match_triggers(mission_context)
    
    # Fitness-weighted selection for cognitive tools, using the relevant Niche
    target_niche = determine_niche(mission_context)
    selected_tools = select_by_fitness(candidate_tools, target_niche)
    
    pipeline = inject_tools_into_roles(baseline_roles, selected_tools)
    Logger.info("   🧬 Adaptive Pipeline: #{Enum.map_join(pipeline, " -> ", & &1.name)} (Niche: #{target_niche})")
    
    run_pipeline(task, pipeline)
  end

  defp determine_niche(context) do
    cond do
      context[:type] == :research -> :research
      context[:type] == :infrastructure -> :infrastructure
      context[:type] == :governance -> :governance
      true -> :mission
    end
  end

  defp select_by_fitness(candidates, niche) do
    if Enum.empty?(candidates), do: []
    
    # Get fitness scores for the specific niche
    scored = Enum.map(candidates, fn cap ->
      profile = CapabilityRegistry.get_fitness(cap.id) || %CapabilityFitness{overall_fitness: 1.0}
      score = get_niche_score(profile, niche)
      {cap, score}
    end)
    
    # Apply exploration/exploitation balance
    if :rand.uniform() < @exploration_rate do
      # Exploration: pick randomly to give new/LLM capabilities a chance
      [elem(Enum.random(scored), 0)]
    else
      # Exploitation: pick highest fitness in this niche
      scored 
      |> Enum.sort_by(fn {_cap, score} -> score end, :desc) 
      |> Enum.take(2) 
      |> Enum.map(fn {cap, _} -> cap end)
    end
  end

  defp get_niche_score(profile, :mission), do: profile.mission_fitness || 1.0
  defp get_niche_score(profile, :research), do: profile.research_fitness || 1.0
  defp get_niche_score(profile, :infrastructure), do: profile.infrastructure_fitness || 1.0
  defp get_niche_score(profile, :governance), do: profile.governance_fitness || 1.0

  defp inject_tools_into_roles(roles, tools) do
    architects = Enum.filter(roles, & &1.name == "Architect")
    coders = Enum.filter(roles, & &1.name == "Coder")
    auditors = Enum.filter(roles, & &1.name == "Auditor")
    architects ++ tools ++ coders ++ auditors
  end

  defp run_pipeline(task, []), do: task
  defp run_pipeline(task, [cap | rest]) do
    Logger.info("   ⚙️ Executing: #{cap.name} (Lineage: #{cap.lineage || :human_seeded})")
    run_pipeline(cap.implementation.(task), rest)
  end
end
