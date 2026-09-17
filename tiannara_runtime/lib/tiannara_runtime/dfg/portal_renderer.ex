defmodule TiannaraRuntime.DFG.PortalRenderer do
  @moduledoc """
  Phase 5F.12 — DFG Portal Renderer

  Publishes portal metadata for latent meta-reality coupling and observer
  handoff.
  """

  use GenServer
  require Logger
  alias TiannaraRuntime.NATS.Publisher

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{published_portals: 0}}
  end

  @portal_subject "tiannara.dfg.portal.metadata"

  def publish_portal_metadata(meta_state) when is_map(meta_state) do
    payload = %{
      event: :portal_metadata,
      meta_reality_id: meta_state.id,
      slice_id: meta_state.slice_id,
      anchors: Map.get(meta_state, :features, %{})[:anchors],
      compression_ratio: Map.get(meta_state, :latent_graph, %{})[:compression_ratio],
      created_at: meta_state.created_at
    }

    Logger.info("[DFG] Publishing portal metadata for #{meta_state.id}")
    Publisher.publish(@portal_subject, Jason.encode!(payload))
  end
end
