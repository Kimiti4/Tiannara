defmodule Tiannara.Runtime.CRA.RedundancyMesh do
  @moduledoc """
  Phase 5F.10 — Redundancy Mesh

  Manages active ontological forks, tracks isolated clusters, and stores metadata
  for timeline branch split-ups.
  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, %{forks: %{}, isolated_clusters: %{}}}
  end

  @doc """
  Resets the redundancy mesh state.
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  Returns a snapshot of active forks and isolated clusters.
  """
  def snapshot do
    GenServer.call(__MODULE__, :snapshot)
  end

  @doc """
  Registers a new ontological fork.
  """
  def register_fork(cluster_id, fork_details) do
    GenServer.call(__MODULE__, {:register_fork, cluster_id, fork_details})
  end

  # --- GenServer Callbacks ---

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{forks: %{}, isolated_clusters: %{}}}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:register_fork, cluster_id, fork_details}, _from, state) do
    new_forks = Map.put(state.forks, cluster_id, fork_details)
    new_isolated = Map.put(state.isolated_clusters, cluster_id, true)
    {:reply, :ok, %{state | forks: new_forks, isolated_clusters: new_isolated}}
  end
end
