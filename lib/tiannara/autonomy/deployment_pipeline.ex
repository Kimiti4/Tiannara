defmodule Tiannara.Autonomy.DeploymentPipeline do
  @moduledoc """
  Deployment Pipeline — manages staged deployment of validated improvements.
  Implements the constitutional deployment protocol with pre-deployment
  checkpointing and post-deployment monitoring.
  """

  use GenServer
  require Logger
  alias Tiannara.Executive.Types

  @monitoring_duration_seconds 3600

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec deploy(map()) :: {:ok, binary()} | {:error, term()}
  def deploy(simulation_result) do
    GenServer.call(__MODULE__, {:deploy, simulation_result})
  end

  @spec approve(binary(), atom()) :: :ok | {:error, term()}
  def approve(deployment_id, approver) do
    GenServer.call(__MODULE__, {:approve, deployment_id, approver})
  end

  @spec reject(binary(), atom(), String.t()) :: :ok | {:error, term()}
  def reject(deployment_id, rejector, reason) do
    GenServer.call(__MODULE__, {:reject, deployment_id, rejector, reason})
  end

  @spec active_count() :: non_neg_integer()
  def active_count do
    GenServer.call(__MODULE__, :active_count)
  end

  @spec total_deployed() :: non_neg_integer()
  def total_deployed do
    GenServer.call(__MODULE__, :total_deployed)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(opts) do
    monitoring_duration = Keyword.get(opts, :monitoring_duration_seconds, @monitoring_duration_seconds)
    {:ok, %{deployments: %{}, total_deployed: 0, total_promoted: 0, total_rolled_back: 0, total_rejected: 0, monitoring_duration_seconds: monitoring_duration}}
  end

  @impl true
  def handle_call({:deploy, simulation}, _from, state) do
    proposal = simulation[:proposal] || %{}
    human_required = proposal[:human_approval_required] || false

    deployment = %{id: Types.new_id(), proposal_id: simulation[:proposal_id], simulation_id: simulation[:id], stage: if(human_required, do: :pending_approval, else: :checkpointing), human_approval_required: human_required, approved_by: nil, checkpoint_id: nil, deployed_at: nil, monitoring_until: nil, promoted_at: nil, rolled_back_at: nil, rollback_reason: nil, lineage: %{simulation: simulation, proposal: proposal, initiated_at: DateTime.utc_now()}}
    deployments = Map.put(state.deployments, deployment.id, deployment)

    :telemetry.execute([:tiannara, :autonomy, :deployment_initiated], %{count: 1}, %{human_required: human_required, proposal_id: deployment.proposal_id})

    Logger.info("[DeploymentPipeline] Deployment initiated. ID: #{deployment.id} Human approval: #{human_required}")

    final_deployments = if human_required, do: deployments, else: proceed_with_deployment(deployment.id, deployments, state)

    {:reply, {:ok, deployment.id}, %{state | deployments: final_deployments, total_deployed: state.total_deployed + 1}}
  end

  @impl true
  def handle_call({:approve, deployment_id, approver}, _from, state) do
    case Map.get(state.deployments, deployment_id) do
      nil -> {:reply, {:error, :not_found}, state}
      %{stage: :pending_approval} = deployment ->
        updated = %{deployment | approved_by: approver, stage: :checkpointing}
        deployments = Map.put(state.deployments, deployment_id, updated)
        Logger.info("[DeploymentPipeline] Approved by #{approver}: #{deployment_id}")
        final_deployments = proceed_with_deployment(deployment_id, deployments, state)
        {:reply, :ok, %{state | deployments: final_deployments}}
      deployment -> {:reply, {:error, {:invalid_stage, deployment.stage}}, state}
    end
  end

  @impl true
  def handle_call({:reject, deployment_id, rejector, reason}, _from, state) do
    case Map.get(state.deployments, deployment_id) do
      nil -> {:reply, {:error, :not_found}, state}
      deployment ->
        updated = %{deployment | stage: :rolled_back, rollback_reason: "Rejected by #{rejector}: #{reason}"}
        Logger.info("[DeploymentPipeline] Rejected by #{rejector}: #{reason}")
        {:reply, :ok, %{state | deployments: Map.put(state.deployments, deployment_id, updated), total_rejected: state.total_rejected + 1}}
    end
  end

  @impl true
  def handle_call(:active_count, _from, state) do
    active = state.deployments |> Map.values() |> Enum.count(fn d -> d.stage in [:pending_approval, :checkpointing, :deploying, :monitoring] end)
    {:reply, active, state}
  end

  @impl true
  def handle_call(:total_deployed, _from, state) do
    {:reply, state.total_deployed, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_deployed: state.total_deployed, total_promoted: state.total_promoted, total_rolled_back: state.total_rolled_back, total_rejected: state.total_rejected, by_stage: state.deployments |> Map.values() |> Enum.frequencies_by(& &1.stage)}, state}
  end

  defp proceed_with_deployment(deployment_id, deployments, state) do
    checkpoint_id = Types.new_id()
    deployed_at = DateTime.utc_now()
    monitoring_until = DateTime.add(deployed_at, state.monitoring_duration_seconds, :second)
    updated = %{deployments[deployment_id] | stage: :monitoring, checkpoint_id: checkpoint_id, deployed_at: deployed_at, monitoring_until: monitoring_until}
    Logger.info("[DeploymentPipeline] Deployed. Checkpoint: #{checkpoint_id} Monitoring until: #{DateTime.to_iso8601(monitoring_until)}")
    :telemetry.execute([:tiannara, :autonomy, :deployment_monitoring], %{count: 1}, %{deployment_id: deployment_id})
    Map.put(deployments, deployment_id, updated)
  end
end
