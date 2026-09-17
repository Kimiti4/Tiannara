defmodule Tiannara.Sentinel.Monitors.CollapseMonitor do
  @moduledoc """
  Monitors HSV singularity formation and collapse probability.
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
