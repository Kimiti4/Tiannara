defmodule Tiannara.Sentinel.Baseline.AnomalyThresholds do
  @moduledoc """
  Dynamically calculates the standard deviation or adaptive boundaries for what
  constitutes an anomaly, based on baseline learnings.
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
