defmodule TiannaraRuntime.Cognitive.Engines.AttentionQueue do
  @moduledoc false

  defstruct [:items]

  def new do
    %__MODULE__{items: []}
  end

  def enqueue(queue, task, score) do
    items = queue.items ++ [{task, score}]
    sorted = Enum.sort_by(items, fn {_t, s} -> -s end)
    {:ok, %{queue | items: sorted}}
  end

  def dequeue(queue) do
    case queue.items do
      [] -> {:error, :empty}
      [first | rest] -> {:ok, %{queue | items: rest}, first}
    end
  end
end
