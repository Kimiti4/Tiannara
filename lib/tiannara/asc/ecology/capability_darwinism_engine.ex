defmodule Tiannara.ASC.Ecology.CapabilityDarwinismEngine do
  @moduledoc """
  Phase 15: Applies evolutionary selection pressure to the Capability Ecology.
  Handles fitness evaluation, extinction, reproduction, and hybridization across 4 Niches.
  """
  alias Tiannara.ASC.Ecology.{Capability, CapabilityFitness, CapabilityRegistry}
  alias Tiannara.ASC.Memory.InstitutionalMemory
  require Logger

  @extinction_threshold 0.85
  @reproduction_threshold 8.0
  @hybridization_rate 0.3

  @doc """
  Runs at the end of each civilizational epoch. Evaluates all capabilities,
  applies selection pressure, and evolves the ecology.
  """
  def apply_selection_pressure(epoch_telemetry) do
    Logger.info("🧬 [DarwinismEngine] Applying evolutionary selection pressure...")
    
    profiles = CapabilityRegistry.get_all_fitness_profiles()
    
    # 1. Update fitness with real mission outcomes
    updated_profiles = Enum.map(profiles, fn {cap_id, profile} ->
      telemetry = Map.get(epoch_telemetry, cap_id, %{niche: :mission, success: false, compute: 0, utility: 0.0})
      # Skip if no telemetry for this epoch
      if telemetry.compute == 0 and telemetry.utility == 0.0 do
        {cap_id, profile}
      else
        {cap_id, CapabilityFitness.record_outcome(profile, telemetry.niche, telemetry.success, telemetry.compute, telemetry.utility)}
      end
    end)
    
    # 2. Apply extinction (Conservative)
    {survivors, extinct} = Enum.split_with(updated_profiles, fn {_id, p} -> p.extinction_risk < @extinction_threshold end)
    archive_extinct(extinct)
    
    # 3. Apply reproduction & hybridization
    top_performers = Enum.filter(survivors, fn {_id, p} -> p.overall_fitness >= @reproduction_threshold end)
    spawn_hybrids(top_performers)
    
    # 4. Persist updated profiles
    Enum.each(survivors, fn {cap_id, profile} -> CapabilityRegistry.update_fitness(cap_id, profile) end)
    
    Logger.info("✅ [DarwinismEngine] Selection complete. #{length(extinct)} extinct, #{length(top_performers)} eligible for reproduction.")
  end

  defp archive_extinct(extinct_list) do
    Enum.each(extinct_list, fn {cap_id, profile} ->
      Logger.warning("💀 [DarwinismEngine] EXTINCTION: #{cap_id} (Risk: #{Float.round(profile.extinction_risk, 2)})")
      CapabilityRegistry.archive_capability(cap_id)
      
      # Fossil Record Write
      InstitutionalMemory.record_rejected_hypothesis(
        cap_id,
        "Capability extinct. Used in #{profile.missions_used} missions. Failures: #{profile.failures}. " <>
        "Overall Fitness: #{Float.round(profile.overall_fitness, 2)}. " <>
        "High extinction risk (#{Float.round(profile.extinction_risk, 2)}) triggered culling."
      )
    end)
  end

  defp spawn_hybrids(top_performers) do
    if length(top_performers) >= 2 and :rand.uniform() < @hybridization_rate do
      [{id_a, _prof_a}, {id_b, _prof_b} | _] = Enum.sort_by(top_performers, fn {_id, p} -> p.overall_fitness end, :desc)
      
      cap_a = CapabilityRegistry.get_capability(id_a)
      cap_b = CapabilityRegistry.get_capability(id_b)
      
      if cap_a && cap_b do
        hybrid = %Capability{
          id: "hybrid_#{:erlang.unique_integer([:positive])}",
          name: "#{cap_a.name} x #{cap_b.name}",
          type: cap_a.type,
          trigger_condition: Map.merge(cap_a.trigger_condition || %{}, cap_b.trigger_condition || %{}),
          implementation: fn task -> cap_a.implementation.(task) |> cap_b.implementation.() end,
          lineage: :hybrid
        }
        
        CapabilityRegistry.register(hybrid)
        Logger.info("🌟 [DarwinismEngine] HYBRIDIZATION: #{hybrid.name} spawned from top performers.")
      end
    end
  end
end
