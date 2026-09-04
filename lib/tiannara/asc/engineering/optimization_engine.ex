defmodule Tiannara.ASC.Engineering.OptimizationEngine do
  use GenServer

  @objectives [:cost, :performance, :reliability, :safety, :sustainability, :manufacturability]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def optimize(design, weights \\ %{}) do
    GenServer.call(__MODULE__, {:optimize, design, weights}, 30_000)
  end

  def pareto_front(designs) do
    GenServer.call(__MODULE__, {:pareto, designs}, 30_000)
  end

  def solve_constraints(design, constraints) do
    GenServer.call(__MODULE__, {:solve, design, constraints}, 30_000)
  end

  @impl true
  def init(_opts) do
    {:ok, %{optimizations: 0}}
  end

  @impl true
  def handle_call({:optimize, design, weights}, _from, state) do
    effective_weights = Map.merge(default_weights(), weights)

    scores = score_design(design, effective_weights)
    composite = weighted_sum(scores, effective_weights)
    bottlenecks = identify_bottlenecks(scores)

    optimized = Map.merge(design, %{
      optimization_scores: scores,
      composite_score: composite,
      bottlenecks: bottlenecks,
      optimized_at: DateTime.utc_now()
    })

    {:reply, {:ok, optimized}, %{state | optimizations: state.optimizations + 1}}
  end

  @impl true
  def handle_call({:pareto, designs}, _from, state) do
    scored = Enum.map(designs, fn d ->
      scores = score_design(d, default_weights())
      {d, scores}
    end)

    front = Enum.filter(scored, fn {_d, scores} ->
      not Enum.any?(scored, fn {_other, other_scores} ->
        dominates?(other_scores, scores)
      end)
    end)

    {:reply, {:ok, Enum.map(front, fn {d, _s} -> d end)}, state}
  end

  @impl true
  def handle_call({:solve, design, constraints}, _from, state) do
    results = Enum.map(constraints, fn constraint ->
      satisfied = check_constraint(design, constraint)
      %{constraint: constraint, satisfied: satisfied}
    end)

    all_satisfied = Enum.all?(results, & &1.satisfied)

    {:reply, {:ok, %{feasible: all_satisfied, results: results}}, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp default_weights do
    %{cost: 0.15, performance: 0.20, reliability: 0.20, safety: 0.25, sustainability: 0.10, manufacturability: 0.10}
  end

  defp score_design(design, _weights) do
    constraints = Map.get(design, :constraints, %{})
    components = Map.get(design, :components, [])

    %{
      cost: 0.7,
      performance: min(1.0, 0.5 + length(components) * 0.1),
      reliability: Map.get(constraints, :availability_target, 0.99),
      safety: if(Map.get(constraints, :safety_critical, false), do: 0.9, else: 0.7),
      sustainability: 0.6,
      manufacturability: 0.7
    }
  end

  defp weighted_sum(scores, weights) do
    Enum.reduce(@objectives, 0.0, fn obj, acc ->
      acc + Map.get(scores, obj, 0.5) * Map.get(weights, obj, 0.0)
    end)
  end

  defp identify_bottlenecks(scores) do
    scores
    |> Enum.filter(fn {_obj, score} -> score < 0.5 end)
    |> Enum.map(fn {obj, score} -> %{objective: obj, score: score, severity: :high} end)
  end

  defp dominates?(scores_a, scores_b) do
    all_geq = Enum.all?(@objectives, fn obj ->
      Map.get(scores_a, obj, 0) >= Map.get(scores_b, obj, 0)
    end)

    any_gt = Enum.any?(@objectives, fn obj ->
      Map.get(scores_a, obj, 0) > Map.get(scores_b, obj, 0)
    end)

    all_geq and any_gt
  end

  defp check_constraint(design, constraint) do
    case Map.get(constraint, :type) do
      :max_latency -> Map.get(design, :constraints, %{}) |> Map.get(:max_latency_ms, 1000) <= Map.get(constraint, :value, 1000)
      :max_memory -> Map.get(design, :constraints, %{}) |> Map.get(:max_memory_mb, 512) <= Map.get(constraint, :value, 512)
      _ -> true
    end
  end
end
