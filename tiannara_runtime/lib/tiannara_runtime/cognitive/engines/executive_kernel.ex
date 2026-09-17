defmodule TiannaraRuntime.Cognitive.Engines.ExecutiveKernel do
  @moduledoc "Phase 18.2 — Constitutional Cognitive Kernel (Executive Orchestrator)"

  alias TiannaraRuntime.Cognitive.Engines.{
    MissionController, ContextBuilder, AttentionCoordinator,
    TaskDispatcher, EvidenceCollector, ReplayCoordinator, ArchaeologyRecorder
  }
  alias TiannaraRuntime.Cognitive.{
    Mission, CognitiveTask, CognitiveContext, AttentionState,
    ExecutionRequest, ExecutionResult, EvidenceReference,
    ReplayReference, ArchaeologyReference
  }

  def initialize() do
    %{
      missions: %{},
      metrics: %{
        missions_submitted: 0, missions_completed: 0, missions_failed: 0,
        scheduling_latency: [], dispatch_latency: [], context_latency: [],
        evidence_latency: [], replay_latency: [], archaeology_latency: []
      },
      started_at: :erlang.system_time(:millisecond)
    }
  end

  def submit_mission(state, mission_params) do
    start = :erlang.system_time(:millisecond)
    {:ok, mission} = MissionController.create_mission(mission_params)
    {:ok, context} = ContextBuilder.build_context(mission, %{}, [])
    {:ok, attention} = AttentionCoordinator.allocate([], %{}, %{})
    metrics = state.metrics
    metrics = put_in(metrics, [:missions_submitted], metrics.missions_submitted + 1)
    missions = Map.put(state.missions, mission.id, %{
      mission: mission, context: context, attention: attention,
      status: :submitted, tasks: [], evidence: [], replay: [], archaeology: [],
      started_at: start
    })
    {:ok, %{state | missions: missions, metrics: metrics}, mission.id}
  end

  def execute_mission(state, mission_id) do
    with {:ok, mission_state} <- Map.fetch(state.missions, mission_id),
         :ok <- MissionController.transition(mission_state.mission, :submitted, :running),
         {:ok, updated_mission} <- MissionController.set_status(mission_state.mission, :running) do
      state = collect_transition_evidence(state, mission_id, :submitted, :running)
      {:ok, %{state | missions: put_in(state.missions, [mission_id, :mission], updated_mission)}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def pause_mission(state, mission_id) do
    with {:ok, ms} <- Map.fetch(state.missions, mission_id),
         {:ok, updated} <- MissionController.set_status(ms.mission, :paused) do
      state = collect_transition_evidence(state, mission_id, :running, :paused)
      {:ok, put_in(state, [:missions, mission_id, :mission], updated)}
    end
  end

  def resume_mission(state, mission_id) do
    with {:ok, ms} <- Map.fetch(state.missions, mission_id),
         {:ok, updated} <- MissionController.set_status(ms.mission, :running) do
      state = collect_transition_evidence(state, mission_id, :paused, :running)
      {:ok, put_in(state, [:missions, mission_id, :mission], updated)}
    end
  end

  def cancel_mission(state, mission_id) do
    with {:ok, ms} <- Map.fetch(state.missions, mission_id),
         {:ok, updated} <- MissionController.set_status(ms.mission, :failed) do
      state = collect_transition_evidence(state, mission_id, ms.mission.status, :failed)
      metrics = %{state.metrics | missions_failed: state.metrics.missions_failed + 1}
      {:ok, %{state | missions: put_in(state.missions, [mission_id, :mission], updated), metrics: metrics}}
    end
  end

  def complete_mission(state, mission_id) do
    with {:ok, ms} <- Map.fetch(state.missions, mission_id),
         {:ok, updated} <- MissionController.set_status(ms.mission, :completed) do
      {:ok, _ar} = ArchaeologyRecorder.record(%{type: :mission_complete, mission_id: mission_id}, ms)
      {:ok, _rr} = ReplayCoordinator.record(mission_id, updated.fingerprint)
      metrics = %{state.metrics | missions_completed: state.metrics.missions_completed + 1}
      state = collect_transition_evidence(state, mission_id, :running, :completed)
      {:ok, %{state | missions: put_in(state.missions, [mission_id, :mission], updated), metrics: metrics}}
    end
  end

  def status(state, mission_id) do
    with {:ok, ms} <- Map.fetch(state.missions, mission_id) do
      {:ok, %{id: mission_id, status: ms.mission.status, task_count: length(ms.tasks),
              evidence_count: length(ms.evidence), replay_count: length(ms.replay)}}
    end
  end

  def get_metrics(state), do: {:ok, state.metrics}

  def shutdown(state) do
    missions = Enum.map(state.missions, fn {id, ms} ->
      {:ok, m} = MissionController.set_status(ms.mission, :archived)
      {id, %{ms | mission: m}}
    end) |> Map.new()
    {:ok, %{state | missions: missions}}
  end

  def dispatch_task(state, mission_id, task) do
    start = :erlang.system_time(:millisecond)
    with {:ok, ms} <- Map.fetch(state.missions, mission_id),
         {:ok, context} <- ContextBuilder.build_context(ms.mission, ms.context, []),
         {:ok, attention} <- AttentionCoordinator.allocate([task], %{}, ms.context || %{}),
         {:ok, exec_request} <- TaskDispatcher.dispatch(task, context),
         {:ok, exec_result} <- simulate_subsystem_execution(exec_request),
         {:ok, evidence} <- EvidenceCollector.collect_execution(exec_result, context),
         {:ok, replay} <- ReplayCoordinator.record_execution(mission_id, task, exec_result),
         {:ok, archaeology} <- ArchaeologyRecorder.record_execution(task, exec_result, ms) do
      latency = :erlang.system_time(:millisecond) - start
      dispatch_latency = state.metrics.dispatch_latency ++ [latency]
      metrics = %{state.metrics | dispatch_latency: dispatch_latency}
      mission_state = ms
      |> put_in([:tasks], ms.tasks ++ [task])
      |> put_in([:evidence], ms.evidence ++ [evidence])
      |> put_in([:replay], ms.replay ++ [replay])
      |> put_in([:archaeology], ms.archaeology ++ [archaeology])
      {:ok, %{state | missions: put_in(state.missions, [mission_id], mission_state), metrics: metrics},
       exec_result}
    end
  end

  defp collect_transition_evidence(state, mission_id, from, to) do
    {:ok, evidence} = EvidenceCollector.collect_transition(mission_id, from, to)
    put_in(state, [:missions, mission_id, :evidence],
           (state.missions[mission_id].evidence ++ [evidence]))
  end

  defp simulate_subsystem_execution(%ExecutionRequest{} = req) do
    route_key = Map.get(req, :task_reference, "unknown")
    resources = Map.get(req, :requested_resources, %{})
    constraints = Map.get(req, :constraints, [])
    resource_hash = :crypto.hash(:sha256, inspect(resources)) |> Base.encode16(case: :lower)
    constraint_hash = :crypto.hash(:sha256, inspect(constraints)) |> Base.encode16(case: :lower)
    output = %{
      routed_to: route_key,
      resource_fingerprint: resource_hash,
      constraint_fingerprint: constraint_hash,
      sequence: :erlang.unique_integer([:positive])
    }
    ExecutionResult.new(%{execution_request: req, status: :completed, evidence: [output], metrics: %{latency: 0}})
  end
  defp simulate_subsystem_execution(req) when is_map(req) do
    route_key = Map.get(req, :task_reference, "unknown")
    resources = Map.get(req, :requested_resources, %{})
    resource_fp = :crypto.hash(:sha256, inspect(resources)) |> Base.encode16(case: :lower)
    result = %{status: :completed, output: %{routed_to: route_key, resource_fingerprint: resource_fp}}
    {:ok, %{status: :completed, result: result}}
  end
end
