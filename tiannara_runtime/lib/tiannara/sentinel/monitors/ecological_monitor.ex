defmodule Tiannara.Sentinel.Monitors.EcologicalMonitor do
  @moduledoc """
  Monitors GRCC entropy, diversity, and monoculture risk.
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
