defmodule ObservationBus.CIL.Ops.AuthorizationEngine do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_pending, do: GenServer.call(__MODULE__, :pending)
  def authorize(plan_id), do: GenServer.cast(__MODULE__, {:authorize, plan_id})
  def reject(plan_id, reason), do: GenServer.cast(__MODULE__, {:reject, plan_id, reason})

  @impl true
  def init(_opts) do
    authorizations = [
      %{plan_id: "op_1", status: :approved, simulation_passed: true, risk_acceptable: true, constitution_check: :passed, approved_at: DateTime.utc_now()},
      %{plan_id: "op_2", status: :approved, simulation_passed: true, risk_acceptable: true, constitution_check: :passed, approved_at: DateTime.utc_now()},
      %{plan_id: "op_3", status: :pending, simulation_passed: nil, risk_acceptable: nil, constitution_check: :pending, approved_at: nil},
      %{plan_id: "op_4", status: :pending, simulation_passed: nil, risk_acceptable: nil, constitution_check: :pending, approved_at: nil},
      %{plan_id: "op_5", status: :simulating, simulation_passed: true, risk_acceptable: :under_review, constitution_check: :pending, approved_at: nil},
    ]
    {:ok, %{authorizations: authorizations, rejected: []}}
  end

  @impl true
  def handle_call(:pending, _from, state) do
    pending = Enum.filter(state.authorizations, &(&1.status == :pending))
    {:reply, pending, state}
  end

  @impl true
  def handle_cast({:authorize, plan_id}, state) do
    auths = Enum.map(state.authorizations, fn a ->
      if a.plan_id == plan_id, do: %{a | status: :approved, simulation_passed: true, risk_acceptable: true, constitution_check: :passed, approved_at: DateTime.utc_now()}, else: a
    end)
    {:noreply, %{state | authorizations: auths}}
  end

  def handle_cast({:reject, plan_id, reason}, state) do
    auths = Enum.reject(state.authorizations, &(&1.plan_id == plan_id))
    rejected = [%{plan_id: plan_id, reason: reason, rejected_at: DateTime.utc_now()} | state.rejected]
    {:noreply, %{state | authorizations: auths, rejected: rejected}}
  end
end
