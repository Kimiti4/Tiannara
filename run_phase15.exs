defmodule Tiannara.ASC.Ecology.CapabilityLifecycleCampaign do
  @moduledoc """
  Phase 15: Runs a multi-epoch campaign demonstrating Capability Darwinism.
  Tracks birth, competition, extinction, and speciation across real missions.
  Incorporates multi-niche fitness tracking.
  """
  alias Tiannara.ASC.Ecology.{Capability, CapabilityDarwinismEngine, CapabilityRegistry}
  require Logger

  def run do
    Logger.info("🌍 [Phase 15] Initiating Capability Darwinism Campaign")
    
    # 1. Start Ecology
    Tiannara.ASC.Ecology.CapabilityRegistry.start_link([])

    # Seed an LLM invention for testing
    CapabilityRegistry.register(%Capability{
      id: "llm_dep_drift",
      name: "Dependency Drift Analyst",
      type: :cognitive_tool,
      trigger_condition: %{mission_type: :api_migration},
      implementation: fn task -> Map.put(task, :analyzed, true) end,
      lineage: :llm_synthesis
    })

    # Simulate 12 epochs of missions to allow protection period to expire
    epoch_telemetry = simulate_epochs(1..12)
    
    # Apply selection pressure after each epoch
    Enum.each(epoch_telemetry, fn {epoch_num, telemetry} ->
      Logger.info("\n📊 [Phase 15] === EPOCH #{epoch_num} SELECTION ===")
      CapabilityDarwinismEngine.apply_selection_pressure(telemetry)
      print_ecology_state()
    end)
    
    Logger.info("\n🏆 [Phase 15] Capability Darwinism Campaign Complete.")
  end

  defp simulate_epochs(epochs) do
    Enum.map(epochs, fn epoch_num ->
      {epoch_num, simulate_epoch(epoch_num)}
    end)
  end

  defp simulate_epoch(epoch_num) do
    # Simulated mission outcomes for capabilities
    # Niche matters here.
    %{
      "base_code" => %{niche: :mission, success: true, compute: 120, utility: 15.0},
      "base_arch" => %{niche: :infrastructure, success: true, compute: 200, utility: 10.0},
      "llm_dep_drift" => %{niche: :mission, success: epoch_num < 4, compute: 300, utility: if(epoch_num < 4, do: 5.0, else: -10.0)},
      # Introduce a hypothetical hybrid in later epochs to show survival of the fittest
      "hybrid_arch_x_drift" => if(epoch_num > 6, do: %{niche: :mission, success: true, compute: 180, utility: 22.0}, else: %{niche: :mission, success: false, compute: 0, utility: 0.0})
    }
  end

  defp print_ecology_state do
    profiles = CapabilityRegistry.get_all_fitness_profiles()
    Logger.info("   📈 Active Capabilities: #{length(profiles)}")
    Enum.each(profiles, fn {id, p} ->
      Logger.info("      #{id} | Overall Fitness: #{Float.round(p.overall_fitness, 2)} | Extinction Risk: #{Float.round(p.extinction_risk, 2)} | Lineage: #{p.lineage}")
    end)
  end
end

Tiannara.ASC.Ecology.CapabilityLifecycleCampaign.run()
