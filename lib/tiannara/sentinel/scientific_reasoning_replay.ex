defmodule Tiannara.Sentinel.ScientificReasoningReplay do
  @moduledoc """
  Deterministic replay and failure-localization for recorded scientific reasoning.

  Replay evaluates a recorded sequence of reasoning steps against an explicitly
  supplied observer. It does not re-run arbitrary code from historical records.
  A step must be represented as data and interpreted by the supplied observer.

  A replay can identify the first step whose expected state diverges from the
  observed state. It never converts a failed historical theory into truth.
  """

  @spec replay(map(), (map() -> {:ok, term()} | {:error, term()})) ::
          {:ok, map()} | {:error, term()}
  def replay(record, observer) when is_map(record) and is_function(observer, 1) do
    with {:ok, steps} <- extract_steps(record),
         {:ok, results} <- evaluate(steps, observer, 1, []) do
      {:ok, %{
        record_id: Map.get(record, :id),
        status: :replayed,
        replay_mode: :deterministic_data_interpretation,
        steps_evaluated: length(results),
        results: Enum.reverse(results),
        first_divergence: first_divergence(Enum.reverse(results)),
        lesson: derive_lesson(Enum.reverse(results)),
        certification_eligible: false
      }}
    end
  end

  def replay(_, _), do: {:error, :invalid_replay_input}

  defp extract_steps(record) do
    artifact = Map.get(record, :artifact, %{})
    steps = Map.get(artifact, :reasoning_steps)

    cond do
      is_list(steps) and steps != [] -> {:ok, steps}
      true -> {:error, :reasoning_steps_unavailable}
    end
  end

  defp evaluate([], _observer, _index, acc), do: {:ok, acc}

  defp evaluate([step | rest], observer, index, acc) do
    step_data = normalize_step(step, index)

    case observer.(step_data) do
      {:ok, observed} ->
        evaluate(rest, observer, index + 1, [
          %{index: index, step: step, outcome: :consistent, observed: observed} | acc
        ])

      {:error, reason} ->
        {:ok, Enum.reverse([
          %{index: index, step: step, outcome: :diverged, observed: reason} | acc
        ]) |> Kernel.++(remaining_unchecked(rest, index + 1))}
    end
  end

  defp remaining_unchecked(steps, start_index) do
    Enum.with_index(steps, start_index)
    |> Enum.map(fn {step, index} ->
      %{index: index, step: step, outcome: :not_evaluated}
    end)
  end

  defp normalize_step(step, index) when is_map(step), do: Map.put(step, :replay_index, index)
  defp normalize_step(step, index), do: %{value: step, replay_index: index}

  defp first_divergence(results) do
    case Enum.find(results, &(&1.outcome == :diverged)) do
      nil -> nil
      result -> result
    end
  end

  defp derive_lesson(results) do
    case first_divergence(results) do
      nil -> %{type: :no_divergence_observed, action: :retain_as_historical_reasoning}
      %{index: index, step: step} ->
        %{
          type: :first_observed_divergence,
          step_index: index,
          failed_step: step,
          action: :review_assumption_or_observation
        }
    end
  end
end
