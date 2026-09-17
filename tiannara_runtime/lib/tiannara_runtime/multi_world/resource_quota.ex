defmodule TiannaraRuntime.MultiWorld.ResourceQuota do
  @moduledoc """
  PHASE 5 SAFEGUARD #1: World Resource Quotas

  Prevents runaway world spawning by enforcing strict limits on:
  - Maximum concurrent worlds
  - CPU time per world
  - Memory allocation per world
  - Event processing rate per world

  This is a HARD LIMIT — worlds exceeding quotas are automatically throttled
  or terminated to protect system stability.
  """

  use GenServer
  require Logger

  @default_max_worlds 10
  @default_max_cpu_seconds_per_world 300
  @default_max_memory_mb_per_world 512
  @default_max_events_per_second 1000

  defstruct [
    max_worlds: @default_max_worlds,
    max_cpu_seconds: @default_max_cpu_seconds_per_world,
    max_memory_mb: @default_max_memory_mb_per_world,
    max_events_per_second: @default_max_events_per_second,
    active_worlds: %{},
    total_worlds_created: 0
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def request_world_spawn(world_id) do
    GenServer.call(__MODULE__, {:request_spawn, world_id})
  end

  def report_usage(world_id, cpu_seconds, memory_mb, events_per_second) do
    GenServer.cast(__MODULE__, {:report_usage, world_id, cpu_seconds, memory_mb, events_per_second})
  end

  def check_quota(world_id) do
    GenServer.call(__MODULE__, {:check_quota, world_id})
  end

  def terminate_world(world_id, reason \\ :quota_exceeded) do
    GenServer.cast(__MODULE__, {:terminate_world, world_id, reason})
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  def update_limits(new_limits) do
    GenServer.cast(__MODULE__, {:update_limits, new_limits})
  end

  @impl true
  def init(_opts) do
    Logger.info("ResourceQuota supervisor started")
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call({:request_spawn, world_id}, _from, state) do
    active_count = map_size(state.active_worlds)

    if active_count >= state.max_worlds do
      Logger.warning("World spawn rejected: max worlds exceeded (#{active_count}/#{state.max_worlds})")
      {:reply, {:error, :max_worlds_exceeded}, state}
    else
      new_worlds = Map.put(state.active_worlds, world_id, %{
        cpu_seconds: 0,
        memory_mb: 0,
        events_per_second: 0,
        created_at: System.system_time(:second)
      })

      new_state = %{state |
        active_worlds: new_worlds,
        total_worlds_created: state.total_worlds_created + 1
      }

      Logger.info("World #{world_id} spawned (#{active_count + 1}/#{state.max_worlds})")
      {:reply, {:ok, world_id}, new_state}
    end
  end

  @impl true
  def handle_call({:check_quota, world_id}, _from, state) do
    case Map.get(state.active_worlds, world_id) do
      nil ->
        {:reply, {:error, :world_not_found}, state}

      usage ->
        violations = []
        warnings = []

        if usage.cpu_seconds > state.max_cpu_seconds do
          violations = ["CPU time exceeded (#{usage.cpu_seconds}s > #{state.max_cpu_seconds}s)" | violations]
        end

        if usage.cpu_seconds > state.max_cpu_seconds * 0.8 and usage.cpu_seconds <= state.max_cpu_seconds do
          warnings = ["CPU time approaching limit (#{usage.cpu_seconds}s)" | warnings]
        end

        if usage.memory_mb > state.max_memory_mb do
          violations = ["Memory exceeded (#{usage.memory_mb}MB > #{state.max_memory_mb}MB)" | violations]
        end

        if usage.memory_mb > state.max_memory_mb * 0.8 and usage.memory_mb <= state.max_memory_mb do
          warnings = ["Memory approaching limit (#{usage.memory_mb}MB)" | warnings]
        end

        if usage.events_per_second > state.max_events_per_second do
          violations = ["Event rate exceeded (#{usage.events_per_second}/s > #{state.max_events_per_second}/s)" | violations]
        end

        if usage.events_per_second > state.max_events_per_second * 0.8 and usage.events_per_second <= state.max_events_per_second do
          warnings = ["Event rate approaching limit (#{usage.events_per_second}/s)" | warnings]
        end

        result = cond do
          length(violations) > 0 ->
            Logger.warning("World #{world_id} quota violation: #{Enum.join(violations, ", ")}")
            {:violation, violations}

          length(warnings) > 0 ->
            Logger.info("World #{world_id} quota warning: #{Enum.join(warnings, ", ")}")
            {:warning, warnings}

          true ->
            :ok
        end

        {:reply, result, state}
    end
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      max_worlds: state.max_worlds,
      active_worlds: map_size(state.active_worlds),
      total_worlds_created: state.total_worlds_created,
      worlds: Enum.map(state.active_worlds, fn {id, usage} ->
        {id, %{
          cpu_seconds: usage.cpu_seconds,
          memory_mb: usage.memory_mb,
          events_per_second: usage.events_per_second,
          uptime_seconds: System.system_time(:second) - usage.created_at
        }}
      end) |> Map.new()
    }

    {:reply, {:ok, status}, state}
  end

  @impl true
  def handle_cast({:report_usage, world_id, cpu_seconds, memory_mb, events_per_second}, state) do
    case Map.get(state.active_worlds, world_id) do
      nil ->
        Logger.warning("Usage report for unknown world: #{world_id}")
        {:ok, state}

      _usage ->
        new_worlds = Map.update!(state.active_worlds, world_id, fn usage ->
          %{usage |
            cpu_seconds: cpu_seconds,
            memory_mb: memory_mb,
            events_per_second: events_per_second
          }
        end)

        {:ok, %{state | active_worlds: new_worlds}}
    end
  end

  @impl true
  def handle_cast({:terminate_world, world_id, reason}, state) do
    case Map.get(state.active_worlds, world_id) do
      nil ->
        Logger.warning("Termination requested for unknown world: #{world_id}")
        {:ok, state}

      _usage ->
        new_worlds = Map.delete(state.active_worlds, world_id)
        new_state = %{state | active_worlds: new_worlds}

        Logger.info("World #{world_id} terminated: #{reason}")

        notify_world_supervisor(world_id, reason)

        {:ok, new_state}
    end
  end

  @impl true
  def handle_cast({:update_limits, new_limits}, state) do
    new_state = %{state |
      max_worlds: Map.get(new_limits, :max_worlds, state.max_worlds),
      max_cpu_seconds: Map.get(new_limits, :max_cpu_seconds, state.max_cpu_seconds),
      max_memory_mb: Map.get(new_limits, :max_memory_mb, state.max_memory_mb),
      max_events_per_second: Map.get(new_limits, :max_events_per_second, state.max_events_per_second)
    }

    Logger.info("Resource quotas updated: #{inspect(new_limits)}")
    {:ok, new_state}
  end

  defp notify_world_supervisor(world_id, reason) do
    send(TiannaraRuntime.MultiWorld.WorldSupervisor, {:terminate_world, world_id, reason})
  end
end
