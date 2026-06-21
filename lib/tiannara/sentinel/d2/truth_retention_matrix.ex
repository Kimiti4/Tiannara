defmodule Tiannara.Sentinel.D2.TruthRetentionMatrix do
  @moduledoc """
  D.2: Computes and tracks Truth Half-Life across time and context.
  """
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Record survival of a discovery across an epoch boundary."
  def record_epoch_survival(discovery_id) do
    GenServer.cast(__MODULE__, {:epoch_survival, discovery_id})
  end

  @doc "Record a discovery surviving an ACM attack."
  def record_acm_survival(discovery_id) do
    GenServer.cast(__MODULE__, {:acm_survival, discovery_id})
  end
  
  @doc "Record survival across civilizational transfer."
  def record_cross_civ_transfer(discovery_id, from_civ, to_civ) do
    GenServer.cast(__MODULE__, {:cross_civ, discovery_id, from_civ, to_civ})
  end

  @doc "Retrieves the truth matrix."
  def get_matrix do
    GenServer.call(__MODULE__, :get_matrix)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting D.2 TruthRetentionMatrix")
    {:ok, %{
      discoveries: %{} # id -> %{epochs_survived, acm_survived, civs_held}
    }}
  end

  @impl true
  def handle_cast({:epoch_survival, disc_id}, state) do
    current = Map.get(state.discoveries, disc_id, default_metrics())
    updated = %{current | epochs_survived: current.epochs_survived + 1}
    {:noreply, %{state | discoveries: Map.put(state.discoveries, disc_id, updated)}}
  end

  @impl true
  def handle_cast({:acm_survival, disc_id}, state) do
    current = Map.get(state.discoveries, disc_id, default_metrics())
    updated = %{current | acm_survived: current.acm_survived + 1}
    {:noreply, %{state | discoveries: Map.put(state.discoveries, disc_id, updated)}}
  end
  
  @impl true
  def handle_cast({:cross_civ, disc_id, from_civ, to_civ}, state) do
    current = Map.get(state.discoveries, disc_id, default_metrics())
    # Track unique civs
    civs = Enum.uniq([from_civ, to_civ | current.civs_held])
    updated = %{current | civs_held: civs}
    {:noreply, %{state | discoveries: Map.put(state.discoveries, disc_id, updated)}}
  end

  @impl true
  def handle_call(:get_matrix, _from, state) do
    {:reply, state.discoveries, state}
  end
  
  defp default_metrics do
    %{epochs_survived: 0, acm_survived: 0, civs_held: []}
  end
end
