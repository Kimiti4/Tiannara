defmodule Tiannara.Sentinel.Monitors.CausalMonitor do
  @moduledoc """
  Monitors CTL branch divergence and paradox density.
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
