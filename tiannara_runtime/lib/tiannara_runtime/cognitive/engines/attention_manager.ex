defmodule TiannaraRuntime.Cognitive.Engines.AttentionManager do
  @moduledoc false

  alias TiannaraRuntime.Cognitive.Engines.{
    AttentionPolicy, AttentionQueue, AttentionBudget,
    PriorityEvaluator, ResourceAllocator, FocusState, AttentionReplay
  }

  defstruct [:queue, :budget, :focus, :history, :allocation]

  def new do
    %__MODULE__{
      queue: AttentionQueue.new(),
      budget: nil,
      focus: FocusState.new(),
      history: [],
      allocation: nil
    }
  end

  def allocate(tasks, budgets \\ nil, _working_memory \\ %{}) do
    budgets = budgets || %{cpu: 100, memory: 100, simulation: 50, mathematics: 50, research: 50, world_model: 50}
    criteria = AttentionPolicy.get_default_criteria()

    scored = Enum.map(tasks, fn t ->
      {t, AttentionPolicy.evaluate(t, criteria)}
    end)

    queue = Enum.reduce(scored, AttentionQueue.new(), fn {t, s}, q ->
      {:ok, q2} = AttentionQueue.enqueue(q, t, s)
      q2
    end)

    allocation =
      tasks
      |> Enum.with_index()
      |> Map.new(fn {t, idx} -> {idx, t} end)

    {:ok, %{
      queue: queue,
      allocation: allocation,
      budget: budgets,
      scored_tasks: scored,
      task_count: length(tasks)
    }}
  end

  def record_history(manager, cycle_info) do
    {:ok, %{manager | history: manager.history ++ [cycle_info], allocation: cycle_info}}
  end

  def allocation_history(manager) do
    manager.history
  end
end
