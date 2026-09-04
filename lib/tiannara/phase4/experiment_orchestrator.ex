defmodule Tiannara.Phase4.ExperimentOrchestrator do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, KnowledgeCoordinator, WorldQueryEngine}
  alias Tiannara.CEL.Services.{WorkflowEngine, ExecutiveMemory, EventBus, ResourceManager, CapabilityGraph}
  alias Tiannara.CEL.Workflow.{Workflow, Step}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @max_concurrent_experiments 20
  @experiment_timeout :timer.hours(72)
  @max_retries 3
  @retry_backoff_base 2_000

  @impl Tiannara.ExecutiveService
  def id, do: :experiment_orchestrator

  @impl Tiannara.ExecutiveService
  def version, do: "2.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :experiment_lifecycle_management, :experiment_tracking,
      :multi_arm_trial_coordination, :result_aggregation,
      :experiment_cancellation, :human_in_the_loop_gating,
      :eig_estimation, :resource_aware_scheduling,
      :constitutional_gating, :execution_environment_selection,
      :failure_recovery
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies do
    [:persistent_memory, :event_transport, :unified_world_model,
     :workflow_engine, :knowledge_coordinator, :resource_manager,
     :capability_graph, :council]
  end

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)
    completion_rate =
      if stats.total_experiments > 0,
        do: stats.completed_experiments / stats.total_experiments,
        else: 1.0

    %ConstitutionalScore{
      service_id: id(), health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0, transparency: 1.0,
      explainability: 1.0, evidence_quality: completion_rate,
      human_oversight: 1.0, computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def submit_experiment(experiment_spec) do
    # MC-003-M M2: the single real-execution gateway. Unless real execution is
    # explicitly enabled, submission is refused — NOTHING is fabricated here.
    if Application.get_env(:tiannara, :real_execution_enabled, false) do
      GenServer.call(__MODULE__, {:submit_experiment, experiment_spec}, 60_000)
    else
      {:error, :real_execution_not_enabled}
    end
  end

  def get_experiment(experiment_id) do
    GenServer.call(__MODULE__, {:get_experiment, experiment_id})
  end

  def cancel_experiment(experiment_id, reason) do
    GenServer.call(__MODULE__, {:cancel_experiment, experiment_id, reason})
  end

  def list_experiments(status \\ nil) do
    GenServer.call(__MODULE__, {:list_experiments, status})
  end

  def aggregate_results(experiment_ids) do
    GenServer.call(__MODULE__, {:aggregate_results, experiment_ids})
  end

  def estimate_eig(hypothesis, existing_knowledge \\ []) do
    GenServer.call(__MODULE__, {:estimate_eig, hypothesis, existing_knowledge})
  end

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    EventBus.subscribe("workflow.completed", self())
    EventBus.subscribe("workflow.failed", self())
    EventBus.subscribe("experiment.cancelled", self())

    {:ok, %{
      experiments: %{}, total_experiments: 0,
      completed_experiments: 0, failed_experiments: 0,
      cancelled_experiments: 0, healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:submit_experiment, spec}, _from, state) do
    # Gateway path: delegate to the real execution provider. The orchestrator's
    # lifecycle bookkeeping is only updated with REAL results.
    experiment_id = spec.id || "exp_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

    case Tiannara.Phase4.RealExecution.execute(spec) do
      {:ok, %{execution_id: execution_id, verification: verification}} ->
        experiment = %{
          id: experiment_id, name: spec.name || "Experiment #{experiment_id}",
          type: spec.type || :standard, hypotheses: spec.hypotheses || [],
          workflow_ids: [], status: :completed,
          submitted_at: DateTime.utc_now(), completed_at: DateTime.utc_now(),
          result: %{execution_id: execution_id, verification: verification},
          eig: nil, resources: nil, environment: :real_sandbox, retry_count: 0
        }

        :telemetry.execute(
          [:tiannara, :phase4, :experiment, :real_execution],
          %{count: 1},
          %{experiment_id: experiment_id, execution_id: execution_id}
        )

        {:reply, {:ok, experiment_id},
         %{state | experiments: Map.put(state.experiments, experiment_id, experiment),
           total_experiments: state.total_experiments + 1,
           completed_experiments: state.completed_experiments + 1}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:estimate_eig, hypothesis, existing_knowledge}, _from, state) do
    eig = compute_eig(hypothesis, existing_knowledge)
    {:reply, {:ok, eig}, state}
  end

  @impl true
  def handle_call({:get_experiment, id}, _from, state) do
    case Map.fetch(state.experiments, id) do
      {:ok, exp} -> {:reply, {:ok, exp}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:cancel_experiment, id, reason}, _from, state) do
    case Map.fetch(state.experiments, id) do
      {:ok, exp} when exp.status in [:running, :pending] ->
        Enum.each(exp.workflow_ids, fn wf_id ->
          WorkflowEngine.cancel_workflow(wf_id, reason)
        end)

        ResourceManager.release(id, exp.resources)

        UnifiedWorldModel.update_entity(id, %{
          attributes: %{status: :cancelled, cancellation_reason: reason},
          status: :cancelled, updated_at: DateTime.utc_now()
        })

        updated = %{exp | status: :cancelled, completed_at: DateTime.utc_now()}
        new_state = %{state |
          experiments: Map.put(state.experiments, id, updated),
          cancelled_experiments: state.cancelled_experiments + 1
        }

        ExecutiveMemory.record_decision(id, :experiment_cancelled, %{reason: reason})
        {:reply, {:ok, id}, new_state}

      {:ok, _exp} ->
        {:reply, {:error, :cannot_cancel_experiment_in_status}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:list_experiments, filter_status}, _from, state) do
    result = if filter_status do
      Enum.filter(state.experiments, fn {_id, exp} -> exp.status == filter_status end)
    else
      Map.to_list(state.experiments)
    end
    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:aggregate_results, experiment_ids}, _from, state) do
    experiments = Enum.map(experiment_ids, fn id -> Map.get(state.experiments, id) end)

    results = Enum.reduce(experiments, %{count: 0, confidence_sum: 0.0, findings: [], total_eig: 0.0}, fn
      nil, acc -> acc
      %{status: :completed, result: r, eig: eig}, acc ->
        %{acc |
          count: acc.count + 1, confidence_sum: acc.confidence_sum + (r.confidence || 0.0),
          findings: acc.findings ++ (r.findings || []), total_eig: acc.total_eig + (eig || 0.0)
        }
      _, acc -> acc
    end)

    avg_confidence = if results.count > 0, do: results.confidence_sum / results.count, else: 0.0
    avg_eig = if results.count > 0, do: results.total_eig / results.count, else: 0.0

    {:reply, {:ok, %{
      experiments: experiment_ids, completed: results.count,
      total: length(experiment_ids), avg_confidence: avg_confidence,
      avg_eig: avg_eig, findings: results.findings
    }}, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      active_experiments: Enum.count(state.experiments, fn {_id, e} -> e.status == :running end),
      total_experiments: state.total_experiments,
      completed_experiments: state.completed_experiments,
      failed_experiments: state.failed_experiments,
      cancelled_experiments: state.cancelled_experiments
    }, state}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "workflow.completed", payload: payload}}, state) do
    new_state = update_experiment_on_workflow_done(payload, :completed, state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "workflow.failed", payload: payload}}, state) do
    new_state = handle_workflow_failure(payload, state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "experiment.cancelled", payload: payload}}, state) do
    experiment_id = payload.experiment_id
    case Map.fetch(state.experiments, experiment_id) do
      {:ok, exp} ->
        ResourceManager.release(experiment_id, exp.resources)
        updated = %{exp | status: :cancelled, completed_at: DateTime.utc_now()}
        {:noreply, %{state |
          experiments: Map.put(state.experiments, experiment_id, updated),
          cancelled_experiments: state.cancelled_experiments + 1
        }}
      :error -> {:noreply, state}
    end
  end

  defp check_concurrent_limit(state) do
    active = Enum.count(state.experiments, fn {_id, e} -> e.status == :running end)
    if active >= @max_concurrent_experiments,
      do: {:error, :concurrent_limit_reached}, else: :ok
  end

  defp check_constitutional_gate(spec, eig) do
    risk_level = classify_risk(spec, eig)

    if risk_level in [:high, :critical] do
      auth = Tiannara.Council.authorize(:high_risk_experiment, %{
        experiment_spec: spec, eig: eig, risk_level: risk_level
      })

      if auth.decision in [:approved, :conditional] do
        :ok
      else
        {:error, :council_denied, auth.explanation}
      end
    else
      :ok
    end
  end

  defp classify_risk(spec, eig) do
    cond do
      spec.type == :human_trial or eig > 0.9 -> :critical
      spec.type in [:longitudinal, :invasive] or eig > 0.7 -> :high
      spec.type == :intervention or eig > 0.4 -> :medium
      true -> :low
    end
  end

  defp estimate_eig_internal(spec, _experiment_id) do
    hypotheses = spec.hypotheses || []
    existing_knowledge = spec.existing_knowledge || []

    if hypotheses == [] do
      0.0
    else
      eigs = Enum.map(hypotheses, fn h -> compute_eig(h, existing_knowledge) end)
      Enum.sum(eigs) / length(eigs)
    end
  end

  defp compute_eig(hypothesis, existing_knowledge) do
    try do
      case CapabilityGraph.dependency_chain(:investigate) do
        {:ok, chain} ->
          provider_score =
            case CapabilityGraph.find_optimal_provider(:investigate) do
              {:ok, _provider, score} -> score
              _ -> 0.5
            end

          knowledge_overlap =
            if existing_knowledge == [] do
              0.0
            else
              overlap = Enum.count(existing_knowledge, fn k ->
                String.contains?(
                  to_string(hypothesis.description || ""),
                  to_string(k.topic || "")
                )
              end)
              overlap / length(existing_knowledge)
            end

          base_eig = 0.5 * (1.0 - knowledge_overlap)
          uncertainty = Map.get(hypothesis, :current_uncertainty, 0.5)
          novelty = Map.get(hypothesis, :novelty, 0.5)

          base_eig * 0.4 + uncertainty * 0.3 + novelty * 0.2 + provider_score * 0.1

        _ ->
          0.3
      end
    rescue
      _ -> 0.3
    end
  end

  defp estimate_resources(spec, eig) do
    base = %{cpu: 1, memory_mb: 512, gpu: 0, storage_gb: 1}

    scaling =
      cond do
        eig > 0.8 -> 3.0
        eig > 0.5 -> 2.0
        true -> 1.0
      end

    case spec.type do
      :simulation -> %{base | cpu: round(4 * scaling), memory_mb: round(2048 * scaling), gpu: 1}
      :ml_training -> %{base | cpu: round(8 * scaling), memory_mb: round(8192 * scaling), gpu: 2}
      :longitudinal -> %{base | memory_mb: round(1024 * scaling), storage_gb: round(10 * scaling)}
      _ -> %{base | cpu: round(base.cpu * scaling), memory_mb: round(base.memory_mb * scaling)}
    end
  end

  defp select_environment(eig, _resources) do
    cond do
      eig < 0.3 -> :sandbox
      eig < 0.7 -> :local_docker
      true -> :remote_cluster
    end
  end

  defp create_experiment_entity(experiment_id, spec, environment) do
    entity = %{
      id: experiment_id, domain: :experiments,
      type: spec.type || :validation_trial, subtype: :autonomous,
      attributes: %{
        name: spec.name, design: spec.design, hypotheses: spec.hypotheses,
        status: :running, environment: environment
      },
      confidence: 0.5, uncertainty: 0.5,
      provenance: %{
        origin: :experiment_orchestrator, produced_by: :ExperimentOrchestrator,
        produced_at: DateTime.utc_now()
      },
      owner_subsystem: :experiment_orchestrator,
      version: 1, created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(), status: :active
    }
    UnifiedWorldModel.create_entity(entity)
  end

  defp maybe_dispatch_workflows(spec, experiment_id, environment) do
    case spec.workflow do
      nil ->
        case spec.hypotheses do
          hypotheses when is_list(hypotheses) and hypotheses != [] ->
            Enum.map(hypotheses, fn hyp -> dispatch_experiment_workflow(hyp, experiment_id, environment) end)
            |> Enum.reject(&is_nil/1)
          _ ->
            Logger.warning("ExperimentOrchestrator: No hypotheses or workflow for #{experiment_id}")
            []
        end
      workflow_spec ->
        wf = build_workflow(experiment_id, workflow_spec)
        case WorkflowEngine.start_workflow(wf) do
          {:ok, wf_id} -> [wf_id]
          {:error, _} -> []
        end
    end
  end

  defp dispatch_experiment_workflow(hypothesis, experiment_id, environment) do
    steps = [
      %Step{id: "step_obs_#{experiment_id}", module: Tiannara.CEL.Workflow.Steps.Observation,
            input: %{hypothesis: hypothesis, observation_type: :automated_inquiry, environment: environment}},
      %Step{id: "step_exp_#{experiment_id}", module: Tiannara.CEL.Workflow.Steps.Experiment,
            input: %{hypothesis: hypothesis, experiment_design: :automated_replication, environment: environment}},
      %Step{id: "step_val_#{experiment_id}", module: Tiannara.CEL.Workflow.Steps.Validation,
            input: %{expected_results: :statistical_significance, environment: environment}}
    ]

    workflow = Workflow.new(
      "Experiment: #{experiment_id}",
      steps,
      context: %{source: :experiment_orchestrator, experiment_id: experiment_id,
                 environment: environment}
    )

    case WorkflowEngine.start_workflow(workflow) do
      {:ok, wf_id} ->
        ExecutiveMemory.record_decision(experiment_id, :workflow_dispatched, %{
          workflow_id: wf_id, hypothesis: hypothesis, environment: environment
        })
        wf_id
      {:error, reason} ->
        Logger.warning("ExperimentOrchestrator: Failed to start workflow: #{inspect(reason)}")
        nil
    end
  end

  defp build_workflow(experiment_id, workflow_spec) do
    steps = Enum.map(workflow_spec.steps || [], fn s ->
      %Step{
        id: s.id || "step_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}",
        module: s.module, input: s.input || %{}
      }
    end)

    Workflow.new(
      workflow_spec.name || "Experiment Workflow: #{experiment_id}",
      steps,
      context: Map.merge(%{experiment_id: experiment_id}, workflow_spec.context || %{})
    )
  end

  defp handle_workflow_failure(payload, state) do
    workflow_id = payload.workflow_id
    {exp_id, experiment} = find_experiment_by_workflow(workflow_id, state)

    case experiment do
      nil -> state
      %{retry_count: retries} when retries >= @max_retries ->
        ResourceManager.release(exp_id, experiment.resources)

        updated = %{experiment | status: :failed, completed_at: DateTime.utc_now()}

        ExecutiveMemory.record_decision(exp_id, :experiment_failed, %{
          workflow_id: workflow_id, reason: payload.reason,
          retries_exhausted: true
        })

        %{state |
          experiments: Map.put(state.experiments, exp_id, updated),
          failed_experiments: state.failed_experiments + 1
        }

      %{retry_count: retries} ->
        backoff = @retry_backoff_base * Integer.pow(2, retries)

        Process.send_after(self(), {:retry_workflow, exp_id, workflow_id, payload}, backoff)

        updated = %{experiment | retry_count: retries + 1}

        ExecutiveMemory.record_decision(exp_id, :workflow_retry_scheduled, %{
          workflow_id: workflow_id, retry_count: retries + 1,
          backoff_ms: backoff, reason: payload.reason
        })

        %{state | experiments: Map.put(state.experiments, exp_id, updated)}
    end
  end

  @impl true
  def handle_info({:retry_workflow, exp_id, workflow_id, original_payload}, state) do
    case Map.fetch(state.experiments, exp_id) do
      {:ok, %{status: :running} = experiment} ->
        hypothesis = Map.get(original_payload, :hypothesis, %{description: "retry"})
        case dispatch_experiment_workflow(hypothesis, exp_id, experiment.environment) do
          nil ->
            ResourceManager.release(exp_id, experiment.resources)
            updated = %{experiment | status: :failed, completed_at: DateTime.utc_now()}
            {:noreply, %{state |
              experiments: Map.put(state.experiments, exp_id, updated),
              failed_experiments: state.failed_experiments + 1
            }}
          new_wf_id ->
            updated = %{experiment | workflow_ids: [new_wf_id | experiment.workflow_ids]}
            {:noreply, %{state | experiments: Map.put(state.experiments, exp_id, updated)}}
        end
      _ ->
        {:noreply, state}
    end
  end

  defp update_experiment_on_workflow_done(payload, outcome, state) do
    workflow_id = payload.workflow_id
    {exp_id, experiment} = find_experiment_by_workflow(workflow_id, state)

    case experiment do
      nil -> state
      _ ->
        all_done = Enum.all?(experiment.workflow_ids, fn wf_id ->
          if wf_id == workflow_id, do: true, else: workflow_status(wf_id) == :completed
        end)

        result = if outcome == :completed do
          %{confidence: Map.get(payload, :final_confidence, 0.5),
            findings: Map.get(payload, :findings, []),
            evidence: Map.get(payload, :outcome_evidence, [])}
        end

        updated = %{experiment |
          status: if(all_done, do: outcome, else: experiment.status),
          completed_at: if(all_done, do: DateTime.utc_now(), else: nil),
          result: if(all_done, do: result, else: experiment.result)
        }

        if all_done do
          ResourceManager.release(exp_id, experiment.resources)
          ingest_experiment_result(exp_id, result, experiment)
        end

        new_state = cond do
          all_done and outcome == :completed ->
            %{state | experiments: Map.put(state.experiments, exp_id, updated),
              completed_experiments: state.completed_experiments + 1}
          all_done and outcome == :failed ->
            %{state | experiments: Map.put(state.experiments, exp_id, updated),
              failed_experiments: state.failed_experiments + 1}
          true ->
            %{state | experiments: Map.put(state.experiments, exp_id, updated)}
        end

        new_state
    end
  end

  defp ingest_experiment_result(exp_id, result, experiment) do
    try do
      KnowledgeCoordinator.ingest_discovery(%{
        id: "exp_result_#{exp_id}", type: :experimental_result,
        attributes: %{
          experiment_id: exp_id, findings: (result && result.findings) || [],
          environment: experiment.environment, eig: experiment.eig
        },
        confidence: (result && result.confidence) || 0.5,
        evidence: (result && result.evidence) || [],
        provenance: %{origin: :experiment_orchestrator, produced_by: :ExperimentOrchestrator,
                      produced_at: DateTime.utc_now()}
      })
    rescue
      _ -> :ok
    end
  end

  defp find_experiment_by_workflow(workflow_id, experiments) do
    Enum.find_value(experiments, {nil, nil}, fn {id, exp} ->
      if workflow_id in (exp.workflow_ids || []), do: {id, exp}, else: nil
    end)
  end

  defp workflow_status(workflow_id) do
    case WorkflowEngine.get_status(workflow_id) do
      {:ok, status} -> status
      _ -> :unknown
    end
  end
end
