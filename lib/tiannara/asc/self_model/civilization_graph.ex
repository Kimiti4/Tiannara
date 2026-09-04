defmodule Tiannara.ASC.SelfModel.CivilizationGraph do
  @moduledoc """
  Phase 17: The Epistemic Mirror.
  Constructs a unified, real-time graph of the civilization's anatomy, 
  mapping dependencies, utility flows, and cognitive load.
  """
  alias Tiannara.ASC.Ecology.CapabilityRegistry
  alias Tiannara.ASC.Laws.Registry
  alias Tiannara.ASC.Research.ResearchRegistry
  require Logger

  defstruct [
    :capabilities,
    :laws,
    :programs,
    :utility_flows,
    :cognitive_load,
    :generated_at
  ]

  def build_mirror do
    Logger.info("🪞 [SelfModel] Constructing Civilizational Mirror...")
    
    caps = CapabilityRegistry.get_all()
    laws = Registry.get_all_active_laws()
    progs = ResearchRegistry.get_all_programs()
    
    # Calculate cognitive load (e.g., total active capabilities vs context window limits)
    cognitive_load = calculate_cognitive_load(caps)
    
    # Map utility flows (which capabilities are actually generating the ROI?)
    utility_flows = map_utility_concentration(caps)
    
    %__MODULE__{
      capabilities: caps,
      laws: laws,
      programs: progs,
      utility_flows: utility_flows,
      cognitive_load: cognitive_load,
      generated_at: System.system_time(:millisecond)
    }
  end

  defp calculate_cognitive_load(caps) do
    active_caps = Enum.count(caps, & &1.status == :active)
    # Assuming a safe context window limit of 50 active cognitive organs
    min(1.0, active_caps / 50.0) 
  end

  defp map_utility_concentration(caps) do
    total_utility = Enum.sum(Enum.map(caps, & &1.fitness_impact))
    
    if total_utility == 0 do
      %{}
    else
      caps
      |> Enum.map(fn cap -> {cap.id, cap.fitness_impact / total_utility} end)
      |> Map.new()
    end
  end
end
