defmodule Tiannara.Agency.ComplexTaskRuntime do
  @moduledoc """
  Bounded dependency-aware task executor.

  A task is %{id: term(), deps: [term()], run: (() -> term())}. The executor
  validates the DAG, runs independent tasks concurrently through the existing
  Task.Supervisor, waits only within a caller-defined deadline, and returns a
  complete execution trace. It is the deterministic execution substrate for
  complex/JARVIS-style missions; planning and natural-language decomposition
  remain separate concerns.
  """

  @default_timeout 30_000
  @max_tasks 256

  def execute(tasks, opts \\ []) when is_list(tasks) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    with :ok <- validate(tasks),
         {:ok, order} <- topological_order(tasks) do
      started = System.monotonic_time(:millisecond)
      task_map = Map.new(tasks, &{&1.id, &1})
      run_levels(order, task_map, timeout, %{}, started)
    end
  end

  defp validate(tasks) do
    cond do
      length(tasks) > @max_tasks -> {:error, :task_limit_exceeded}
      Enum.any?(tasks, &(not is_map(&1) or not is_function(Map.get(&1, :run), 0))) ->
        {:error, :invalid_task}
      Enum.uniq(Enum.map(tasks, & &1.id)) |> length() != length(tasks) ->
        {:error, :duplicate_task_id}
      Enum.any?(tasks, fn task -> Enum.any?(task.deps, &(&1 == task.id)) end) ->
        {:error, :self_dependency}
      true ->
        ids = MapSet.new(Enum.map(tasks, & &1.id))
        if Enum.any?(tasks, fn t -> Enum.any?(t.deps, &(not MapSet.member?(ids, &1))) end) do
          {:error, :unknown_dependency}
        else
          :ok
        end
    end
  end

  defp topological_order(tasks) do
    deps = Map.new(tasks, &{&1.id, MapSet.new(&1.deps)})
    visit_all(Map.keys(deps), deps, MapSet.new(), [])
  end

  defp visit_all([], _deps, _visiting, order), do: {:ok, Enum.reverse(order)}
  defp visit_all([id | rest], deps, visiting, order) do
    case visit(id, deps, visiting, MapSet.new(order)) do
      {:ok, order_set} -> visit_all(rest, deps, visiting, MapSet.to_list(order_set))
      {:error, _} = error -> error
    end
  end

  defp visit(id, deps, visiting, done) do
    cond do
      MapSet.member?(done, id) -> {:ok, done}
      MapSet.member?(visiting, id) -> {:error, :dependency_cycle}
      true ->
        visiting = MapSet.put(visiting, id)
        Enum.reduce_while(Map.get(deps, id, MapSet.new()) |> MapSet.to_list(), {:ok, done}, fn dep, {:ok, acc} ->
          case visit(dep, deps, visiting, acc) do
            {:ok, next} -> {:cont, {:ok, next}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
        |> case do
          {:ok, acc} -> {:ok, MapSet.put(acc, id)}
          error -> error
        end
    end
  end

  defp run_levels(order, task_map, timeout, results, started) do
    remaining = Enum.reject(order, &Map.has_key?(results, &1))

    if remaining == [] do
      {:ok, %{status: :completed, results: results, elapsed_ms: System.monotonic_time(:millisecond) - started}}
    else
      ready =
        Enum.filter(remaining, fn id ->
          task_map[id].deps |> Enum.all?(&Map.has_key?(results, &1))
        end)

      if ready == [] do
        {:error, :dependency_cycle}
      else
        elapsed = System.monotonic_time(:millisecond) - started
        if elapsed >= timeout do
          {:ok, %{status: :timeout, results: results, elapsed_ms: elapsed}}
        else
          handles =
            Enum.map(ready, fn id ->
              task = task_map[id]
              {id, Task.Supervisor.async_nolink(Tiannara.ExtrusionTaskSupervisor, task.run)}
            end)

          remaining_timeout = max(timeout - elapsed, 0)
          new_results =
            Enum.reduce(handles, results, fn {id, task}, acc ->
              result =
                case Task.yield(task, remaining_timeout) do
                  {:ok, value} -> %{status: :completed, value: value}
                  {:exit, reason} -> %{status: :failed, reason: reason}
                  nil ->
                    Task.shutdown(task, :brutal_kill)
                    %{status: :timeout}
                end

              Map.put(acc, id, result)
            end)

          if Enum.any?(ready, fn id -> new_results[id].status != :completed end) do
            {:ok, %{status: :degraded, results: new_results,
              elapsed_ms: System.monotonic_time(:millisecond) - started}}
          else
            run_levels(order, task_map, timeout, new_results, started)
          end
        end
      end
    end
  end
end
