defmodule ObservationBus.CIL.Meta.ConstitutionalGovernance do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_proposals, do: GenServer.call(__MODULE__, :proposals)
  def get_audit_log, do: GenServer.call(__MODULE__, :audit)

  @impl true
  def init(_opts) do
    proposals = [
      %{id: "gov_1", title: "Add new metric: Research Velocity", status: :proposed, submitted_by: :instrumentation_evolution, submitted_at: DateTime.add(DateTime.utc_now(), -3600, :second), review_status: :pending},
      %{id: "gov_2", title: "Modify CausalEngine retention policy", status: :simulating, submitted_by: :architecture_evolution, submitted_at: DateTime.add(DateTime.utc_now(), -7200, :second), simulation_result: :passed, review_status: :validating},
      %{id: "gov_3", title: "Add CivilizationMonitor room", status: :validating, submitted_by: :human, submitted_at: DateTime.add(DateTime.utc_now(), -86400, :second), simulation_result: :passed, review_status: :certifying},
      %{id: "gov_4", title: "Update TRL calculation formula", status: :deployed, submitted_by: :human, submitted_at: DateTime.add(DateTime.utc_now(), -259200, :second), simulation_result: :passed, certification: :approved, deployed_at: DateTime.add(DateTime.utc_now(), -172800, :second)},
    ]
    audit_log = Enum.map(1..20, fn i ->
      %{id: "audit_#{i}", action: :change, target: Enum.random([:metric, :dashboard, :pipeline, :room]), status: Enum.random([:approved, :rejected, :pending]), timestamp: DateTime.add(DateTime.utc_now(), -i * 3600, :second)}
    end)
    {:ok, %{proposals: proposals, audit_log: audit_log}}
  end

  @impl true
  def handle_call(:proposals, _from, state), do: {:reply, state.proposals, state}
  def handle_call(:audit, _from, state), do: {:reply, state.audit_log, state}
end
