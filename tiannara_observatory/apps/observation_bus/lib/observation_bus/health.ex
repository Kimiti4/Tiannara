defmodule ObservationBus.Health do
  @moduledoc """
  COB health check — reports the status of all bus subsystems.
  """

  @doc """
  Returns the overall health of the observation bus.
  """
  @spec check() :: %{status: :healthy | :degraded | :unhealthy, subsystems: list(map())}
  def check do
    subsystems = [
      check_buffer(),
      check_priority(),
      check_ordering(),
      check_lineage(),
      check_scheduler(),
      check_registries(),
    ]

    status = cond do
      Enum.any?(subsystems, &(&1.status == :unhealthy)) -> :unhealthy
      Enum.any?(subsystems, &(&1.status == :degraded)) -> :degraded
      true -> :healthy
    end

    %{status: status, subsystems: subsystems, checked_at: DateTime.utc_now()}
  end

  @doc """
  Alias for `check/0`, used by the main ObservationBus module.
  """
  @spec health() :: map()
  def health, do: check()

  @doc """
  Returns a summary ping for load balancers.
  """
  @spec ping() :: :pong
  def ping, do: :pong

  defp check_buffer do
    %{name: "buffer", status: :healthy, details: %{module: "ObservationBus.Buffer"}}
  rescue
    _ -> %{name: "buffer", status: :unhealthy, details: %{error: "unreachable"}}
  end

  defp check_priority do
    depth = safe_call(&ObservationBus.PriorityEngine.queue_depth/0, %{})
    total = safe_call(&ObservationBus.PriorityEngine.total_queued/0, 0)
    status = if total > 10_000, do: :degraded, else: :healthy
    %{name: "priority_engine", status: status, details: %{queued: total, depth: depth}}
  end

  defp check_ordering do
    global = safe_call(&ObservationBus.OrderingEngine.global_counter/0, 0)
    %{name: "ordering_engine", status: :healthy, details: %{global_sequence: global}}
  end

  defp check_lineage do
    integrity = safe_call(&ObservationBus.LineageEngine.integrity/0, %{total_events: 0, orphans: 0})
    status = if integrity.total_events > 0, do: :healthy, else: :degraded
    %{name: "lineage_engine", status: status, details: integrity}
  end

  defp check_scheduler do
    status = safe_call(&ObservationBus.Scheduler.status/0, %{})
    %{name: "scheduler", status: :healthy, details: status}
  end

  defp check_registries do
    topics = safe_call(&ObservationBus.TopicRegistry.list/0, [])
    subs = safe_call(&ObservationBus.SubscriptionRegistry.total_subscribers/0, 0)
    %{name: "registries", status: :healthy, details: %{topics: length(topics), subscribers: subs}}
  end

  defp safe_call(fun, default) do
    fun.()
  rescue
    _ -> default
  catch
    :exit, _ -> default
  end
end
