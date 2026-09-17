defmodule TiannaraRuntime.OCM.ConsensusEngine do
  @moduledoc """
  Phase 5F.7 — OCM Consensus Engine

  Supervises semantic reconciliation requests and invokes the drift
  analyzer plus consensus policy.
  """

  use GenServer
  require Logger
  alias TiannaraRuntime.OCM.{Consensus, DriftAnalyzer, Registry}
  alias TiannaraRuntime.NATS.OCMBus

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{decisions: []}}
  end

  @doc "Request a reconciliation pass between two registered node ids." 
  def reconcile(node_a, node_b) do
    GenServer.call(__MODULE__, {:reconcile, node_a, node_b})
  end

  @impl true
  def handle_call({:reconcile, node_a, node_b}, _from, state) do
    ontologies = Registry.list()

    with {:ok, vec_a} <- fetch_vector(ontologies, node_a),
         {:ok, vec_b} <- fetch_vector(ontologies, node_b) do
      {category, drift} = DriftAnalyzer.analyze(vec_a, vec_b)
      result = Consensus.reconcile(node_a, node_b, drift)
      Logger.debug("[OCM] drift=#{drift} category=#{category}")

      # ── Publish full reconciliation event on the cluster bus ─────────────
      OCMBus.publish_reconcile(%{
        node_a: node_a,
        node_b: node_b,
        drift: drift,
        category: category,
        decision: result.type,
        result: result.result
      })

      # ── Publish drift alert when drift crosses warning / critical ─────────
      case category do
        :warning  -> OCMBus.publish_drift_alert(node_a, node_b, drift, :warning)
        :critical -> OCMBus.publish_drift_alert(node_a, node_b, drift, :critical)
        _         -> :noop
      end

      # ── Dedicated quarantine notice when drift ≥ 0.60 ───────────────────
      case result do
        %{type: :quarantine} ->
          OCMBus.publish_quarantine(node_a, node_b, drift)

        _ ->
          :noop
      end

      # ── Publish consensus result for audit-trail consumers ────────────────
      OCMBus.publish_consensus_result(result)

      {:reply, result, %{state | decisions: [{node_a, node_b, category, drift} | state.decisions]}}
    else
      error -> {:reply, error, state}
    end
  end

  defp fetch_vector(ontologies, node_id) do
    case Map.fetch(ontologies, node_id) do
      {:ok, vector} when is_list(vector) -> {:ok, vector}
      _ -> {:error, "missing ontology vector for #{inspect(node_id)}"}
    end
  end
end
