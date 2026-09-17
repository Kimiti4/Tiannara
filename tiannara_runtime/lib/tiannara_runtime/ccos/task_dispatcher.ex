defmodule TiannaraRuntime.CCOS.TaskDispatcher do
  @moduledoc """
  Phase 18.2 Task Dispatcher.

  Routes tasks to certified subsystem references. It creates dispatch intents
  only; it does not execute subsystem logic.
  """

  alias TiannaraRuntime.CCOS.Artifact

  @spec dispatch(map(), [map()]) :: {:ok, map()} | {:error, String.t()}
  def dispatch(attention_state, certified_subsystems)
      when is_map(attention_state) and is_list(certified_subsystems) do
    subsystem_index =
      certified_subsystems
      |> Enum.map(fn subsystem -> {subsystem_key(subsystem), subsystem} end)
      |> Map.new()

    attention_state
    |> Map.fetch!(:ordered_tasks)
    |> Enum.reduce_while({:ok, []}, fn task, {:ok, acc} ->
      target = Map.get(task, :target_subsystem) || Map.get(task, "target_subsystem")

      case Map.fetch(subsystem_index, target) do
        {:ok, subsystem} ->
          intent = %{
            task_ref: Artifact.fingerprint(task),
            target_subsystem: target,
            subsystem_ref: Artifact.fingerprint(subsystem),
            dispatch_kind: :intent_only
          }

          {:cont, {:ok, [Map.put(intent, :dispatch_id, Artifact.content_id("cckdispatch", intent)) | acc]}}

        :error ->
          {:halt, {:error, "certified subsystem is unavailable for target #{inspect(target)}"}}
      end
    end)
    |> case do
      {:ok, intents} ->
        dispatch = %{
          attention_state_id: Map.fetch!(attention_state, :attention_state_id),
          dispatch_intents: Enum.reverse(intents)
        }

        {:ok, Map.put(dispatch, :dispatch_root_id, Artifact.content_id("cckdispatchroot", dispatch))}

      error ->
        error
    end
  end

  def dispatch(_attention_state, _certified_subsystems),
    do: {:error, "TaskDispatcher.dispatch requires attention state and certified subsystems"}

  defp subsystem_key(subsystem) when is_map(subsystem) do
    Map.get(subsystem, :subsystem) || Map.get(subsystem, "subsystem")
  end
end
