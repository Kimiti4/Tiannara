defmodule ObservationBus.CIL.Strategy.BottleneckEngine do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_bottlenecks, do: GenServer.call(__MODULE__, :list)
  def get_ranked, do: GenServer.call(__MODULE__, :ranked)
  def report_bottleneck(type, id, description, impact) do
    GenServer.cast(__MODULE__, {:report, type, id, description, impact})
  end

  @impl true
  def init(_opts) do
    bottlenecks = [
      %{id: :b1, type: :scientific, domain: :fusion, description: "Plasma confinement stability limits progress", impact: 0.85, urgency: 0.9, cost: 0.7, likelihood: 0.8, leverage: 0.9},
      %{id: :b2, type: :engineering, domain: :quantum, description: "Qubit coherence time insufficient for error correction", impact: 0.8, urgency: 0.7, cost: 0.9, likelihood: 0.6, leverage: 0.85},
      %{id: :b3, type: :computational, domain: :ai, description: "Training compute scaling exceeds capacity", impact: 0.75, urgency: 0.8, cost: 0.8, likelihood: 0.7, leverage: 0.8},
      %{id: :b4, type: :ontological, domain: :consciousness, description: "No formal theory of consciousness measurement", impact: 0.6, urgency: 0.4, cost: 0.5, likelihood: 0.9, leverage: 0.7},
      %{id: :b5, type: :resource, domain: :energy, description: "Sustainable energy production limits expansion", impact: 0.9, urgency: 0.85, cost: 0.6, likelihood: 0.8, leverage: 0.95},
      %{id: :b6, type: :organizational, domain: :governance, description: "Decision velocity constrained by consensus overhead", impact: 0.5, urgency: 0.5, cost: 0.3, likelihood: 0.7, leverage: 0.5},
    ]
    state = %{bottlenecks: bottlenecks, indexed_by: :impact}
    {:ok, state}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.bottlenecks, state}
  def handle_call(:ranked, _from, state) do
    ranked = %{
      highest_impact: Enum.sort_by(state.bottlenecks, & &1.impact, :desc) |> Enum.take(5),
      highest_cost: Enum.sort_by(state.bottlenecks, & &1.cost, :desc) |> Enum.take(5),
      most_urgent: Enum.sort_by(state.bottlenecks, & &1.urgency, :desc) |> Enum.take(5),
      most_likely: Enum.sort_by(state.bottlenecks, & &1.likelihood, :desc) |> Enum.take(5),
      highest_leverage: Enum.sort_by(state.bottlenecks, & &1.leverage, :desc) |> Enum.take(5)
    }
    {:reply, ranked, state}
  end

  @impl true
  def handle_cast({:report, type, id, description, impact}, state) do
    bottleneck = %{id: id, type: type, domain: :unknown, description: description, impact: impact, urgency: 0.5, cost: 0.5, likelihood: 0.5, leverage: 0.5}
    {:noreply, %{state | bottlenecks: [bottleneck | state.bottlenecks]}}
  end
end
