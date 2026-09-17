defmodule TiannaraRuntime.DFG.TopologicalFold do
  @moduledoc """
  Phase 5F.12 — DFG Topological Fold

  Performs the core latent folding operations and preserves topological invariants.
  """

  use GenServer
  require Logger
  alias TiannaraRuntime.Topology.PersistentHomology
  alias TiannaraRuntime.DFG.MetaRealitySpawner

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{folded_slices: []}}
  end

  @doc "Fold a stable world slice into a latent representation."
  def fold(%{id: slice_id, graph: graph} = slice) when is_map(graph) do
    features = PersistentHomology.extract_persistent_features(graph)
    latent = embed_graph_into_latent_space(graph, features)

    Logger.debug("[DFG] Folded slice #{slice_id} with features #{inspect(features)}")
    MetaRealitySpawner.spawn_latent_world(%{slice_id: slice_id, latent_graph: latent, features: features})
  end

  defp embed_graph_into_latent_space(graph, features) do
    %{
      original_nodes: Map.get(graph, :nodes, []),
      latent_coordinates: compute_latent_coordinates(graph, features),
      anchors: features.anchors,
      compression_ratio: estimate_compression_ratio(graph, features)
    }
  end

  defp compute_latent_coordinates(graph, features) do
    nodes = Map.get(graph, :nodes, [])

    Enum.reduce(nodes, %{}, fn node, acc ->
      Map.put(acc, node, %{
        x: :erlang.phash2({node, features.h0, features.h1}) / 1_000_000.0,
        y: :erlang.phash2({node, features.anchors}) / 1_000_000.0,
        z: :erlang.phash2({node, length(Map.get(graph, :edges, []))}) / 1_000_000.0
      })
    end)
  end

  defp estimate_compression_ratio(graph, features) do
    node_count = length(Map.get(graph, :nodes, []))
    anchor_count = length(features.anchors)

    if node_count == 0 do
      1.0
    else
      1.0 - (anchor_count / max(node_count, 1)) * 0.5
    end
  end
end
