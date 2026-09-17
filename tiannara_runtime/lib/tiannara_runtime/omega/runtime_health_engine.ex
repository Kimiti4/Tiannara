defmodule TiannaraRuntime.Omega.RuntimeHealthEngine do
  @moduledoc """
  Continuous health aggregation for Omega runtime readiness.
  """

  use GenServer

  alias TiannaraRuntime.Omega.{
    CheckpointReliability,
    DependencyIsolation,
    EventStoreAudit,
    ExecutiveMemory,
    FailureObservatory,
    SentinelEventBus
  }

  @default_interval 5_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def status, do: GenServer.call(__MODULE__, :status)

  @impl true
  def init(opts) do
    state = %{
      interval: Keyword.get(opts, :interval, @default_interval),
      last_health: nil,
      samples: 0
    }

    schedule(state.interval)
    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state.last_health || collect_health(), state}
  end

  @impl true
  def handle_info(:sample, state) do
    health = collect_health()
    publish(:runtime_health, health)
    schedule(state.interval)
    {:noreply, %{state | last_health: health, samples: state.samples + 1}}
  end

  defp collect_health do
    processes = %{
      event_bus: alive?(SentinelEventBus),
      executive_memory: alive?(ExecutiveMemory),
      failure_observatory: alive?(FailureObservatory),
      dependency_isolation: alive?(DependencyIsolation),
      checkpoint_reliability: alive?(CheckpointReliability),
      event_store_audit: alive?(EventStoreAudit)
    }

    degraded = processes |> Enum.any?(fn {_name, alive} -> not alive end)

    %{
      status: if(degraded, do: :degraded, else: :healthy),
      timestamp: System.system_time(:millisecond),
      processes: processes,
      erlang: %{
        process_count: :erlang.system_info(:process_count),
        run_queue: :erlang.statistics(:run_queue),
        memory: :erlang.memory(:total)
      },
      executive_memory: safe_call(ExecutiveMemory, :health, []),
      checkpoint_reliability: safe_call(CheckpointReliability, :status, []),
      event_store_audit: safe_call(EventStoreAudit, :status, []),
      dependency_isolation: safe_call(DependencyIsolation, :status, []),
      failure_observatory: safe_call(FailureObservatory, :report, [])
    }
  end

  defp alive?(module) do
    case Process.whereis(module) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  end

  defp safe_call(module, fun, args) do
    if alive?(module), do: apply(module, fun, args), else: %{status: :unavailable}
  rescue
    error -> %{status: :error, reason: inspect(error)}
  catch
    kind, reason -> %{status: :error, reason: inspect({kind, reason})}
  end

  defp publish(topic, payload) do
    if Process.whereis(SentinelEventBus) do
      SentinelEventBus.publish(topic, payload, %{source: __MODULE__})
    end
  end

  defp schedule(interval), do: Process.send_after(self(), :sample, interval)
end
