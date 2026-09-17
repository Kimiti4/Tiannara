defmodule TiannaraRuntime.DFG.MetaRealitySpawner do
  @moduledoc """
  Phase 5F.12 — DFG Meta Reality Spawner

  Spawns and tracks latent meta-reality instances based on folded world slices.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{meta_realities: %{}}}
  end

  @doc "Spawn a latent meta-reality instance from folded slice data."
  def spawn_latent_world(payload) when is_map(payload) do
    GenServer.call(__MODULE__, {:spawn_latent_world, payload})
  end

  @impl true
  def handle_call({:spawn_latent_world, payload}, _from, state) do
    meta_id = "meta_#{System.unique_integer([:positive])}"
    meta_state = %{
      id: meta_id,
      slice_id: Map.get(payload, :slice_id),
      latent_graph: Map.get(payload, :latent_graph),
      features: Map.get(payload, :features),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Logger.info("[DFG] Spawned meta reality #{meta_id} for slice #{meta_state.slice_id}")

    new_state = put_in(state.meta_realities[meta_id], meta_state)
    TiannaraRuntime.DFG.PortalRenderer.publish_portal_metadata(meta_state)

    {:reply, {:ok, meta_state}, new_state}
  end
end
