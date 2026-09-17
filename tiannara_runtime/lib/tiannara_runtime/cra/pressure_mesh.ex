defmodule Tiannara.Runtime.CRA.PressureMesh do
  @moduledoc """
  Phase 5F.10 — Pressure Mesh

  Implements discrete ontological fluid equations and manages peer connections
  for pressure diffusion.
  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, %{peers: %{}}}
  end

  @doc """
  Resets the pressure mesh state.
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  Registers a new peer node in the mesh with given pressure and capacity.
  """
  def register_peer(peer_id, pressure, capacity, neighbors) do
    GenServer.call(__MODULE__, {:register_peer, peer_id, pressure, capacity, neighbors})
  end

  @doc """
  Runs one step of diffusion for a given peer.
  """
  def diffuse_once(peer_id, coef, damping, thresh) do
    GenServer.call(__MODULE__, {:diffuse_once, peer_id, coef, damping, thresh})
  end

  # --- GenServer Callbacks ---

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{peers: %{}}}
  end

  @impl true
  def handle_call({:register_peer, peer_id, pressure, capacity, neighbors}, _from, state) do
    peer = %{
      peer_id: peer_id,
      pressure: pressure,
      capacity: capacity,
      neighbors: neighbors
    }

    new_peers = Map.put(state.peers, peer_id, peer)
    {:reply, {:ok, peer}, %{state | peers: new_peers}}
  end

  @impl true
  def handle_call({:diffuse_once, peer_id, coef, damping, _thresh}, _from, state) do
    peer = Map.get(state.peers, peer_id)

    # Calculate discrete Laplacian
    neighbors = Map.get(peer, :neighbors, [])
    p_node = Map.get(peer, :pressure, 0.0)

    laplacian =
      if Enum.empty?(neighbors) do
        0.0
      else
        sum =
          Enum.reduce(neighbors, 0.0, fn n_id, acc ->
            n = Map.get(state.peers, n_id, %{pressure: p_node})
            acc + (n.pressure - p_node)
          end)

        sum / length(neighbors)
      end

    delta = laplacian * coef - damping * p_node
    new_pressure = max(0.0, min(1.0, p_node + delta))

    diffusion = %{
      laplacian: laplacian,
      delta: delta,
      pressure: new_pressure
    }

    # Update node pressure in state
    updated_peer = %{peer | pressure: new_pressure}
    new_peers = Map.put(state.peers, peer_id, updated_peer)

    {:reply, {:ok, diffusion}, %{state | peers: new_peers}}
  end
end
