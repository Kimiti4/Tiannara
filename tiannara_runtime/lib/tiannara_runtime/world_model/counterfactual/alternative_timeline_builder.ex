defmodule TiannaraRuntime.WorldModel.Counterfactual.AlternativeTimelineBuilder do
  @moduledoc """
  Phase 17.5.4 — AlternativeTimelineBuilder: constructs deterministic timelines
  from a divergence point forward under counterfactual regime.
  """
  alias TiannaraRuntime.WorldModel.Ontology.{WorldModel, Equation, EquationSystem}
  alias TiannaraRuntime.WorldModel.Counterfactual.{BranchNode, DivergencePoint, AlternativeTimeline, TimelineStep}

  @spec construct(WorldModel.t(), BranchNode.t(), DivergencePoint.t(), keyword()) ::
    {:ok, AlternativeTimeline.t()} | {:error, String.t()}
  def construct(%WorldModel{} = world_model, %BranchNode{} = branch, %DivergencePoint{} = dp, opts \\ []) do
    num_steps = Keyword.get(opts, :num_steps, 10)
    state = dp.state
    equations = get_equations(world_model)

    steps = simulate_steps(equations, state, num_steps, dp.intervention)
    final_state = case List.last(steps) do
      nil -> state
      %TimelineStep{state: s} -> s
    end

    {:ok, at} = AlternativeTimeline.new(
      branch_id: branch.branch_id,
      steps: steps,
      initial_state: state,
      final_state: final_state,
      total_steps: length(steps),
      metadata: Keyword.get(opts, :metadata, %{})
    )

    {:ok, at}
  end

  defp get_equations(%WorldModel{equations: %EquationSystem{equations: eqs}}), do: eqs
  defp get_equations(_), do: []

  defp simulate_steps(_equations, state, 0, _intervention), do:
    [%TimelineStep{step: 0, state: state, intervention_active: true}]

  defp simulate_steps(equations, state, n, intervention) do
    first = %TimelineStep{step: 0, state: state, intervention_active: true}
    [first | do_simulate(equations, state, n, intervention, 1)]
  end

  defp do_simulate(_eqs, _state, 0, _interv, _i), do: []

  defp do_simulate(equations, state, n, intervention, i) do
    new_state = evaluate_state(equations, state, intervention, i)
    step = %TimelineStep{
      step: i,
      state: new_state,
      intervention_active: is_intervention_active?(intervention, i)
    }
    [step | do_simulate(equations, new_state, n - 1, intervention, i + 1)]
  end

  defp evaluate_state([], state, _intervention, _i), do: state

  defp evaluate_state([%Equation{target_variable: tv, expression: expr} | rest], state, intervention, i) do
    new_val = evaluate_expression(expr, state, tv, intervention, i)
    evaluate_state(rest, Map.put(state, tv, new_val), intervention, i)
  end

  defp evaluate_expression(%{"form" => "constant"} = expr, _state, _tv, _interv, _i) do
    params = Map.get(expr, "parameters", [])
    if "baseline" in params, do: 0.0, else: 0.0
  end

  defp evaluate_expression(%{"form" => "linear"} = expr, state, tv, intervention, _i) do
    parents = Map.get(expr, "parents", [])
    intercept = 0.5

    parent_sum = Enum.reduce(parents, 0.0, fn p, acc ->
      parent_val = Map.get(state, p, 0.0)
      case intervention.target do
        ^p -> acc + (intervention.value || parent_val)
        _ -> acc + parent_val * 1.0
      end
    end)

    if intervention.target == tv and intervention.operation == :fix do
      intervention.value || (parent_sum + intercept)
    else
      parent_sum + intercept
    end
  end

  defp evaluate_expression(_expr, state, tv, _interv, _i), do: Map.get(state, tv, 0.0)

  defp is_intervention_active?(%{operation: :remove}, _i), do: true
  defp is_intervention_active?(%{operation: :fix}, _i), do: true
  defp is_intervention_active?(_, _i), do: false
end
