defmodule TiannaraRuntime.Cognitive.Engines.FocusState do
  @moduledoc false

  defstruct [:active_tasks, :queue, :allocation, :focus_id]

  def new do
    %__MODULE__{active_tasks: [], queue: nil, allocation: nil, focus_id: :erlang.unique_integer([:positive])}
  end

  def set(focus, queue, allocation) do
    tasks = extract_tasks(queue)
    {:ok, %{focus | active_tasks: tasks, queue: queue, allocation: allocation}}
  end

  defp extract_tasks(queue) do
    case queue do
      %{items: items} -> Enum.map(items, fn {task, _score} -> task end)
      queue when is_list(queue) -> queue
      _ -> []
    end
  end
end
