defmodule ObservationBus.CIL.Ops.OperationsPlanner do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_plans, do: GenServer.call(__MODULE__, :list)
  def get_plan(id), do: GenServer.call(__MODULE__, {:get, id})
  def propose(action, target, reason), do: GenServer.cast(__MODULE__, {:propose, action, target, reason})

  @impl true
  def init(_opts) do
    plans = [
      %{id: "op_1", action: :launch_experiment, target: :fusion_simulation, reason: "High-confidence fusion regime identified", status: :proposed, risk: 0.3, benefit: 0.85, resource_estimate: %{gpu_hours: 240, storage_tb: 5}, proposed_at: DateTime.utc_now()},
      %{id: "op_2", action: :rebalance_compute, target: :gpu_cluster_a, reason: "Underutilized during off-peak hours", status: :approved, risk: 0.1, benefit: 0.5, resource_estimate: %{gpu_hours: 0, storage_tb: 0}, proposed_at: DateTime.utc_now()},
      %{id: "op_3", action: :pause_subsystem, target: :legacy_monitor, reason: "Migration to new architecture pending", status: :executing, risk: 0.2, benefit: 0.4, resource_estimate: %{gpu_hours: 0, storage_tb: 0}, proposed_at: DateTime.utc_now()},
      %{id: "op_4", action: :expand_campaign, target: :materials_discovery, reason: "New ML model achieves 95% accuracy", status: :proposed, risk: 0.4, benefit: 0.9, resource_estimate: %{gpu_hours: 500, storage_tb: 20}, proposed_at: DateTime.utc_now()},
      %{id: "op_5", action: :allocate_resources, target: :quantum_simulation, reason: "New qubit architecture requires validation", status: :simulating, risk: 0.5, benefit: 0.75, resource_estimate: %{gpu_hours: 1000, storage_tb: 50}, proposed_at: DateTime.utc_now()},
    ]
    {:ok, %{plans: plans}}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.plans, state}
  def handle_call({:get, id}, _from, state), do: {:reply, Enum.find(state.plans, &(&1.id == id)), state}

  @impl true
  def handle_cast({:propose, action, target, reason}, state) do
    n = length(state.plans) + 1
    plan = %{id: "op_#{n}", action: action, target: target, reason: reason, status: :proposed, risk: :rand.uniform() * 0.5, benefit: :rand.uniform() * 0.5 + 0.3, resource_estimate: %{}, proposed_at: DateTime.utc_now()}
    {:noreply, %{state | plans: [plan | state.plans]}}
  end
end
