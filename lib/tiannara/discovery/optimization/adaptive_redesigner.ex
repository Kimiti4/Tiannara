defmodule Tiannara.Discovery.Optimization.AdaptiveRedesigner do
  alias Tiannara.Discovery.Domain.{ExperimentPlan, DiscoveryResult}

  @spec redesign(ExperimentPlan.t(), [DiscoveryResult.t()]) :: {:redesign, ExperimentPlan.t()} | {:no_change, ExperimentPlan.t()}
  def redesign(%ExperimentPlan{} = plan, results) do
    cond do
      inconclusive?(results) -> {:redesign, increase_sample_size(plan)}
      high_variance?(results) -> {:redesign, add_controls(plan)}
      strongly_positive?(results) -> {:redesign, narrow_scope(plan)}
      strongly_negative?(results) -> {:redesign, broaden_scope(plan)}
      true -> {:no_change, plan}
    end
  end

  @spec adaptation_history(ExperimentPlan.t(), [DiscoveryResult.t()]) :: [map()]
  def adaptation_history(plan, results) do
    results
    |> Enum.chunk_every(3)
    |> Enum.with_index()
    |> Enum.map(fn {window, idx} ->
      decision = case redesign(plan, window) do
        {:redesign, _} -> :adapted
        {:no_change, _} -> :maintained
      end
      %{
        window: idx + 1,
        evidence_count: length(window),
        decision: decision,
        avg_confidence_delta: Enum.reduce(window, 0.0, fn r, acc -> acc + r.confidence_delta end) / max(1, length(window))
      }
    end)
  end

  defp inconclusive?(results) do
    if results == [] do
      false
    else
      inconclusive_count = Enum.count(results, &(&1.outcome == :inconclusive))
      inconclusive_count / length(results) > 0.6
    end
  end

  defp high_variance?(results) do
    if length(results) < 3 do
      false
    else
      deltas = Enum.map(results, & &1.confidence_delta)
      mean = Enum.sum(deltas) / length(deltas)
      variance = Enum.reduce(deltas, 0.0, fn d, acc -> acc + :math.pow(d - mean, 2) end) / length(deltas)
      variance > 0.1
    end
  end

  defp strongly_positive?(results) do
    if results == [] do
      false
    else
      confirmed = Enum.count(results, &(&1.outcome == :confirmed))
      confirmed / length(results) > 0.9
    end
  end

  defp strongly_negative?(results) do
    if results == [] do
      false
    else
      refuted = Enum.count(results, &(&1.outcome == :refuted))
      refuted / length(results) > 0.7
    end
  end

  defp increase_sample_size(%ExperimentPlan{} = plan) do
    %{plan |
      inputs: Map.update(plan.inputs, :sample_size, 200, fn current -> current * 2 end),
      stopping_criteria: Map.put(plan.stopping_criteria, :max_iterations,
        Map.get(plan.stopping_criteria, :max_iterations, 1000) * 2)
    }
  end

  defp add_controls(%ExperimentPlan{} = plan) do
    new_controls = plan.controls ++ [
      %{name: :variance_control, description: "Additional control to reduce variance"},
      %{name: :confound_check, description: "Check for suspected confounding variables"}
    ]
    %{plan | controls: new_controls}
  end

  defp narrow_scope(%ExperimentPlan{} = plan) do
    %{plan |
      inputs: Map.put(plan.inputs, :precision_mode, true),
      stopping_criteria: Map.put(plan.stopping_criteria, :confidence_threshold, 0.99)
    }
  end

  defp broaden_scope(%ExperimentPlan{} = plan) do
    %{plan |
      inputs: Map.put(plan.inputs, :exploration_mode, true),
      variables: plan.variables ++ [%{name: :additional_variable, description: "Explore additional factors"}]
    }
  end
end
