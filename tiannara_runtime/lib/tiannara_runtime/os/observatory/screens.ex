defmodule TiannaraRuntime.OS.Observatory.Screens do
  @moduledoc """
  Observatory Screens Coordinator

  Coordinates data retrieval for all 12 instrument screens.
  Each screen is implemented as a separate module.
  """

  alias TiannaraRuntime.OS.Observatory.Screens.{
    Screen01ConstitutionalHealth,
    Screen02ScientificDiscovery,
    Screen03Engineering,
    Screen04KnowledgeGrowth,
    Screen05OntologyEvolution,
    Screen06TheoryEcology,
    Screen07RuntimeEvolution,
    Screen08DiscoveryPipeline,
    Screen09LongTermMetrics,
    Screen10Evolution,
    Screen11PlanetaryTwin,
    Screen12MissionTimeline
  }

  @doc """
  Returns data for a specific screen.
  """
  def get_screen_data(screen_number, metrics, artifact_storage) do
    case screen_number do
      1 -> Screen01ConstitutionalHealth.get_data(metrics)
      2 -> Screen02ScientificDiscovery.get_data(metrics, artifact_storage)
      3 -> Screen03Engineering.get_data(metrics, artifact_storage)
      4 -> Screen04KnowledgeGrowth.get_data(metrics, artifact_storage)
      5 -> Screen05OntologyEvolution.get_data(artifact_storage)
      6 -> Screen06TheoryEcology.get_data(artifact_storage)
      7 -> Screen07RuntimeEvolution.get_data(artifact_storage)
      8 -> Screen08DiscoveryPipeline.get_data(artifact_storage)
      9 -> Screen09LongTermMetrics.get_data(metrics)
      10 -> Screen10Evolution.get_data(artifact_storage)
      11 -> Screen11PlanetaryTwin.get_data(metrics)
      12 -> Screen12MissionTimeline.get_data(artifact_storage)
    end
  end
end
