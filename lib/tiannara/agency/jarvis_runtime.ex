defmodule Tiannara.Agency.JarvisRuntime do
  @moduledoc """
  Bounded cognitive orchestration inspired by the JARVIS architecture.

  It provides measurable intent classification, bounded parallel delegation,
  validation, timeouts and graceful degradation. It does not claim AGI,
  consciousness, or unrestricted autonomous control.
  """

  @max_domains 6
  @default_timeout 5_000

  @spec execute(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def execute(request, opts \\ []) when is_binary(request) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    started = System.monotonic_time(:millisecond)
    {intent, domains} = Tiannara.AAL.LexicalTensegrityField.map_intent_vectors(request)
    selected = Enum.take(domains, @max_domains)

    tasks =
      Enum.map(selected, fn domain ->
        Task.Supervisor.async_nolink(Tiannara.ExtrusionTaskSupervisor, fn ->
          Tiannara.Domains.Extruder.extract_blueprint(domain, intent)
        end)
      end)

    results =
      Task.yield_many(tasks, timeout)
      |> Enum.map(fn {task, result} ->
        case result do
          {:ok, value} -> %{status: :completed, result: value}
          nil ->
            Task.shutdown(task, :brutal_kill)
            %{status: :timeout}
          {:exit, reason} -> %{status: :failed, reason: reason}
        end
      end)

    completed = Enum.filter(results, &(&1.status == :completed))
    validated = completed |> Enum.map(& &1.result) |> Tiannara.AAL.BlueprintValidator.validate()

    status =
      cond do
        selected == [] -> :rejected
        length(validated) == length(selected) -> :completed
        validated != [] -> :degraded
        true -> :failed
      end

    {:ok,
     %{
       request: request,
       intent: intent,
       domains: selected,
       status: status,
       completed: length(completed),
       validated: length(validated),
       results: results,
       elapsed_ms: System.monotonic_time(:millisecond) - started
     }}
  end
end
