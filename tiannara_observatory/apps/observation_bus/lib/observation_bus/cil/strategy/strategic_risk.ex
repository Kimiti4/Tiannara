defmodule ObservationBus.CIL.Strategy.StrategicRisk do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_risks, do: GenServer.call(__MODULE__, :list)
  def get_summary, do: GenServer.call(__MODULE__, :summary)

  @impl true
  def init(_opts) do
    risks = [
      %{id: :r1, type: :technology_dead_end, name: "Semiconductor Miniaturization Limit", probability: 0.7, impact: 0.85, risk_score: 0.595, horizon_years: 10, description: "Moore's Law ends before alternative paradigm matures"},
      %{id: :r2, type: :portfolio_collapse, name: "Single-Domain Dependency", probability: 0.5, impact: 0.75, risk_score: 0.375, horizon_years: 5, description: "Over-concentration in computing creates systemic fragility"},
      %{id: :r3, type: :knowledge_monoculture, name: "Epistemic Narrowing", probability: 0.4, impact: 0.6, risk_score: 0.24, horizon_years: 15, description: "Declining diversity of scientific approaches"},
      %{id: :r4, type: :resource_exhaustion, name: "Compute Budget Saturation", probability: 0.6, impact: 0.7, risk_score: 0.42, horizon_years: 3, description: "Energy/compute constraints limit experiment throughput"},
      %{id: :r5, type: :governance_failure, name: "Strategic Drift", probability: 0.3, impact: 0.8, risk_score: 0.24, horizon_years: 8, description: "Loss of constitutional alignment in scientific priorities"}
    ]
    {:ok, %{risks: risks}}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.risks, state}
  def handle_call(:summary, _from, state) do
    summary = %{
      total_risks: length(state.risks),
      mean_risk_score: Enum.reduce(state.risks, 0, &(&1.risk_score + &2)) / max(length(state.risks), 1),
      critical_risks: Enum.count(state.risks, & &1.risk_score >= 0.5),
      by_type: Enum.group_by(state.risks, & &1.type) |> Enum.map(fn {k, v} -> {k, length(v)} end) |> Enum.into(%{})
    }
    {:reply, summary, state}
  end
end
