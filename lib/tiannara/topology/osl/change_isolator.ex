defmodule Tiannara.Topology.OSL.ChangeIsolator do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{isolations: 0}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, {:ok, state}, state}
  end
end
