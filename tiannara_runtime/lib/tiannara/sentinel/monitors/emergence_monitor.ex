defmodule Tiannara.Sentinel.Monitors.EmergenceMonitor do
  @moduledoc """
  Monitors NDE novelty generation and intelligence tiers.
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
