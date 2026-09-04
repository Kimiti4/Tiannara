defmodule Tiannara.CEL.Services.MissionDirector do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.CEL.Mission.MissionModel.{Mission, Program, Objective, Asset, ImpactAssessment}
  alias Tiannara.CEL.Services.{ExecutiveMemory, EventBus, WorkflowEngine, ExecutiveMetrics}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @mission_table :mission_director_state
  @mission_file ~c"./mission_director_state.dets"

  @impl true
  def id, do: :mission_director

  @impl true
  def version, do: "2.0.0"

  @impl true
  def capabilities do
    [:scientific_lifecycle_orchestration, :validation_gating, :impact_assessment,
     :workflow_delegation, :knowledge_asset_tracking]
  end

  @impl true
  def dependencies, do: [:executive_memory, :executive_service_bus, :workflow_engine]

  @impl true
  def health do
    if Process.whereis(__MODULE__), do: :healthy, else: :unhealthy
  end

  @impl true
  def constitutional_score do
    stats =
      if Process.whereis(__MODULE__),
        do: GenServer.call(__MODULE__, :stats),
        else: %{missions_by_status: %{}, total_missions: 1}

    stuck = Map.get(stats.missions_by_status, :validating, 0)
    failed = Map.get(stats.missions_by_status, :failed, 0)
    total = stats.total_missions || 1
    health = 1.0 - ((stuck * 0.1 + failed * 0.2) / total)

    %ConstitutionalScore{
      service_id: id(),
      health: max(0.0, health),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def create_mission(name, description, opts \\ []) do
    GenServer.call(__MODULE__, {:create_mission, name, description, opts})
  end

  def add_program(mission_id, program_name, description) do
    GenServer.call(__MODULE__, {:add_program, mission_id, program_name, description})
  end

  def add_objective(program_id, description) do
    GenServer.call(__MODULE__, {:add_objective, program_id, description})
  end

  def launch_workflow(objective_id, workflow_spec) do
    GenServer.call(__MODULE__, {:launch_workflow, objective_id, workflow_spec})
  end

  def submit_validation(objective_id, evidence) do
    GenServer.call(__MODULE__, {:submit_validation, objective_id, evidence})
  end

  def complete_mission(mission_id, assessment_data, assessor) do
    GenServer.call(__MODULE__, {:complete_mission, mission_id, assessment_data, assessor})
  end

  def get_mission(mission_id), do: GenServer.call(__MODULE__, {:get_mission, mission_id})

  def active_missions do
    GenServer.call(__MODULE__, :active_missions)
  end

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    case :dets.open_file(@mission_table, type: :set, file: @mission_file) do
      {:ok, _} ->
        Logger.info("MissionDirector: initialized")
        {:ok, %{total_missions: 0, missions_by_status: %{}}}

      {:error, reason} ->
        Logger.error("MissionDirector: failed to open storage: #{inspect(reason)}")
        {:ok, %{total_missions: 0, missions_by_status: %{}}}
    end
  end

  @impl true
  def handle_call({:create_mission, name, description, opts}, _from, state) do
    mission = %Mission{
      id: "mission_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      name: name,
      description: description,
      strategic_objective_id: Keyword.get(opts, :strategic_objective_id),
      status: :planning,
      programs: [],
      created_at: DateTime.utc_now(),
      metadata: Keyword.get(opts, :metadata, %{})
    }

    persist_mission(mission)
    record_transition(mission.id, :created, %{name: name})
    emit_event(:mission_created, mission.id)

    new_state = update_status_counts(state, mission.id, nil, :planning)
    {:reply, {:ok, mission.id}, new_state}
  end

  @impl true
  def handle_call({:add_program, mission_id, name, description}, _from, state) do
    case get_mission_state(mission_id) do
      {:ok, mission} ->
        program = %Program{
          id: "prog_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
          mission_id: mission_id,
          name: name,
          description: description,
          status: :planning,
          objectives: [],
          created_at: DateTime.utc_now()
        }

        updated = %{mission | programs: [program | mission.programs]}
        persist_mission(updated)
        record_transition(mission_id, :program_added, %{program_id: program.id})
        {:reply, {:ok, program.id}, state}

      :error ->
        {:reply, {:error, :mission_not_found}, state}
    end
  end

  @impl true
  def handle_call({:add_objective, program_id, description}, _from, state) do
    mission = find_mission_by_program(program_id)

    case mission do
      nil ->
        {:reply, {:error, :program_not_found}, state}

      m ->
        objective = %Objective{
          id: "obj_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
          program_id: program_id,
          description: description,
          status: :pending,
          active_workflows: [],
          generated_assets: [],
          validation_evidence: []
        }

        updated_programs = Enum.map(m.programs, fn
          %{id: ^program_id} = p -> %{p | objectives: [objective | p.objectives]}
          p -> p
        end)

        updated_mission = %{m | programs: updated_programs, status: :active}
        persist_mission(updated_mission)
        record_transition(m.id, :objective_added, %{objective_id: objective.id})
        {:reply, {:ok, objective.id}, state}
    end
  end

  @impl true
  def handle_call({:launch_workflow, objective_id, workflow_spec}, _from, state) do
    mission = find_mission_by_objective(objective_id)

    case mission do
      nil ->
        {:reply, {:error, :objective_not_found}, state}

      m ->
        case WorkflowEngine.start_workflow(workflow_spec) do
          {:ok, workflow_id} ->
            updated_programs = update_objective_in_programs(m.programs, objective_id, fn obj ->
              %{obj | status: :in_progress, active_workflows: [workflow_id | obj.active_workflows]}
            end)

            updated_mission = %{m | programs: updated_programs}
            persist_mission(updated_mission)
            record_transition(m.id, :workflow_launched, %{objective_id: objective_id, workflow_id: workflow_id})
            {:reply, {:ok, workflow_id}, state}

          {:error, reason} ->
            {:reply, {:error, {:workflow_launch_failed, reason}}, state}
        end
    end
  end

  @impl true
  def handle_call({:submit_validation, objective_id, evidence}, _from, state) do
    mission = find_mission_by_objective(objective_id)

    case mission do
      nil ->
        {:reply, {:error, :objective_not_found}, state}

      m ->
        if length(evidence) < 1 do
          {:reply, {:error, :insufficient_validation_evidence}, state}
        else
          updated_programs = update_objective_in_programs(m.programs, objective_id, fn obj ->
            %{obj |
              status: :validated,
              validation_evidence: evidence ++ obj.validation_evidence
            }
          end)

          updated_mission = %{m | programs: updated_programs}
          persist_mission(updated_mission)
          record_transition(m.id, :objective_validated, %{objective_id: objective_id})
          {:reply, :ok, state}
        end
    end
  end

  @impl true
  def handle_call({:complete_mission, mission_id, assessment_data, assessor}, _from, state) do
    case get_mission_state(mission_id) do
      {:ok, mission} ->
        unvalidated =
          mission.programs
          |> Enum.flat_map(& &1.objectives)
          |> Enum.count(&(&1.status == :in_progress or &1.status == :pending))

        if unvalidated > 0 do
          {:reply, {:error, :unvalidated_objectives_remaining}, state}
        else
          assessment = %ImpactAssessment{
            mission_id: mission_id,
            research_acceleration_delta: Map.get(assessment_data, :research_acceleration_delta, 0.0),
            engineering_productivity_delta: Map.get(assessment_data, :engineering_productivity_delta, 0.0),
            knowledge_retained: Map.get(assessment_data, :knowledge_retained, 0.0),
            novel_discoveries_count: Map.get(assessment_data, :novel_discoveries_count, 0),
            human_collaboration_value: Map.get(assessment_data, :human_collaboration_value, 0.0),
            assessed_at: DateTime.utc_now(),
            assessor: assessor
          }

          completed = %{mission |
            status: :completed,
            completed_at: DateTime.utc_now(),
            impact_assessment: assessment
          }

          persist_mission(completed)
          record_transition(mission_id, :completed, %{assessment: assessment})
          emit_event(:mission_completed, mission_id, %{assessment: assessment})

          ExecutiveMetrics.ingest_mission_outcome(mission_id, assessment)

          new_state = update_status_counts(state, mission_id, mission.status, :completed)
          {:reply, {:ok, completed}, new_state}
        end

      :error ->
        {:reply, {:error, :mission_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_mission, mission_id}, _from, state) do
    {:reply, get_mission_state(mission_id), state}
  end

  @impl true
  def handle_call(:active_missions, _from, state) do
    active =
      :dets.traverse(@mission_table, fn
        {_id, %{status: status} = m} when status in [:planning, :active, :validating] ->
          {:continue, m}
        _ -> {:continue}
      end)
    {:reply, active, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  defp persist_mission(mission) do
    :dets.insert(@mission_table, {mission.id, mission})
  end

  defp get_mission_state(mission_id) do
    case :dets.lookup(@mission_table, mission_id) do
      [{^mission_id, mission}] -> {:ok, mission}
      [] -> :error
    end
  end

  defp find_mission_by_program(program_id) do
    :dets.traverse(@mission_table, fn
      {_id, %{programs: programs} = m} ->
        if Enum.any?(programs, &(&1.id == program_id)), do: {:continue, m}, else: {:continue}
      _ -> {:continue}
    end)
    |> List.first()
  end

  defp find_mission_by_objective(objective_id) do
    :dets.traverse(@mission_table, fn
      {_id, %{programs: programs} = m} ->
        has = Enum.any?(programs, fn p -> Enum.any?(p.objectives, &(&1.id == objective_id)) end)
        if has, do: {:continue, m}, else: {:continue}
      _ -> {:continue}
    end)
    |> List.first()
  end

  defp update_objective_in_programs(programs, objective_id, update_fn) do
    Enum.map(programs, fn p ->
      updated = Enum.map(p.objectives, fn
        %{id: ^objective_id} = obj -> update_fn.(obj)
        obj -> obj
      end)
      %{p | objectives: updated}
    end)
  end

  defp record_transition(mission_id, action, metadata) do
    ExecutiveMemory.record_event(:mission_state_transition, %{
      mission_id: mission_id, action: action, metadata: metadata
    }, %{correlation_id: "mission_#{mission_id}_#{action}"})
  rescue
    _ -> :ok
  end

  defp emit_event(event_type, mission_id, metadata \\ %{}) do
    EventBus.publish("mission.#{event_type}", Map.put(metadata, :mission_id, mission_id), [])
  rescue
    _ -> :ok
  end

  defp update_status_counts(state, _mission_id, old_status, new_status) do
    counts = state.missions_by_status
    counts = if old_status, do: Map.update(counts, old_status, 1, &max(0, &1 - 1)), else: counts
    counts = Map.update(counts, new_status, 1, &(&1 + 1))
    total = if old_status, do: state.total_missions, else: state.total_missions + 1
    %{state | missions_by_status: counts, total_missions: total}
  end
end
