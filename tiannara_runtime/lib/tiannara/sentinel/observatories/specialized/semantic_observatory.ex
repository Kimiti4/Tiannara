defmodule Tiannara.Sentinel.Observatories.Specialized.SemanticObservatory do
  @moduledoc """
  Observes causal ontology and semantic fragmentation.
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
      :semantic,
      anomaly.type,
      :ontology_reconciliation,
      0.70,
      "Semantic analysis favors ontology reconciliation."
    )
    {:reply, signal, state}
  end
end
