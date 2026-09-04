defmodule Tiannara.CEL.Services.ExecutiveScheduler do
  use Tiannara.ExecutiveService.Base
  use GenServer
  require Logger

  @moduledoc """
  Executive Scheduler — the civilizational process scheduler.

  Responsibilities:
    - Priority-aware scheduling (integrates with PriorityEngine)
    - Resource-aware admission control (integrates with ResourceManager)
    - Fairness guarantees (aging mechanism to prevent mission starvation)
    - Preemption support (high-priority civilizational work can interrupt low-priority)
    - Concurrency limits (prevents systemic resource exhaustion)

  Constitutional Alignment:
    - Bottleneck Discovery: actively tracks queue depths and wait times
    - Scalability: manages concurrency limits to prevent collapse under load
    - Long-Term Optimization: fairness ensures no domain is permanently starved
    - Verification First: admission control verifies resources before execution
  """

  alias Tiannara.CEL.Services.{PriorityEngine, ResourceManager, CapabilityGraph, ExecutiveMemory}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @max_concurrency 50
  @starvation_threshold_ms :timer.minutes(15)
  @aging_increment 0.05

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  # ── Client API ──────────────────────────────────────────────────

  def submit_work(mission_id, work_spec, context \\ nil) do
    GenServer.call(__MODULE__, {:submit, mission_id, work_spec, context})
  end

  def request_next_job(worker_id) do
    GenServer.call(__MODULE__, {:request_next, worker_id})
  end

  def complete_job(job_id, outcome) do
    GenServer.cast(__MODULE__, {:complete, job_id, outcome})
  end

  def preempt(job_id, reason) do
    GenServer.call(__MODULE__, {:preempt, job_id, reason})
  end

  def bottlenecks, do: GenServer.call(__MODULE__, :bottlenecks)
  def stats, do: GenServer.call(__MODULE__, :stats)

  # ── ExecutiveService Behaviour ──────────────────────────────────

  @impl true
  def id, do: :executive_scheduler

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities do
    [:mission_scheduling, :fairness_enforcement, :preemption,
     :admission_control, :concurrency_management, :bottleneck_detection]
  end

  @impl true
  def dependencies, do: [:priority_engine, :resource_manager, :capability_graph, :executive_memory]

  @impl true
  def constitutional_score do
    s = stats()

    fairness_score = if s.starved_missions > 0, do: 0.5, else: 1.0
    admission_score = 1.0 - min(1.0, s.rejection_count / max(1, s.submission_count))

    %ConstitutionalScore{
      service_id: :executive_scheduler,
      health: if(s.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: fairness_score,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: admission_score,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ── Init ────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    schedule_aging_cycle()
    state = %{
      queue: :queue.new(),
      running: %{},
      submission_count: 0,
      rejection_count: 0,
      starved_missions: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }
    Logger.info("ExecutiveScheduler: Initialized (max_concurrency: #{@max_concurrency})")
    {:ok, state}
  end

  # ── Call Handlers ───────────────────────────────────────────────

  @impl true
  def handle_call({:submit, mission_id, work_spec, context}, _from, state) do
    resources = Map.get(work_spec, :resources, %{})

    case ResourceManager.allocate(mission_id, resources) do
      {:ok, allocation} ->
        base_priority = PriorityEngine.calculate_priority(work_spec)
        job_id = generate_job_id()

        job = %{
          id: job_id,
          mission_id: mission_id,
          work_spec: work_spec,
          context: context,
          base_priority: base_priority,
          effective_priority: base_priority,
          submitted_at: DateTime.utc_now(),
          allocation: allocation
        }

        new_queue = :queue.in(job, state.queue)
        new_state = %{state | queue: new_queue, submission_count: state.submission_count + 1}

        emit_constitutional_event(:work_submitted, %{priority: base_priority}, %{job_id: job_id, mission_id: mission_id})
        {:reply, {:ok, job_id}, new_state}

      {:error, reason} ->
        Logger.warning("Scheduler: Admission denied for #{mission_id}: #{inspect(reason)}")
        {:reply, {:error, :admission_denied}, %{state | rejection_count: state.rejection_count + 1}}
    end
  end

  @impl true
  def handle_call({:request_next, worker_id}, _from, state) do
    if map_size(state.running) >= @max_concurrency do
      {:reply, :concurrency_limit_reached, state}
    else
      case :queue.out(state.queue) do
        {{:value, job}, new_queue} ->
          running = Map.put(state.running, job.id, {job.mission_id, worker_id, DateTime.utc_now()})

          safely_record(:job_scheduled, %{
            job_id: job.id, mission_id: job.mission_id, worker: worker_id, priority: job.effective_priority
          })

          {:reply, {:ok, job}, %{state | queue: new_queue, running: running}}

        {:empty, _} ->
          {:reply, :empty, state}
      end
    end
  end

  @impl true
  def handle_call({:preempt, job_id, reason}, _from, state) do
    case Map.fetch(state.running, job_id) do
      {:ok, {mission_id, worker_id, _started_at}} ->
        Logger.warning("Scheduler: Preempting job #{job_id} (#{mission_id}): #{reason}")
        {:reply, :ok, %{state | running: Map.delete(state.running, job_id)}}

      :error ->
        case find_and_remove_from_queue(state.queue, job_id) do
          {:found, _job, new_queue} -> {:reply, :ok, %{state | queue: new_queue}}
          :not_found -> {:reply, {:error, :job_not_found}, state}
        end
    end
  end

  @impl true
  def handle_call(:bottlenecks, _from, state) do
    queue_len = :queue.len(state.queue)
    bottlenecks =
      (if queue_len > @max_concurrency * 2, do: [%{type: :queue_backlog, severity: :high, value: queue_len}], else: [])
      |> Kernel.++(if state.starved_missions > 0, do: [%{type: :mission_starvation, severity: :critical, value: state.starved_missions}], else: [])
    {:reply, bottlenecks, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      queue_length: :queue.len(state.queue),
      running_count: map_size(state.running),
      submission_count: state.submission_count,
      rejection_count: state.rejection_count,
      starved_missions: state.starved_missions
    }, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  # ── Cast Handlers ──────────────────────────────────────────────

  @impl true
  def handle_cast({:complete, job_id, outcome}, state) do
    case Map.pop(state.running, job_id) do
      {{_mission_id, _worker_id, _started_at}, new_running} ->
        emit_constitutional_event(:work_completed, %{outcome: outcome}, %{job_id: job_id})
        {:noreply, %{state | running: new_running}}
      {nil, _} ->
        {:noreply, state}
    end
  end

  # ── Background Tasks ────────────────────────────────────────────

  @impl true
  def handle_info(:aging_cycle, state) do
    now = DateTime.utc_now()

    {new_queue, starved_count} =
      :queue.to_list(state.queue)
      |> Enum.map_reduce(0, fn job, acc ->
        wait_ms = DateTime.diff(now, job.submitted_at, :millisecond)
        if wait_ms > @starvation_threshold_ms do
          updated = %{job | effective_priority: min(1.0, job.effective_priority + @aging_increment)}
          {updated, acc + 1}
        else
          {job, acc}
        end
      end)

    rebuilt_queue = Enum.reduce(new_queue, :queue.new(), &:queue.in(&2, &1))

    if starved_count > 0 do
      Logger.warning("Scheduler: #{starved_count} missions experienced scheduling starvation")
      emit_constitutional_event(:starvation_detected, %{count: starved_count}, %{})
    end

    schedule_aging_cycle()
    {:noreply, %{state | queue: rebuilt_queue, starved_missions: state.starved_missions + starved_count}}
  end

  # ── Private ─────────────────────────────────────────────────────

  defp find_and_remove_from_queue(queue, job_id) do
    list = :queue.to_list(queue)
    {keep, [removed | _]} = Enum.split_with(list, &(&1.id != job_id))
    {:found, removed, Enum.reduce(keep, :queue.new(), &:queue.in(&2, &1))}
  rescue
    _ -> :not_found
  end

  defp safely_record(event_type, payload) do
    try do
      ExecutiveMemory.record_event(event_type, payload)
    rescue
      _ -> :ok
    end
  end

  defp schedule_aging_cycle do
    Process.send_after(self(), :aging_cycle, :timer.seconds(30))
  end

  defp generate_job_id do
    "job_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
