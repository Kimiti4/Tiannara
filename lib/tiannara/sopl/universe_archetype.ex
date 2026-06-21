defmodule Tiannara.SOPL.UniverseArchetype do
  @moduledoc """
  SOPL-3: Universe Archetype
  
  Emergent classes of realities discovered through Law Recombination.
  These are not assigned human labels (e.g. "Truth-Dominant"), but are 
  clustered dynamically by Sentinel based on their structural profiles.
  """
  defstruct [
    :id,
    :dominant_fragments,
    :fitness_profile,
    :pathology_profile,
    :attractor_affinity
  ]
end

defmodule Tiannara.SOPL.ArchetypeDiscovery do
  @moduledoc """
  SOPL-3: Archetype Discovery Engine
  
  Clusters deployed SOPL-3 universes into emergent UniverseArchetypes.
  Ensures that human taxonomy does not leak into law evolution.
  """
  alias Tiannara.SOPL.UniverseArchetype
  require Logger

  @doc """
  Discovers new Archetypes from a population of deployed, recombined laws.
  """
  def discover_archetypes(deployed_proto_laws, _evaluations \\ []) do
    # 1. Group laws by their dominant fragment ancestry
    clusters = Enum.group_by(deployed_proto_laws, fn proto -> 
      # The centroid signature is defined by the fragments that built it
      frag_sig = Enum.sort(proto.fragment_ancestry || []) |> Enum.join("+")
      "#{frag_sig}"
    end)
    
    archetypes = Enum.map(clusters, fn {sig, protos} ->
      # 2. Aggregate profiles across the cluster
      avg_synergy = Enum.sum(Enum.map(protos, & &1.synergy_score)) / length(protos)
      
      %UniverseArchetype{
        id: "arch_#{:erlang.phash2(sig)}",
        dominant_fragments: sig,
        fitness_profile: %{avg_synergy: avg_synergy},
        pathology_profile: %{}, # Determined after running in a live shard
        attractor_affinity: "vector_#{:erlang.phash2(sig)}"
      }
    end)
    
    Logger.info("🌌 [SOPL-3] Sentinel discovered #{length(archetypes)} emergent Universe Archetypes.")
    archetypes
  end
end
