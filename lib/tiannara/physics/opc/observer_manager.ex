defmodule Tiannara.Physics.OPC.ObserverManager do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{active_observers: %{}, total_managed: 0}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end
