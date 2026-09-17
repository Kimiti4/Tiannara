defmodule TiannaraRuntime.Omega.ConstitutionalScheduler do
  @moduledoc """
  Priority-aware scheduler with retries, backoff, and throttling hooks.

  Omega preparation uses this for readiness ticks only; experiments are not
  launched here.
  """

  use GenServer

  alias TiannaraRuntime.Omega.{FailureObservatory, SentinelEventBus}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def schedule(name, interval_ms, action \\ nil, opts \\ []) when is_integer(interval_ms) do
    GenServer.call(__MODULE__, {:schedule, name, interval_ms, action, opts})
  end

  def status, do: GenServer.call(__MODULE__, :status)

  @impl true
  def init(opts) do
    state = %{jobs: %{}, ticks: 0}

    state =
      opts
      |> Keyword.get(:jobs, default_jobs())
      |> Enum.reduce(state, fn {name, interval, priority}, acc ->
        put_job(acc, name, interval, nil, priority: priority)
      end)

    {:ok, state}
  end

  @impl true
  def handle_call({:schedule, name, interval_ms, action, opts}, _from, state) do
    {:reply, :ok, put_job(state, name, interval_ms, action, opts)}
  end

  @impl true
  def handle_call(:status, _from, state) do
    jobs = Map.new(state.jobs, fn {name, job} -> {name, Map.drop(job, [:timer, :action])} end)
    {:reply, %{ticks: state.ticks, jobs: jobs}, state}
  end

  @impl true
  def handle_info({:run_job, name}, state) do
    case Map.get(state.jobs, name) do
      nil ->
        {:noreply, state}

      job ->
        {job, event} = run_job(job)
        timer = Process.send_after(self(), {:run_job, name}, next_interval(job))
        job = %{job | timer: timer, last_run: System.system_time(:millisecond)}
        publish(:scheduler_tick, event)
        {:noreply, %{state | jobs: Map.put(state.jobs, name, job), ticks: state.ticks + 1}}
    end
  end

  defp put_job(state, name, interval_ms, action, opts) do
    if old = state.jobs[name], do: Process.cancel_timer(old.timer)

    job = %{
      name: name,
      interval_ms: interval_ms,
      priority: Keyword.get(opts, :priority, :normal),
      action: action,
      failure_count: 0,
      max_retries: Keyword.get(opts, :max_retries, 3),
      backoff_ms: Keyword.get(opts, :backoff_ms, interval_ms),
      last_run: nil,
      last_error: nil,
      timer: Process.send_after(self(), {:run_job, name}, interval_ms)
    }

    %{state | jobs: Map.put(state.jobs, name, job)}
  end

  defp run_job(%{action: nil} = job) do
    {job, %{job: job.name, status: :tick, priority: job.priority}}
  end

  defp run_job(job) do
    execute_action(job.action)

    {%{job | failure_count: 0, last_error: nil},
     %{job: job.name, status: :ok, priority: job.priority}}
  rescue
    error ->
      FailureObservatory.record_failure(:scheduler_job, error, %{job: job.name})

      {%{job | failure_count: job.failure_count + 1, last_error: inspect(error)},
       %{job: job.name, status: :failed, reason: inspect(error), priority: job.priority}}
  catch
    kind, reason ->
      FailureObservatory.record_failure(:scheduler_job, {kind, reason}, %{job: job.name})

      {%{job | failure_count: job.failure_count + 1, last_error: inspect({kind, reason})},
       %{job: job.name, status: :failed, reason: inspect({kind, reason}), priority: job.priority}}
  end

  defp execute_action(fun) when is_function(fun, 0), do: fun.()
  defp execute_action({module, function, args}), do: apply(module, function, args)

  defp next_interval(%{
         failure_count: count,
         max_retries: max,
         backoff_ms: backoff,
         interval_ms: interval
       })
       when count > 0 and count <= max do
    backoff * count
  end

  defp next_interval(%{interval_ms: interval}), do: interval

  defp publish(topic, payload) do
    if Process.whereis(SentinelEventBus) do
      SentinelEventBus.publish(topic, payload, %{source: __MODULE__})
    end
  end

  defp default_jobs do
    [
      {:runtime_metrics, 1_000, :high},
      {:infrastructure_health, 5_000, :high},
      {:dependency_evaluation, 30_000, :normal},
      {:research_scan, 60_000, :normal},
      {:memory_consolidation, 300_000, :normal},
      {:atlas_refresh, 600_000, :low},
      {:civilization_review, 1_800_000, :low},
      {:strategic_review, 3_600_000, :low},
      {:long_term_planning, 86_400_000, :low}
    ]
  end
end
