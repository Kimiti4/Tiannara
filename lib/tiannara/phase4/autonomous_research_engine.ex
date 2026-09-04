defmodule Tiannara.Phase4.AutonomousResearchEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{
    UnifiedWorldModel, OntologyManager, KnowledgeCoordinator,
    EpistemicIntegrityService, WorldMutationEngine, WorldQueryEngine
  }
  alias Tiannara.CEL.Workflow.{Workflow, Step}
  alias Tiannara.CEL.Services.{WorkflowEngine, ExecutiveMemory, EventBus}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @research_cycle_interval :timer.minutes(15)
  @max_concurrent_programs 10

  @impl Tiannara.ExecutiveService
  def id, do: :autonomous_research_engine

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :autonomous_hypothesis_generation,
      :experiment_dispatch,
      :epistemic_gap_closure,
      :result_fusion,
      :cross_domain_inquiry
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies do
    [:persistent_memory, :event_transport, :unified_world_model,
     :epistemic_integrity_service, :ontology_manager, :workflow_engine,
     :knowledge_coordinator]
  end

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)
    evidence_quality =
      if stats.total_programs_initiated > 0,
        do: stats.total_validations_completed / stats.total_programs_initiated,
        else: 1.0

    %ConstitutionalScore{
      service_id: id(),
      health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: evidence_quality,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def trigger_research_cycle, do: GenServer.cast(__MODULE__, :trigger_cycle)

  def submit_manual_recommendation(recommendation) do
    GenServer.call(__MODULE__, {:submit_manual, recommendation})
  end

  def active_programs, do: GenServer.call(__MODULE__, :active_programs)

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    EventBus.subscribe("workflow.completed", self())
    EventBus.subscribe("workflow.failed", self())
    schedule_research_cycle()

    {:ok, %{
      active_programs: %{},
      total_programs_initiated: 0,
      total_hypotheses_generated: 0,
      total_validations_completed: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_cast(:trigger_cycle, state) do
    new_state = run_research_cycle(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:submit_manual, recommendation}, _from, state) do
    case initiate_research_program(recommendation, state) do
      {:ok, program_id, new_state} -> {:reply, {:ok, program_id}, new_state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:active_programs, _from, state) do
    {:reply, Map.values(state.active_programs), state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      active_programs: map_size(state.active_programs),
      total_programs_initiated: state.total_programs_initiated,
      total_hypotheses_generated: state.total_hypotheses_generated,
      total_validations_completed: state.total_validations_completed
    }, state}
  end

  @impl true
  def handle_info(:run_research_cycle, state) do
    new_state = run_research_cycle(state)
    schedule_research_cycle()
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "workflow.completed", payload: payload}}, state) do
    new_state = handle_workflow_completion(payload, state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "workflow.failed", payload: payload}}, state) do
    new_state = handle_workflow_failure(payload, state)
    {:noreply, new_state}
  end

  defp run_research_cycle(state) do
    if map_size(state.active_programs) >= @max_concurrent_programs do
      Logger.info("ARE: Max concurrent programs (#{@max_concurrent_programs}) reached. Skipping cycle.")
      state
    else
      case EpistemicIntegrityService.integrity_report() do
        %{experiment_recommendations: recommendations} when is_list(recommendations) and length(recommendations) > 0 ->
          Logger.info("ARE: Found #{length(recommendations)} experiment recommendations.")
          slots_available = @max_concurrent_programs - map_size(state.active_programs)
          to_process = Enum.take(recommendations, slots_available)
          Enum.reduce(to_process, state, fn rec, acc_state ->
            case initiate_research_program(rec, acc_state) do
              {:ok, _program_id, updated_state} -> updated_state
              {:error, _reason} -> acc_state
            end
          end)
        _ ->
          state
      end
    end
  end

  defp initiate_research_program(recommendation, state) do
    program_id = "research_prog_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

    program_entity = %{
      id: program_id,
      domain: :experiments,
      type: :research_program,
      subtype: :autonomous,
      attributes: %{
        recommendation_type: recommendation.type,
        reason: recommendation.reason,
        priority: recommendation.priority,
        status: :hypothesis_generation
      },
      confidence: 0.5,
      uncertainty: 0.5,
      provenance: %{
        origin: :autonomous_research_engine,
        produced_by: :ARE,
        produced_at: DateTime.utc_now(),
        source_recommendation: recommendation
      },
      owner_subsystem: :autonomous_research_engine,
      version: 1,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      status: :active
    }

    case UnifiedWorldModel.create_entity(program_entity) do
      {:ok, ^program_id} ->
        hypotheses = generate_hypotheses(recommendation, program_id)

        workflow_ids =
          hypotheses
          |> Enum.map(fn hyp -> dispatch_validation_workflow(hyp, program_id) end)
          |> Enum.reject(&is_nil/1)

        program_record = %{
          id: program_id,
          recommendation: recommendation,
          hypotheses: hypotheses,
          workflow_ids: workflow_ids,
          initiated_at: DateTime.utc_now()
        }

        new_state = %{state |
          active_programs: Map.put(state.active_programs, program_id, program_record),
          total_programs_initiated: state.total_programs_initiated + 1,
          total_hypotheses_generated: state.total_hypotheses_generated + length(hypotheses)
        }

        ExecutiveMemory.record_decision(
          program_id,
          :research_program_initiated,
          %{recommendation: recommendation.type, hypothesis_count: length(hypotheses)}
        )

        {:ok, program_id, new_state}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp generate_hypotheses(recommendation, program_id) do
    base = %{
      program_id: program_id,
      generated_at: DateTime.utc_now(),
      status: :pending_validation,
      type: :general_inquiry,
      statement: "",
      target_domain: :knowledge
    }

    case recommendation.type do
      :resolve_contradictions ->
        [%{base |
          type: :contradiction_resolution,
          statement: "Targeted experiment to resolve: #{recommendation.reason}"
        }]

      :strengthen_evidence ->
        [%{base |
          type: :evidence_strengthening,
          statement: "Replication experiment to strengthen weak evidence chains"
        }]

      :refresh_stale_theories ->
        [%{base |
          type: :theory_refresh,
          statement: "New observational test for stale theories"
        }]

      _ ->
        [%{base |
          type: :general_inquiry,
          statement: "General inquiry based on epistemic gap"
        }]
    end
  end

  defp dispatch_validation_workflow(hypothesis, program_id) do
    steps = [
      %Step{id: "step_obs", module: Tiannara.CEL.Workflow.Steps.Observation,
            input: %{target: hypothesis.target_domain, observation_type: :automated_inquiry}},
      %Step{id: "step_exp", module: Tiannara.CEL.Workflow.Steps.Experiment,
            input: %{hypothesis: hypothesis, experiment_design: :automated_replication}},
      %Step{id: "step_val", module: Tiannara.CEL.Workflow.Steps.Validation,
            input: %{expected_results: :statistical_significance}}
    ]

    workflow = Workflow.new(
      "ARE Validation: #{hypothesis.type} for #{program_id}",
      steps,
      context: %{source: :autonomous_research_engine, program_id: program_id, hypothesis: hypothesis}
    )

    case WorkflowEngine.start_workflow(workflow) do
      {:ok, workflow_id} ->
        Logger.info("ARE: Dispatched validation workflow #{workflow_id} for hypothesis #{hypothesis.type}")
        workflow_id
      {:error, reason} ->
        Logger.warning("ARE: Failed to dispatch workflow: #{inspect(reason)}")
        nil
    end
  end

  defp handle_workflow_completion(payload, state) do
    workflow_id = payload.workflow_id
    {program_id, program} = Enum.find(state.active_programs, fn {_pid, prog} ->
      workflow_id in prog.workflow_ids
    end) || {nil, nil}

    if program do
      Logger.info("ARE: Workflow #{workflow_id} completed for program #{program_id}. Fusing results.")
      evidence = Map.get(payload, :outcome_evidence, [])
      confidence = Map.get(payload, :final_confidence, 0.5)

      result_entity = %{
        id: "are_result_#{workflow_id}",
        type: :experimental_result,
        attributes: %{
          workflow_id: workflow_id,
          program_id: program_id,
          hypothesis_type: List.first(program.hypotheses).type
        },
        confidence: confidence,
        evidence: evidence,
        provenance: %{
          origin: :autonomous_research_engine,
          produced_by: :ARE,
          produced_at: DateTime.utc_now(),
          workflow_id: workflow_id
        }
      }

      KnowledgeCoordinator.ingest_discovery(result_entity)
      updated_program = Map.put(program, :status, :validation_completed)
      new_active = Map.put(state.active_programs, program_id, updated_program)

      %{state |
        active_programs: new_active,
        total_validations_completed: state.total_validations_completed + 1
      }
    else
      state
    end
  end

  defp handle_workflow_failure(payload, state) do
    workflow_id = payload.workflow_id
    {program_id, program} = Enum.find(state.active_programs, fn {_pid, prog} ->
      workflow_id in prog.workflow_ids
    end) || {nil, nil}

    if program do
      Logger.warning("ARE: Workflow #{workflow_id} failed for program #{program_id}.")

      failure_entity = %{
        id: "are_failure_#{workflow_id}",
        domain: :unknowns,
        type: :failed_experiment,
        attributes: %{
          workflow_id: workflow_id,
          program_id: program_id,
          reason: Map.get(payload, :failure_reason, :unknown)
        },
        confidence: 1.0,
        uncertainty: 0.0,
        provenance: %{
          origin: :autonomous_research_engine,
          produced_by: :ARE,
          produced_at: DateTime.utc_now()
        },
        owner_subsystem: :autonomous_research_engine,
        version: 1,
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        status: :active
      }

      UnifiedWorldModel.create_entity(failure_entity)
      updated_program = Map.put(program, :status, :validation_failed)
      new_active = Map.put(state.active_programs, program_id, updated_program)
      %{state | active_programs: new_active}
    else
      state
    end
  end

  defp schedule_research_cycle do
    Process.send_after(self(), :run_research_cycle, @research_cycle_interval)
  end
end
