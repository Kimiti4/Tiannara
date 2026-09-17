defmodule Tiannara.Sentinel.Immune.RegulationPlanner do
  @moduledoc """
  Maps anomaly types to a policy matrix of potential interventions.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_policies(anomaly_type) do
    GenServer.call(__MODULE__, {:get_policies, anomaly_type})
  end

  @impl true
  def init(_opts) do
    # The policy matrix: maps anomaly types to potential actions
    policy_matrix = %{
      type_a_local_process: [:observe, :investigate],
      type_b_ecological: [:rebalance, :isolate],
      type_c_causal: [:isolate, :reconcile],
      type_d_semantic: [:reconcile, :observe],
      type_e_recursion: [:quarantine, :isolate],
      type_f_collapse: [:quarantine, :rebalance]
    }
    {:ok, %{policy_matrix: policy_matrix}}
  end

  @impl true
  def handle_call({:get_policies, anomaly_type}, _from, state) do
    policies = Map.get(state.policy_matrix, anomaly_type, [:observe])
    {:reply, policies, state}
  end
end
