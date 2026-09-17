defmodule Tiannara.Sentinel.Observatories.Specialized.RuntimeObservatory do
  @moduledoc """
  Observes MSCL/OLEF stability and structural pressure.
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
      :runtime,
      anomaly.type,
      :constraint_tightening,
      0.80,
      "Runtime structural analysis favors constraint stabilization."
    )
    {:reply, signal, state}
  end
end
