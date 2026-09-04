defmodule Tiannara.ASC.Reality.DigitalDeploymentManager do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def deploy(deployment_id, artifact, params \\ %{}) do
    GenServer.call(__MODULE__, {:deploy, deployment_id, artifact, params})
  end

  def get_deployment_status(deployment_id) do
    GenServer.call(__MODULE__, {:status, deployment_id})
  end

  def list_artefacts do
    GenServer.call(__MODULE__, :list_artefacts)
  end

  @impl true
  def init(:ok) do
    {:ok, %{deployments: %{}, artefacts: []}}
  end

  @impl true
  def handle_call({:deploy, deployment_id, artifact, params}, _from, state) do
    target_env = params[:environment] || :staging

    steps = [
      :package_artifact,
      :validate_package,
      :provision_resources,
      :deploy_to_target,
      :health_check,
      :enable_traffic
    ]

    execution = Enum.map(steps, fn step ->
      %{step: step, status: :completed, timestamp: DateTime.utc_now()}
    end)

    deployment = %{
      id: deployment_id,
      artifact: artifact,
      environment: target_env,
      status: :deployed,
      strategy: params[:strategy] || :rolling_update,
      targets: params[:targets] || [:cloud],
      execution_plan: execution,
      deployed_at: DateTime.utc_now(),
      endpoints: generate_endpoints(target_env, artifact),
      config: params
    }

    artefact_record = %{
      id: deployment_id,
      type: :digital,
      artifact: artifact,
      environment: target_env,
      deployed_at: DateTime.utc_now()
    }

    {:reply, {:ok, deployment},
     %{state | deployments: Map.put(state.deployments, deployment_id, deployment),
               artefacts: [artefact_record | state.artefacts]}}
  end

  def handle_call({:status, deployment_id}, _from, state) do
    {:reply, Map.get(state.deployments, deployment_id), state}
  end

  def handle_call(:list_artefacts, _from, state) do
    {:reply, state.artefacts, state}
  end

  defp generate_endpoints(:staging, _artifact) do
    %{api: "https://staging.api.system/internal", dashboard: "https://staging.dashboard.system/internal"}
  end

  defp generate_endpoints(:production, artifact) do
    %{api: "https://api.#{artifact.name}.system/prod", dashboard: "https://dashboard.#{artifact.name}.system/prod"}
  end

  defp generate_endpoints(_env, _artifact) do
    %{api: "https://api.system/deployment", dashboard: "https://dashboard.system/deployment"}
  end
end
