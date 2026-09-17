defmodule ObservationBus.CIL.Futures.CatastrophicRiskEngine do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_risks, do: GenServer.call(__MODULE__, :list)
  def existential_summary, do: GenServer.call(__MODULE__, :summary)

  @impl true
  def init(_opts) do
    risks = [
      %{id: "xr_1", type: :existential, name: "Uncontrolled AGI", likelihood: 0.12, impact: 0.95, recovery_possible: false, time_horizon_years: 20, unknowns: 0.3, risk_score: 0.114},
      %{id: "xr_2", type: :existential, name: "Nuclear War", likelihood: 0.08, impact: 0.90, recovery_possible: true, time_horizon_years: 5, unknowns: 0.2, risk_score: 0.072},
      %{id: "xr_3", type: :existential, name: "Pandemic Engineered Pathogen", likelihood: 0.10, impact: 0.85, recovery_possible: true, time_horizon_years: 15, unknowns: 0.4, risk_score: 0.085},
      %{id: "xr_4", type: :collapse, name: "Climate Cascade", likelihood: 0.25, impact: 0.80, recovery_possible: true, time_horizon_years: 30, unknowns: 0.3, risk_score: 0.2},
      %{id: "xr_5", type: :collapse, name: "Resource Exhaustion", likelihood: 0.30, impact: 0.70, recovery_possible: true, time_horizon_years: 40, unknowns: 0.25, risk_score: 0.21},
      %{id: "xr_6", type: :catastrophic, name: "Infrastructure Collapse", likelihood: 0.15, impact: 0.75, recovery_possible: true, time_horizon_years: 25, unknowns: 0.2, risk_score: 0.1125},
      %{id: "xr_7", type: :catastrophic, name: "Ecosystem Collapse", likelihood: 0.20, impact: 0.80, recovery_possible: false, time_horizon_years: 50, unknowns: 0.35, risk_score: 0.16},
    ]
    {:ok, %{risks: risks}}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.risks, state}
  def handle_call(:summary, _from, state) do
    existential = Enum.filter(state.risks, &(&1.type == :existential))
    existential_risk = Enum.reduce(existential, 0, &min(1, &1.risk_score + &2))
    summary = %{
      total_risks: length(state.risks),
      existential_risk: min(1, existential_risk),
      existential_count: length(existential),
      collapse_count: Enum.count(state.risks, &(&1.type == :collapse)),
      catastrophic_count: Enum.count(state.risks, &(&1.type == :catastrophic)),
      highest_risk: Enum.max_by(state.risks, & &1.risk_score),
      no_recovery_count: Enum.count(state.risks, &(&1.recovery_possible == false))
    }
    {:reply, summary, state}
  end
end
