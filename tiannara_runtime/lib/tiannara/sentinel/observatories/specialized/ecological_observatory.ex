defmodule Tiannara.Sentinel.Observatories.Specialized.EcologicalObservatory do
  @moduledoc """
  Observes entropy growth and resource pressures.
  """
  use GenServer
  alias Tiannara.Sentinel.Observatories.Types.ObservatorySignal

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def generate_signal(anomaly) do
    GenServer.call(__MODULE__, {:generate_signal, anomaly})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:generate_signal, anomaly}, _from, state) do
    signal = ObservatorySignal.new(
      :ecological,
      anomaly.type,
      :entropy_rebalancing,
      0.75,
      "Ecological analysis favors entropy rebalancing."
    )
    {:reply, signal, state}
  end
end
