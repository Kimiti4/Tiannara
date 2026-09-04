defmodule Tiannara.ASC.Reality.Director do
  use GenServer

  alias Tiannara.ASC.Reality.Artifact

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def deploy(artifact, target, rollout_params \\ %{}) do
    GenServer.call(__MODULE__, {:deploy, artifact, target, rollout_params}, 60_000)
  end

  @doc """
  Bounded, fault-isolated deploy. One failing or slow artifact cannot hold the
  orchestrator hostage (the :infinity amplification that ended the last soak
  run at T+48h). Failures are recorded, not raised.
  """
  @deploy_timeout_ms 60_000
  def safe_deploy(artifact, target, rollout_params \\ %{}, timeout_ms \\ @deploy_timeout_ms) do
    task = Task.async(fn -> deploy(artifact, target, rollout_params) end)

    try do
      case Task.yield(task, timeout_ms) do
        {:ok, result} -> {:ok, result}
        nil ->
          Task.shutdown(task, :brutal)
          {:error, {:deploy_timeout, timeout_ms}}
        {:exit, reason} -> {:error, {:deploy_failed, reason}}
      end
    catch
      :exit, reason -> {:error, {:deploy_failed, reason}}
      :error, reason -> {:error, {:deploy_raised, reason}}
    end
  end

  @doc "Concurrent spike with per-artifact fault isolation (one crash != abort)."
  def spike(artifacts, opts \\ []) do
    opts
    |> Keyword.put_new(:max_concurrency, 50)
    |> Keyword.put_new(:timeout, @deploy_timeout_ms)
    |> Keyword.put_new(:on_timeout, :kill_task)
    |> then(fn opts ->
      Task.async_stream(artifacts, fn {artifact, target, params} ->
        safe_deploy(artifact, target, params, Keyword.get(opts, :timeout, @deploy_timeout_ms))
      end,
        max_concurrency: Keyword.get(opts, :max_concurrency, 50),
        timeout: Keyword.get(opts, :timeout, @deploy_timeout_ms),
        on_timeout: Keyword.get(opts, :on_timeout, :kill_task)
      )
    end)
    |> Enum.map(fn
      {:ok, r} -> r
      {:exit, reason} -> {:error, {:stream_failed, reason}}
    end)
  end

  def rollback(deployment_id) do
    GenServer.call(__MODULE__, {:rollback, deployment_id})
  end

  def status(deployment_id) do
    GenServer.call(__MODULE__, {:status, deployment_id})
  end

  def list_deployments do
    GenServer.call(__MODULE__, :list_deployments)
  end

  @impl true
  def init(:ok) do
    subscribe_to_inputs()
    {:ok, %{deployments: %{}, queue: [], total_submitted: 0, history: []}}
  end

  @impl true
  def handle_call({:deploy, artifact, target, params}, _from, state) do
    artifact = Artifact.normalize(artifact)
    deployment_id = "dep-#{:erlang.system_time(:millisecond)}"

    new_entry = %{
      id: deployment_id,
      artifact: artifact,
      target: target,
      params: params,
      status: :initiated,
      timestamp: DateTime.utc_now(),
      stages: [],
      error: nil
    }

    result = run_pipeline(deployment_id, artifact, target, params)

    final_entry =
      case result do
        {:ok, pipeline} ->
          %{new_entry | status: :deployed, stages: pipeline.stages}

        {:error, reason, pipeline} ->
          %{new_entry | status: :failed, stages: pipeline.stages, error: reason}

        {:error, reason} ->
          %{new_entry | status: :failed, stages: [], error: reason}
      end

    new_state = %{
      state
      | deployments: Map.put(state.deployments, deployment_id, final_entry),
        history: [final_entry | state.history]
    }

    {:reply, {final_entry.status, deployment_id, result}, new_state}
  end

  def handle_call({:rollback, deployment_id}, _from, state) do
    case Map.get(state.deployments, deployment_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      deployment ->
        rollback_result = Tiannara.ASC.Reality.RollbackEngine.rollback(deployment_id)
        updated = %{deployment | status: :rolled_back, rollback: rollback_result}

        {:reply, {:ok, updated},
         %{state | deployments: Map.put(state.deployments, deployment_id, updated)}}
    end
  end

  def handle_call({:status, deployment_id}, _from, state) do
    {:reply, Map.get(state.deployments, deployment_id), state}
  end

  def handle_call(:list_deployments, _from, state) do
    {:reply, Map.values(state.deployments), state}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: type, payload: payload}}, state)
      when type in ["campaign.phase8b.input", "campaign.phase9.input"] do
    designs = extract_designs(payload)

    new_state =
      Enum.reduce(designs, state, fn design, acc ->
        deployment_id = "deploy_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

        deployment = %{
          id: deployment_id,
          design: design,
          status: :queued,
          risk_assessment: nil,
          safety_verification: nil,
          compliance_check: nil,
          rollout_plan: nil,
          audit_trail: [],
          created_at: DateTime.utc_now(),
          deployed_at: nil,
          rolled_back_at: nil
        }

        %{
          acc
          | deployments: Map.put(acc.deployments, deployment_id, deployment),
            queue: [deployment_id | acc.queue || []],
            total_submitted: (acc.total_submitted || 0) + 1
        }
      end)

    {:noreply, new_state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp run_pipeline(deployment_id, artifact, target, params) do
    with {:ok, stage1} <- assess_risks(deployment_id, artifact, params),
         {:ok, stage2} <- verify_safety(deployment_id, artifact, params),
         {:ok, stage3} <- check_compliance(deployment_id, artifact, target, params),
         {:ok, stage4} <- create_snapshot(deployment_id, artifact),
         {:ok, stage5} <- plan_rollout(deployment_id, artifact, target, params),
         {:ok, stage6} <- setup_monitoring(deployment_id, target),
         {:ok, stage7} <- execute_deployment(deployment_id, artifact, target, params),
         {:ok, stage8} <- allocate_resources(deployment_id, target, params),
         {:ok, stage9} <- plan_infrastructure(deployment_id, target, params),
         {:ok, stage10} <- assess_environmental_impact(deployment_id, artifact, params),
         {:ok, stage11} <- record_audit_trail(deployment_id, artifact, target, params) do
      stages = [
        :risk_assessment,
        :safety_verification,
        :compliance,
        :rollback_snapshot,
        :staged_rollout,
        :monitoring_setup,
        :deployment_execution,
        :resource_allocation,
        :infrastructure_planning,
        :environmental_assessment,
        :audit
      ]

      {:ok,
       %{
         stages: stages,
         details: %{
           risk: stage1,
           safety: stage2,
           compliance: stage3,
           snapshot: stage4,
           rollout: stage5,
           monitoring: stage6,
           execution: stage7,
           resources: stage8,
           infrastructure: stage9,
           environment: stage10,
           audit: stage11
         }
       }}
    end
  end

  defp assess_risks(id, artifact, params) do
    Tiannara.ASC.Reality.RiskAssessmentEngine.assess(artifact, params)
  end

  defp verify_safety(id, artifact, params) do
    Tiannara.ASC.Reality.SafetyVerificationEngine.verify(artifact, params)
  end

  defp check_compliance(id, artifact, target, params) do
    Tiannara.ASC.Reality.ComplianceEngine.check(artifact, target, params)
  end

  defp create_snapshot(id, _artifact) do
    Tiannara.ASC.Reality.RollbackEngine.create_snapshot(id)
  end

  defp plan_rollout(id, artifact, target, params) do
    Tiannara.ASC.Reality.StagedRolloutManager.plan(id, artifact, target, params)
  end

  defp setup_monitoring(id, target) do
    Tiannara.ASC.Reality.IncidentResponseEngine.initialize(id, target)
  end

  defp execute_deployment(id, artifact, :digital, params) do
    Tiannara.ASC.Reality.DigitalDeploymentManager.deploy(id, artifact, params)
  end

  defp execute_deployment(id, artifact, :physical, params) do
    design = physical_design(id, artifact, params)
    Tiannara.ASC.Reality.PhysicalDeploymentManager.plan(design)
  end

  defp execute_deployment(id, artifact, target, params) do
    case target do
      :digital ->
        Tiannara.ASC.Reality.DigitalDeploymentManager.deploy(id, artifact, params)

      :physical ->
        design = physical_design(id, artifact, params)
        Tiannara.ASC.Reality.PhysicalDeploymentManager.plan(design)

      _ ->
        {:error, :unknown_target}
    end
  end

  defp physical_design(id, artifact, params) do
    %{
      id: id,
      type: :physical,
      name: Map.get(artifact, :name, "physical_deployment"),
      artifact: artifact,
      params: params,
      steps: [:calibrate, :initialize, :run_diagnostics, :deploy_firmware]
    }
  end

  defp allocate_resources(id, target, params) do
    Tiannara.ASC.Reality.ResourceOptimizationEngine.optimize(id, target, params)
  end

  defp plan_infrastructure(id, target, params) do
    Tiannara.ASC.Reality.InfrastructurePlanner.plan(id, target, params)
  end

  defp assess_environmental_impact(id, artifact, params) do
    Tiannara.ASC.Reality.EnvironmentalImpactEngine.assess(artifact, params)
  end

  defp record_audit_trail(id, artifact, target, params) do
    Tiannara.ASC.Reality.DeploymentAuditEngine.record(id, artifact, target, params)
  end

  defp extract_designs(payload) do
    case Map.get(payload, :result, %{}) do
      %{designs: designs} when is_list(designs) -> designs
      %{design: design} -> [design]
      _ -> []
    end
  end

  defp subscribe_to_inputs do
    try do
      Tiannara.CEL.Services.EventBus.subscribe("campaign.phase8b.input")
      Tiannara.CEL.Services.EventBus.subscribe("campaign.phase9.input")
    rescue
      _ -> :ok
    end
  end
end
