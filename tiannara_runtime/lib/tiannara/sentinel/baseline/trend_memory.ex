defmodule Tiannara.Sentinel.Baseline.TrendMemory do
  @moduledoc """
  Stores continuous streams of historical telemetry to calculate moving averages
  and statistical deviances.
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
