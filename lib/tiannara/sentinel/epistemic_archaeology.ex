defmodule Tiannara.Sentinel.EpistemicArchaeology do
  @moduledoc """
  SEA-4: Searches extinct civilizations for useful lost knowledge.
  Identifies when a new civilization independently rediscovers concepts from ancient dead civilizations.
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.DiscoveryGenealogy

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Analyzes a new discovery to see if it is a rediscovery of lost ancient knowledge."
  def analyze_for_precursors(discovery) do
    if DiscoveryGenealogy.is_rediscovery?(discovery) do
      Logger.info("🏛️ [Epistemic Archaeology] Precursor Detected! #{discovery.originator_civ_id} rediscovered ancient concept: #{discovery.name}")
      
      # EC-3: Increment prestige of the canonical discovery
      DiscoveryGenealogy.increment_prestige(discovery.name)
      
      # In the future, this could trigger ECL-1 knowledge exchange if we want to restore full ancient nodes
      {:rediscovery, discovery.name}
    else
      :novel
    end
  end
end
