defmodule ObservationBus.CIL.Civilization.ResilienceEngine do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_resilience, do: GenServer.call(__MODULE__, :get)
  def get_threats, do: GenServer.call(__MODULE__, :threats)

  @impl true
  def init(_opts) do
    state = %{
      resilience_score: 0.55,
      recovery_capacity: 0.50,
      adaptive_capacity: 0.45,
      threats: [
        %{id: :t1, type: :climate, name: "Climate Events", likelihood: 0.7, impact: 0.8, preparedness: 0.4, risk_score: 0.56},
        %{id: :t2, type: :resource, name: "Resource Shortages", likelihood: 0.5, impact: 0.7, preparedness: 0.5, risk_score: 0.35},
        %{id: :t3, type: :technological, name: "Infrastructure Failure", likelihood: 0.4, impact: 0.8, preparedness: 0.55, risk_score: 0.32},
        %{id: :t4, type: :biological, name: "Pandemics", likelihood: 0.3, impact: 0.9, preparedness: 0.45, risk_score: 0.27},
        %{id: :t5, type: :infrastructure, name: "Infrastructure Collapse", likelihood: 0.25, impact: 0.85, preparedness: 0.5, risk_score: 0.2125},
      ]
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}
  def handle_call(:threats, _from, state), do: {:reply, state.threats, state}
end
