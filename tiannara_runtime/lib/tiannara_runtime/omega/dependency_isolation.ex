defmodule TiannaraRuntime.Omega.DependencyIsolation do
  @moduledoc """
  Lightweight circuit breaker registry for optional runtime dependencies.
  """

  use GenServer

  alias TiannaraRuntime.Omega.{FailureObservatory, SentinelEventBus}

  @default_failure_threshold 3
  @default_cooldown_ms 30_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register(id, opts \\ []) do
    GenServer.call(__MODULE__, {:register, id, opts})
  end

  def available?(id) do
    GenServer.call(__MODULE__, {:available?, id})
  end

  def report_success(id) do
    GenServer.cast(__MODULE__, {:success, id})
  end

  def report_failure(id, reason) do
    GenServer.cast(__MODULE__, {:failure, id, reason})
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  def with_dependency(id, fun) when is_function(fun, 0) do
    if available?(id) do
      try do
        result = fun.()
        report_success(id)
        {:ok, result}
      rescue
        error ->
          report_failure(id, error)
          {:error, error}
      catch
        kind, reason ->
          report_failure(id, {kind, reason})
          {:error, {kind, reason}}
      end
    else
      {:error, :dependency_unavailable}
    end
  end

  @impl true
  def init(_opts) do
    {:ok, %{dependencies: %{}}}
  end

  @impl true
  def handle_call({:register, id, opts}, _from, state) do
    dependency = %{
      id: id,
      status: :closed,
      failure_count: 0,
      success_count: 0,
      last_error: nil,
      opened_until: nil,
      failure_threshold: Keyword.get(opts, :failure_threshold, @default_failure_threshold),
      cooldown_ms: Keyword.get(opts, :cooldown_ms, @default_cooldown_ms)
    }

    {:reply, :ok, %{state | dependencies: Map.put(state.dependencies, id, dependency)}}
  end

  @impl true
  def handle_call({:available?, id}, _from, state) do
    dependency = Map.get(state.dependencies, id, default_dependency(id))
    {available, dependency} = dependency_available(dependency)
    {:reply, available, %{state | dependencies: Map.put(state.dependencies, id, dependency)}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state.dependencies, state}
  end

  @impl true
  def handle_cast({:success, id}, state) do
    dependency =
      state.dependencies
      |> Map.get(id, default_dependency(id))
      |> Map.merge(%{status: :closed, failure_count: 0, opened_until: nil})
      |> Map.update!(:success_count, &(&1 + 1))

    publish(:dependency_recovered, %{id: id})
    {:noreply, %{state | dependencies: Map.put(state.dependencies, id, dependency)}}
  end

  @impl true
  def handle_cast({:failure, id, reason}, state) do
    dependency = Map.get(state.dependencies, id, default_dependency(id))
    failure_count = dependency.failure_count + 1

    dependency =
      dependency
      |> Map.put(:failure_count, failure_count)
      |> Map.put(:last_error, inspect(reason))
      |> maybe_open_circuit(failure_count)

    FailureObservatory.record_failure(:dependency_failure, reason, %{dependency: id})
    publish(:dependency_failure, %{id: id, failure_count: failure_count})

    {:noreply, %{state | dependencies: Map.put(state.dependencies, id, dependency)}}
  end

  defp dependency_available(%{status: :open, opened_until: opened_until} = dependency) do
    if opened_until && System.monotonic_time(:millisecond) >= opened_until do
      {true, %{dependency | status: :half_open}}
    else
      {false, dependency}
    end
  end

  defp dependency_available(dependency), do: {true, dependency}

  defp maybe_open_circuit(dependency, failure_count) do
    if failure_count >= dependency.failure_threshold do
      %{
        dependency
        | status: :open,
          opened_until: System.monotonic_time(:millisecond) + dependency.cooldown_ms
      }
    else
      dependency
    end
  end

  defp default_dependency(id) do
    %{
      id: id,
      status: :closed,
      failure_count: 0,
      success_count: 0,
      last_error: nil,
      opened_until: nil,
      failure_threshold: @default_failure_threshold,
      cooldown_ms: @default_cooldown_ms
    }
  end

  defp publish(topic, payload) do
    if Process.whereis(SentinelEventBus) do
      SentinelEventBus.publish(topic, payload, %{source: __MODULE__})
    end
  end
end
