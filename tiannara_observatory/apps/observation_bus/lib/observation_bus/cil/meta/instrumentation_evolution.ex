defmodule ObservationBus.CIL.Meta.InstrumentationEvolution do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def proposals, do: GenServer.call(__MODULE__, :proposals)
  def propose(type, name, description), do: GenServer.cast(__MODULE__, {:propose, type, name, description})

  @impl true
  def init(_opts) do
    proposals = [
      %{id: "prop_1", type: :metric, name: "Research Serendipity Index", description: "Measure unexpected cross-domain connections", status: :proposed},
      %{id: "prop_2", type: :dashboard, name: "Constitutional Drift Dashboard", description: "Track how decisions deviate from constitutional intent", status: :simulating},
      %{id: "prop_3", type: :telemetry, name: "Cognitive Load Telemetry", description: "Measure researcher mental bandwidth utilization", status: :proposed},
      %{id: "prop_4", type: :visualization, name: "Future Morph Map", description: "Animated transition between future branches", status: :validating},
      %{id: "prop_5", type: :metric, name: "Opportunity Velocity", description: "Rate of opportunity identification and validation", status: :deployed},
    ]
    {:ok, %{proposals: proposals}}
  end

  @impl true
  def handle_call(:proposals, _from, state), do: {:reply, state.proposals, state}

  @impl true
  def handle_cast({:propose, type, name, description}, state) do
    n = length(state.proposals) + 1
    prop = %{id: "prop_#{n}", type: type, name: name, description: description, status: :proposed}
    {:noreply, %{state | proposals: [prop | state.proposals]}}
  end
end
