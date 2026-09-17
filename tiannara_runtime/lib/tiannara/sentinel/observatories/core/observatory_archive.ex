defmodule Tiannara.Sentinel.Observatories.Core.ObservatoryArchive do
  @moduledoc """
  Maintains longitudinal snapshots of the Observatory Mesh metrics.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_snapshot(report) do
    GenServer.cast(__MODULE__, {:record, report})
  end

  def get_history do
    GenServer.call(__MODULE__, :get_history)
  end

  def get_stable_days do
    # Placeholder logic: scan snapshots and determine consecutive days where consensus_advantage_live > 0
    # For D.1A, we return a mock value based on the number of snapshots
    snapshots = get_history()
    Enum.count(snapshots, fn s -> s.consensus_advantage_live > 0.0 end)
  end

  @impl true
  def init(_opts) do
    {:ok, %{snapshots: []}}
  end

  @impl true
  def handle_cast({:record, report}, state) do
    snapshots = [report | state.snapshots] |> Enum.take(30)
    {:noreply, %{state | snapshots: snapshots}}
  end

  @impl true
  def handle_call(:get_history, _from, state) do
    {:reply, state.snapshots, state}
  end
end
