defmodule Tiannara.Sentinel.Monitors.RuntimeMonitor do
  @moduledoc """
  Monitors BEAM/node health, thermal, and latency.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end
end
