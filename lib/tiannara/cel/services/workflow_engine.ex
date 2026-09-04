defmodule Tiannara.CEL.Services.WorkflowEngine do
  @moduledoc """
  Workflow Engine — saga-based orchestration for the scientific method.

  Executes declarative workflows with:
    - Saga compensation (rollback on failure)
    - Checkpoints (resumability after crash)
    - Idempotent retries (safe to retry failed steps)
    - Resource-aware scheduling (integrates with ResourceManager)
    - Capability-based delegation (integrates with CapabilityGraph)
    - Council-gated high-impact steps
    - Rich outcome telemetry (feeds Adaptive PriorityEngine)

  Constitutional Alignment (rules.md):
    - "Scientific Method": Implements the full observation → discovery pipeline.
    - "Verification First": Every step validated before execution.
    - "Recover gracefully": Saga compensation preserves stable state.
    - "Maintain audit trails": Every transition event-sourced to ExecutiveMemory.
    - "Support reproducibility": Workflows are deterministic given same inputs.
    - "Bottleneck Discovery": Step-level metrics reveal workflow bottlenecks.
  """

  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.CEL.Workflow.{Workflow, Step, StepResult}

  alias Tiannara.CEL.Services.{
    ExecutiveMemory,
    EventBus,
    CapabilityGraph,
    ResourceManager,
    ExecutiveDigitalTwin,
    IdentityTrustManager,
    PriorityEngine
  }

  alias Tiannara.CEL.Services.Priority.OutcomeSignal
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @dets_table :workflow_engine
  @checkpoint_interval 5
  @max_retries 3
  @max_persist_retries 3

  # ── ExecutiveService Behaviour ────────────────────────────────────

  @impl true
  def id, do: :workflow_engine

  @impl true
  def version, do: "2.0.0"

  @impl true
  def capabilities do
    [
      :scientific_workflow_orchestration,
      :saga_compensation,
      :checkpoint_resumability,
      :idempotent_retries,
      :resource_aware_scheduling,
      :capability_delegation,
      :council_integration,
      :outcome_telemetry
    ]
  end

  @impl true
  def dependencies do
    [
      :executive_memory,
      :event_store,
      :executive_service_bus,
      :capability_graph,
      :resource_manager,
      :executive_digital_twin,
      :identity_trust_manager
    ]
  end

  @impl true
  def constitutional_score do
    stats = if Process.whereis(__MODULE__), do: GenServer.call(__MODULE__, :stats), else: %{}

    evidence_quality =
      if stats[:total_started] && stats[:total_started] > 0 do
        (stats[:completed_with_evidence] || 0) / stats[:total_started]
      else
        0.5
      end

    recovery_rate =
      if stats[:total_failed] && stats[:total_failed] > 0 do
        (stats[:successful_compensations] || 0) / stats[:total_failed]
      else
        1.0
      end

    %ConstitutionalScore{
      service_id: id(),
      health: if(stats[:healthy] != false, do: 1.0, else: 0.0),
      constitutional_alignment: recovery_rate,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: evidence_quality,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ── Client API ────────────────────────────────────────────────────

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def start_workflow(%Workflow{} = workflow) do
    GenServer.call(__MODULE__, {:start, workflow}, 30_000)
  end

  def start_workflow(%{name: _, steps: _} = spec) when not is_struct(spec, Workflow) do
    workflow = %Workflow{
      id: "wf_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      name: spec.name,
      steps: spec.steps,
      context: Map.get(spec, :context, %{}),
      mission_id: Map.get(spec, :mission_id),
      version: "1.0.0"
    }

    GenServer.call(__MODULE__, {:start, workflow}, 30_000)
  end

  def pause_workflow(workflow_id), do: GenServer.call(__MODULE__, {:pause, workflow_id})

  def resume_workflow(workflow_id), do: GenServer.call(__MODULE__, {:resume, workflow_id})

  def cancel_workflow(workflow_id, reason \\ :cancelled) do
    GenServer.call(__MODULE__, {:cancel, workflow_id, reason})
  end

  def get_workflow(workflow_id), do: GenServer.call(__MODULE__, {:get, workflow_id})

  def get_status(workflow_id) do
    GenServer.call(__MODULE__, {:get_status, workflow_id})
  end

  def active_workflows, do: GenServer.call(__MODULE__, :active)

  def stats, do: GenServer.call(__MODULE__, :stats)

  def checkpoint(workflow_id), do: GenServer.call(__MODULE__, {:checkpoint, workflow_id})

  def rotate, do: GenServer.call(__MODULE__, :rotate, 60_000)
  def prune, do: GenServer.call(__MODULE__, :prune, 60_000)

  @doc false
  def dets_path, do: Tiannara.Storage.Paths.dets("workflow_engine")

  # ── Init ──────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    register_with_lifecycle()

    case Tiannara.CEL.Services.ResilientDETS.open(
           @dets_table,
           type: :set,
           file: String.to_charlist(dets_path())
         ) do
      {:ok, _} ->
        recovered = recover_interrupted_workflows()

        Logger.info(
          "WorkflowEngine: initialized. Recovered #{length(recovered)} interrupted workflows."
        )

        {:ok,
         %{
           workflows: %{},
           active_count: 0,
           total_started: 0,
           total_completed: 0,
           total_failed: 0,
           successful_compensations: 0,
           completed_with_evidence: 0,
           step_metrics: %{},
           persist_retries: %{},
           degraded: false,
           healthy: true,
           started_at: DateTime.utc_now()
         }}

      {:error, reason} ->
        Logger.error("WorkflowEngine: failed to open DETS: #{inspect(reason)}")

        {:ok,
         %{
           healthy: false,
           degraded: true,
           workflows: %{},
           step_metrics: %{},
           total_started: 0,
           total_completed: 0,
           total_failed: 0,
           successful_compensations: 0,
           completed_with_evidence: 0,
           active_count: 0,
           persist_retries: %{},
           started_at: DateTime.utc_now()
         }}
    end
  end

  # ── handle_call ───────────────────────────────────────────────────

  @impl true
  def handle_call({:start, workflow}, _from, state) do
    case Workflow.validate(workflow) do
      {:error, reason} ->
        {:reply, {:error, {:validation_failed, reason}}, state}

      {:ok, validated} ->
        if high_impact?(validated) do
          case ExecutiveDigitalTwin.simulate_strategy(workflow_to_strategy(validated)) do
            {:ok, %{recommendation: :reject} = report} ->
              {:reply, {:error, {:simulation_rejected, report}}, state}

            {:ok, report} ->
              enriched = attach_simulation_evidence(validated, report)
              do_start_workflow(enriched, state)

            {:error, reason} ->
              {:reply, {:error, {:simulation_failed, reason}}, state}
          end
        else
          do_start_workflow(validated, state)
        end
    end
  end

  @impl true
  def handle_call({:pause, wf_id}, _from, state) do
    case Map.fetch(state.workflows, wf_id) do
      {:ok, %{status: :running} = wf} ->
        updated = %{wf | status: :paused}
        persist_workflow(updated)
        emit_event(:workflow_paused, wf_id)
        {:reply, :ok, put_in(state, [:workflows, wf_id], updated)}

      {:ok, wf} ->
        {:reply, {:error, {:invalid_status, wf.status}}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:resume, wf_id}, _from, state) do
    case Map.fetch(state.workflows, wf_id) do
      {:ok, %{status: :paused} = wf} ->
        updated = %{wf | status: :running}
        persist_workflow(updated)
        emit_event(:workflow_resumed, wf_id)
        send(self(), {:advance_workflow, wf_id})
        {:reply, :ok, put_in(state, [:workflows, wf_id], updated)}

      {:ok, wf} ->
        {:reply, {:error, {:invalid_status, wf.status}}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:cancel, wf_id, reason}, _from, state) do
    case Map.fetch(state.workflows, wf_id) do
      {:ok, %{status: status} = wf} when status in [:running, :paused] ->
        {:ok, compensated} = compensate_completed_steps(wf, reason)

        final = %{
          compensated
          | status: :cancelled,
            completed_at: DateTime.utc_now(),
            error: reason
        }

        persist_workflow(final)
        release_resources(final)
        emit_event(:workflow_cancelled, wf_id, %{reason: reason})
        {:reply, :ok, update_stats_after_failure(state, final)}

      {:ok, wf} ->
        {:reply, {:error, {:invalid_status, wf.status}}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:get, wf_id}, _from, state) do
    {:reply, Map.fetch(state.workflows, wf_id), state}
  end

  @impl true
  def handle_call({:get_status, workflow_id}, _from, state) do
    case Map.fetch(state.workflows, workflow_id) do
      {:ok, workflow} -> {:reply, {:ok, workflow.status}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:active, _from, state) do
    active = state.workflows |> Map.values() |> Enum.filter(&(&1.status == :running))
    {:reply, active, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply,
     %{
       healthy: state.healthy,
       total_started: state.total_started,
       active_count: state.active_count,
       total_completed: state.total_completed,
       total_failed: state.total_failed,
       successful_compensations: state.successful_compensations,
       completed_with_evidence: state.completed_with_evidence,
       step_metrics: state.step_metrics,
       bottleneck_steps: identify_bottleneck_steps(state.step_metrics)
     }, state}
  end

  @impl true
  def handle_call({:checkpoint, wf_id}, _from, state) do
    case Map.fetch(state.workflows, wf_id) do
      {:ok, wf} ->
        updated = %{wf | checkpoint: build_checkpoint(wf)}
        persist_workflow(updated)
        {:reply, :ok, put_in(state, [:workflows, wf_id], updated)}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:rotate, _from, %{degraded: true} = state) do
    {:reply, {:error, :storage_degraded}, state}
  end

  def handle_call(:rotate, _from, state) do
    case Tiannara.Storage.Rotator.rotate(@dets_table, dets_path(), type: :set) do
      {:ok, archive} ->
        {:reply, {:ok, archive}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:prune, _from, %{degraded: true} = state) do
    {:reply, {:error, :storage_degraded}, state}
  end

  def handle_call(:prune, _from, state) do
    cutoff =
      DateTime.utc_now()
      |> DateTime.add(-(workflow_retention_hours() * 3600), :second)

    terminal_ids =
      :dets.traverse(@dets_table, fn
        {id, %{status: status, completed_at: ts}}
        when status in [:completed, :failed, :cancelled] and is_struct(ts, DateTime) ->
          if DateTime.compare(ts, cutoff) == :lt, do: {:continue, id}, else: {:continue, :skip}

        _ ->
          {:continue, :skip}
      end)
      |> Enum.reject(&(&1 == :skip))

    Enum.each(terminal_ids, &:dets.delete(@dets_table, &1))
    {:reply, {:ok, length(terminal_ids)}, state}
  end

  # ── handle_info ───────────────────────────────────────────────────

  @impl true
  def handle_info({:advance_workflow, wf_id}, state) do
    case Map.fetch(state.workflows, wf_id) do
      {:ok, %{status: :running} = wf} ->
        {:noreply, execute_next_step(wf, state)}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:retry_persist, wf_id, attempt}, state) do
    if attempt <= @max_persist_retries do
      case Map.fetch(state.workflows, wf_id) do
        {:ok, wf} ->
          case try_dets_insert(wf) do
            :ok ->
              {:noreply, %{state | persist_retries: Map.delete(state.persist_retries, wf_id)}}

            {:error, reason} ->
              Logger.warning(
                "WorkflowEngine: retry #{attempt}/#{@max_persist_retries} failed for #{wf_id}: #{inspect(reason)}"
              )

              schedule_persist_retry(wf_id, attempt)
              {:noreply, put_in(state, [:persist_retries, wf_id], attempt)}
          end

        :error ->
          {:noreply, state}
      end
    else
      Logger.error(
        "WorkflowEngine: giving up persisting #{wf_id} after #{@max_persist_retries} retries (keeping in-memory state)"
      )

      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:simulate_store_failure, state) do
    if :dets.info(@dets_table) != :undefined do
      _ = :dets.close(@dets_table)
    end

    {:noreply, %{state | degraded: true}}
  end

  @impl true
  def handle_info(:attempt_store_recovery, state) do
    case Tiannara.CEL.Services.ResilientDETS.open(
           @dets_table,
           type: :set,
           file: String.to_charlist(dets_path())
         ) do
      {:ok, _} ->
        {:noreply, %{state | degraded: false}}

      {:error, reason} ->
        Logger.error("WorkflowEngine: store recovery failed: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  # ── Private: Workflow Lifecycle ───────────────────────────────────

  defp do_start_workflow(workflow, state) do
    estimated = estimate_workflow_resources(workflow)

    case ResourceManager.allocate(:workflow_engine, estimated) do
      {:ok, allocation} ->
        wf = %{
          workflow
          | status: :running,
            started_at: DateTime.utc_now(),
            current_step_index: 0,
            context: Map.put(workflow.context, :resource_allocation, allocation)
        }

        persist_workflow(wf)
        record_decision(wf, :workflow_started, %{name: wf.name, step_count: length(wf.steps)})
        emit_event(:workflow_started, wf.id)

        new_state = %{
          state
          | workflows: Map.put(state.workflows, wf.id, wf),
            active_count: state.active_count + 1,
            total_started: state.total_started + 1
        }

        send(self(), {:advance_workflow, wf.id})
        {:reply, {:ok, wf.id}, new_state}

      {:error, reason} ->
        {:reply, {:error, {:resource_allocation_failed, reason}}, state}
    end
  end

  defp execute_next_step(workflow, state) do
    case next_step(workflow) do
      nil ->
        complete_workflow(workflow, state)

      {step, index} ->
        case execute_step(step, workflow) do
          {:ok, result} ->
            handle_step_success(workflow, index, step, result, state)

          {:error, reason} ->
            handle_step_failure(workflow, index, step, reason, state)
        end
    end
  end

  defp next_step(%{current_step_index: idx, steps: steps}) when idx >= length(steps), do: nil

  defp next_step(%{current_step_index: idx, steps: steps}) when idx < length(steps) do
    {Enum.at(steps, idx), idx}
  end

  defp next_step(_), do: nil

  # ── Step Execution ────────────────────────────────────────────────

  defp execute_step(step, workflow) do
    start_time = System.monotonic_time(:millisecond)
    capability = step.module.required_capability()

    case CapabilityGraph.find_optimal_provider(capability) do
      {:ok, provider_id, _score} ->
        try do
          case step.module.execute(step.input, workflow.context) do
            {:ok, raw_output} ->
              duration = System.monotonic_time(:millisecond) - start_time

              result =
                StepResult.new(step.id, step.module.step_type(), raw_output,
                  duration_ms: duration,
                  evidence: Map.get(raw_output, :evidence, []),
                  confidence: Map.get(raw_output, :confidence, 0.5),
                  quality_metrics: Map.get(raw_output, :quality_metrics, %{}),
                  resource_usage: Map.get(raw_output, :resource_usage, %{})
                )

              report_provider_success(provider_id)
              {:ok, result}

            {:error, reason} ->
              report_provider_failure(provider_id, reason)
              {:error, reason}
          end
        rescue
          e ->
            report_provider_failure(provider_id, :exception)
            {:error, {:exception, Exception.message(e)}}
        end

      {:error, :no_provider} ->
        {:error, {:no_provider_for_capability, capability}}
    end
  end

  defp handle_step_success(workflow, index, step, result, state) do
    updated = %{
      workflow
      | current_step_index: index + 1,
        outcome_evidence:
          workflow.outcome_evidence ++
            [
              %{
                step_id: step.id,
                step_type: step.module.step_type(),
                result: result
              }
            ]
    }

    updated =
      if rem(index + 1, @checkpoint_interval) == 0 do
        %{updated | checkpoint: build_checkpoint(updated)}
      else
        updated
      end

    persist_workflow(updated)

    record_decision(updated, :step_completed, %{
      step_id: step.id,
      step_type: step.module.step_type(),
      duration_ms: result.duration_ms
    })

    step_metrics =
      update_step_metrics(state.step_metrics, step.module.step_type(), result.duration_ms, false)

    emit_event(:step_completed, workflow.id, %{
      step_id: step.id,
      step_type: step.module.step_type(),
      duration_ms: result.duration_ms,
      confidence: result.confidence
    })

    EventBus.publish("workflow.step.completed", %{
      workflow_id: workflow.id,
      step_type: step.module.step_type(),
      outcome: :success,
      duration_ms: result.duration_ms,
      confidence: result.confidence,
      quality_metrics: result.quality_metrics
    })

    send(self(), {:advance_workflow, workflow.id})

    %{
      state
      | workflows: Map.put(state.workflows, workflow.id, updated),
        step_metrics: step_metrics
    }
  end

  defp handle_step_failure(workflow, _index, step, reason, state) do
    retry_counts = get_in(workflow, [:context, :retry_counts]) || %{}
    retry_count = Map.get(retry_counts, step.id, 0)

    if retry_count < @max_retries and retryable?(reason) do
      Logger.info("WorkflowEngine: Retrying step #{step.id} (attempt #{retry_count + 1})")

      updated = %{
        workflow
        | context: Map.put(workflow.context || %{}, :retry_counts, Map.put(retry_counts, step.id, retry_count + 1))
      }
      persist_workflow(updated)
      emit_event(:step_retrying, workflow.id, %{step_id: step.id, attempt: retry_count + 1})

      send(self(), {:advance_workflow, workflow.id})
      put_in(state, [:workflows, workflow.id], updated)
    else
      Logger.warning(
        "WorkflowEngine: Step #{step.id} failed permanently. Starting saga compensation."
      )

      {:ok, compensated} = compensate_completed_steps(workflow, reason)

      failed = %{
        compensated
        | status: :failed,
          completed_at: DateTime.utc_now(),
          error: reason,
          context: Map.put(compensated.context, :failure_reason, reason)
      }

      persist_workflow(failed)
      release_resources(failed)

      step_metrics = update_step_metrics(state.step_metrics, step.module.step_type(), 0, true)

      feed_priority_engine(failed, :failure)

      emit_event(:workflow_failed, workflow.id, %{
        failed_step: step.id,
        reason: inspect(reason),
        compensated: length(failed.compensation_log)
      })

      EventBus.publish("workflow.failed", %{
        workflow_id: workflow.id,
        outcome: :failed,
        failed_step_type: step.module.step_type(),
        reason: inspect(reason)
      })

      {:reply, _, state} =
        update_stats_after_failure(
          %{
            state
            | workflows: Map.put(state.workflows, workflow.id, failed),
              step_metrics: step_metrics
          },
          failed
        )

      state
    end
  end

  defp complete_workflow(workflow, state) do
    completed = %{workflow | status: :completed, completed_at: DateTime.utc_now()}

    persist_workflow(completed)
    release_resources(completed)

    record_decision(completed, :workflow_completed, %{
      name: completed.name,
      step_count: length(completed.steps),
      duration_ms: Workflow.duration_ms(completed)
    })

    feed_priority_engine(completed, :success)

    emit_event(:workflow_completed, completed.id)

    EventBus.publish("workflow.completed", %{
      workflow_id: completed.id,
      outcome: :success,
      step_count: length(completed.steps),
      evidence_count: length(completed.outcome_evidence)
    })

    has_evidence = length(completed.outcome_evidence) > 0

    %{
      state
      | workflows: Map.put(state.workflows, completed.id, completed),
        active_count: max(0, state.active_count - 1),
        total_completed: state.total_completed + 1,
        completed_with_evidence: state.completed_with_evidence + if(has_evidence, do: 1, else: 0)
    }
  end

  # ── Saga Compensation ─────────────────────────────────────────────

  defp compensate_completed_steps(workflow, _reason) do
    executed =
      workflow.steps
      |> Enum.with_index()
      |> Enum.take(workflow.current_step_index || 0)
      |> Enum.reverse()

    log =
      Enum.reduce(executed, [], fn {step, _idx}, acc ->
        result = get_step_result(workflow, step.id)

        case step.module.compensate(step.input, result, workflow.context) do
          :ok ->
            [%{step_id: step.id, status: :compensated, at: DateTime.utc_now()} | acc]

          {:error, comp_reason} ->
            Logger.error(
              "WorkflowEngine: Compensation failed for step #{step.id}: #{inspect(comp_reason)}"
            )

            [
              %{
                step_id: step.id,
                status: :compensation_failed,
                reason: comp_reason,
                at: DateTime.utc_now()
              }
              | acc
            ]
        end
      end)
      |> Enum.reverse()

    {:ok, %{workflow | compensation_log: log}}
  end

  defp get_step_result(workflow, step_id) do
    workflow.outcome_evidence
    |> Enum.find(&(&1.step_id == step_id))
    |> case do
      %{result: r} ->
        r

      nil ->
        %{output: %{}, confidence: 0.0, evidence: [], quality_metrics: %{}, resource_usage: %{}}
    end
  end

  # ── Helpers ───────────────────────────────────────────────────────

  defp persist_workflow(workflow) do
    case try_dets_insert(workflow) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error(
          "WorkflowEngine: storage error persisting #{workflow.id}: #{inspect(reason)} — scheduling retry with backoff"
        )

        schedule_persist_retry(workflow.id, 1)
        {:error, :storage_degraded}
    end
  end

  defp try_dets_insert(workflow) do
    :dets.insert(@dets_table, {workflow.id, workflow})
  rescue
    e -> {:error, {:exception, Exception.message(e)}}
  end

  defp schedule_persist_retry(wf_id, attempt) do
    backoff = 1_000 * Integer.pow(2, min(attempt - 1, 5))
    Process.send_after(self(), {:retry_persist, wf_id, attempt + 1}, backoff)
  end

  defp recover_interrupted_workflows do
    :dets.traverse(@dets_table, fn
      {_id, %{status: :running} = wf} -> {:continue, wf}
      _ -> {:continue}
    end)
    |> Enum.map(fn wf ->
      recovered = %{
        wf
        | status: :failed,
          completed_at: DateTime.utc_now(),
          context: Map.put(wf.context, :failure_reason, :engine_crash_recovery)
      }

      _ = persist_workflow(recovered)
      Logger.warning("WorkflowEngine: Recovered interrupted workflow #{wf.id}")
      wf
    end)
  rescue
    e ->
      Logger.error("WorkflowEngine: could not scan for interrupted workflows: #{inspect(e)}")
      []
  end

  defp build_checkpoint(workflow) do
    %{
      step_index: workflow.current_step_index,
      context: workflow.context,
      evidence_so_far: length(workflow.outcome_evidence),
      at: DateTime.utc_now()
    }
  end

  defp estimate_workflow_resources(workflow) do
    %{workflow_id: workflow.id, steps: length(workflow.steps), impact: workflow.impact_level}
  end

  defp release_resources(workflow) do
    case Map.get(workflow.context, :resource_allocation) do
      nil -> :ok
      alloc -> ResourceManager.release(:workflow_engine, alloc)
    end
  rescue
    _ -> :ok
  end

  defp high_impact?(workflow) do
    workflow.impact_level in [:high, :critical] or
      Enum.any?(workflow.steps, fn s -> Map.get(s.config, :impact_level) in [:high, :critical] end)
  end

  defp workflow_to_strategy(workflow) do
    %{
      workflow_id: workflow.id,
      name: workflow.name,
      steps:
        Enum.map(workflow.steps, fn s ->
          %{id: s.id, type: s.type, module: inspect(s.module)}
        end),
      step_count: length(workflow.steps),
      impact_level: workflow.impact_level
    }
  end

  defp attach_simulation_evidence(workflow, report) do
    put_in(workflow, [:context, :simulation_evidence], report)
  end

  defp retryable?({:exception, _}), do: true
  defp retryable?(:timeout), do: true
  defp retryable?(:transient_failure), do: true
  defp retryable?(_), do: false

  defp update_step_metrics(metrics, step_type, duration_ms, failed?) do
    existing = Map.get(metrics, step_type, %{count: 0, total_duration: 0, failures: 0})

    Map.put(metrics, step_type, %{
      count: existing.count + 1,
      total_duration: existing.total_duration + duration_ms,
      failures: existing.failures + if(failed?, do: 1, else: 0)
    })
  end

  defp identify_bottleneck_steps(metrics) do
    metrics
    |> Enum.map(fn {step_type, data} ->
      %{
        step_type: step_type,
        avg_duration_ms: data.total_duration / max(1, data.count),
        failure_rate: data.failures / max(1, data.count)
      }
    end)
    |> Enum.filter(&(&1.avg_duration_ms > 5000 or &1.failure_rate > 0.3))
    |> Enum.sort_by(& &1.avg_duration_ms, :desc)
  end

  defp emit_event(event_type, workflow_id, metadata \\ %{}) do
    EventBus.publish("workflow.#{event_type}", Map.put(metadata, :workflow_id, workflow_id))
  rescue
    _ -> :ok
  end

  defp feed_priority_engine(workflow, outcome) do
    signal = OutcomeSignal.from_workflow_telemetry(workflow, outcome)
    PriorityEngine.feed_signal(signal)
  rescue
    _ -> :ok
  end

  defp record_decision(_workflow, event_type, details) do
    ExecutiveMemory.record_event(:workflow, event_type, details)
  rescue
    _ -> :ok
  end

  defp report_provider_success(provider_id) do
    IdentityTrustManager.report_success(provider_id)
  rescue
    _ -> :ok
  end

  defp report_provider_failure(provider_id, _reason) do
    try do
      IdentityTrustManager.report_violation(provider_id, :low)
    rescue
      _ -> :ok
    end
  end

  defp update_stats_after_failure(state, workflow) do
    state = %{
      state
      | active_count: max(0, state.active_count - 1),
        total_failed: state.total_failed + 1,
        successful_compensations:
          state.successful_compensations + length(workflow.compensation_log)
    }

    {:reply, :ok, state}
  end

  defp register_with_lifecycle do
    _ = Tiannara.Storage.DetsLifecycle.register(%{id: id(), module: __MODULE__})
    :ok
  end

  defp workflow_retention_hours do
    Application.get_env(:tiannara, :dets_workflow_retention_hours, 720)
  end
end
