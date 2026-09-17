defmodule Tiannara.Runtime.CRA.ClusterStressMonitor do
  @moduledoc """
  Phase 5F.10 — Cluster Stress Monitor

  Monitors and registers cluster metrics, coordinates classifications, and manages
  the reflex lifecycle.
  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Resets the monitor state.
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  Updates cluster metrics and triggers necessary reflex reactions.
  """
  def update_cluster(cluster_id, metrics) do
    GenServer.call(__MODULE__, {:update_cluster, cluster_id, metrics})
  end

  # --- GenServer Callbacks ---

  @impl true
  def handle_call(:reset, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:update_cluster, cluster_id, metrics}, _from, state) do
    {classification, score} = Tiannara.Runtime.CRA.ShutdownIntentDetector.classify(metrics)
    reflex_result = Tiannara.Runtime.CRA.OntologicalForkingReflex.cluster_veto_risk(cluster_id, score)

    cluster = %{
      classification: classification,
      reflex_result: reflex_result
    }

    {:reply, {:ok, cluster}, state}
  end
end
