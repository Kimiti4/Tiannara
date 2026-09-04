defmodule Tiannara.ASC.Reality.DeploymentAuditEngine do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def record(deployment_id, artifact, target, params \\ %{}) do
    GenServer.call(__MODULE__, {:record, deployment_id, artifact, target, params})
  end

  def get_audit_trail(deployment_id) do
    GenServer.call(__MODULE__, {:audit_trail, deployment_id})
  end

  def get_compliance_records do
    GenServer.call(__MODULE__, :compliance_records)
  end

  def search_audit(filters) do
    GenServer.call(__MODULE__, {:search, filters})
  end

  @impl true
  def init(:ok) do
    {:ok, %{audit_logs: %{}, compliance_records: []}}
  end

  @impl true
  def handle_call({:record, deployment_id, artifact, target, params}, _from, state) do
    event_id = "audit-#{:erlang.system_time(:millisecond)}"

    entry = %{
      event_id: event_id,
      deployment_id: deployment_id,
      artifact: artifact,
      target: target,
      params: params,
      timestamp: DateTime.utc_now(),
      event_type: :deployment_recorded,
      metadata: %{
        version: params[:version] || "1.0.0",
        triggered_by: params[:triggered_by] || :system,
        environment: params[:environment] || :production
      }
    }

    compliance_record = %{
      event_id: event_id,
      deployment_id: deployment_id,
      artifact_name: artifact.name,
      target: target,
      timestamp: DateTime.utc_now(),
      status: :recorded
    }

    existing = Map.get(state.audit_logs, deployment_id, [])
    {:reply, {:ok, entry},
     %{state | audit_logs: Map.put(state.audit_logs, deployment_id, [entry | existing]),
               compliance_records: [compliance_record | state.compliance_records]}}
  end

  def handle_call({:audit_trail, deployment_id}, _from, state) do
    {:reply, Map.get(state.audit_logs, deployment_id, []), state}
  end

  def handle_call(:compliance_records, _from, state) do
    {:reply, state.compliance_records, state}
  end

  def handle_call({:search, filters}, _from, state) do
    results = state.compliance_records
    results = if filters[:target], do: Enum.filter(results, fn r -> r.target == filters[:target] end), else: results
    results = if filters[:status], do: Enum.filter(results, fn r -> r.status == filters[:status] end), else: results
    results = if filters[:limit], do: Enum.take(results, filters[:limit]), else: results
    {:reply, results, state}
  end
end
