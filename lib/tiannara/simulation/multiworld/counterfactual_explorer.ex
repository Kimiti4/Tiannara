defmodule Tiannara.Simulation.MultiWorld.CounterfactualExplorer do
  alias Tiannara.Simulation.MultiWorld.Domain.{CounterfactualScenario, WorldFork}

  @spec explore(String.t(), [map()], map()) :: [CounterfactualScenario.t()]
  def explore(baseline_world_id, variables, baseline_outcomes \\ %{}) do
    Enum.map(variables, fn variable ->
      generate_counterfactual(baseline_world_id, variable, variables, baseline_outcomes)
    end)
  end

  @spec explore_interactions(String.t(), [map()]) :: [CounterfactualScenario.t()]
  def explore_interactions(baseline_world_id, variables) when length(variables) >= 2 do
    variables
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [var_a, var_b] ->
      CounterfactualScenario.new(%{
        question: "What if #{Map.get(var_a, :name, "A")} AND #{Map.get(var_b, :name, "B")} change simultaneously?",
        baseline_world_id: baseline_world_id,
        divergence_description: "Simultaneous change in #{Map.get(var_a, :name)} and #{Map.get(var_b, :name)}",
        variables_changed: [var_a, var_b],
        variables_held_constant: variables -- [var_a, var_b],
        confidence: 0.3
      })
    end)
  end

  @spec attribute_causality(CounterfactualScenario.t(), map(), map()) :: map()
  def attribute_causality(%CounterfactualScenario{} = scenario, baseline_outcomes, counterfactual_outcomes) do
    divergences =
      Map.keys(baseline_outcomes)
      |> Enum.map(fn key ->
        baseline_val = Map.get(baseline_outcomes, key, 0.0)
        cf_val = Map.get(counterfactual_outcomes, key, 0.0)
        delta = cf_val - baseline_val

        %{
          dimension: key,
          baseline: baseline_val,
          counterfactual: cf_val,
          delta: delta,
          relative_change: if(baseline_val != 0, do: delta / baseline_val, else: 0.0),
          attribution: classify_attribution(delta, baseline_val)
        }
      end)

    total_abs_delta = Enum.reduce(divergences, 0.0, fn d, acc -> acc + abs(d.delta) end)
    causal_strength = min(1.0, total_abs_delta / max(1, length(divergences)))

    %{
      scenario_id: scenario.id,
      divergences: divergences,
      causal_strength: causal_strength,
      confidence: scenario.confidence * min(1.0, causal_strength * 2),
      primary_cause: identify_primary_cause(divergences),
      interaction_effects: []
    }
  end

  defp generate_counterfactual(baseline_world_id, variable, all_variables, _baseline_outcomes) do
    CounterfactualScenario.new(%{
      question: "What if #{Map.get(variable, :name, "this variable")} were different?",
      baseline_world_id: baseline_world_id,
      divergence_description: "Change #{Map.get(variable, :name)} from #{Map.get(variable, :current_value)} to #{Map.get(variable, :counterfactual_value)}",
      variables_changed: [variable],
      variables_held_constant: all_variables -- [variable],
      expected_outcome: Map.get(variable, :expected_effect),
      confidence: 0.5
    })
  end

  defp classify_attribution(delta, baseline) when baseline == 0, do: :indeterminate
  defp classify_attribution(delta, _baseline) when abs(delta) < 0.01, do: :negligible
  defp classify_attribution(delta, _baseline) when delta > 0, do: :positive_effect
  defp classify_attribution(delta, _baseline) when delta < 0, do: :negative_effect

  defp identify_primary_cause(divergences) do
    case Enum.max_by(divergences, fn d -> abs(d.delta) end, fn -> nil end) do
      nil -> nil
      max_div -> max_div.dimension
    end
  end
end
