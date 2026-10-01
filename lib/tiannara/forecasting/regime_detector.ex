defmodule Tiannara.Forecasting.RegimeDetector do
  @moduledoc """
  Conservative change-point detection for forecasting.

  A detected change is a hypothesis about regime structure, not proof of a
  causal transition. The detector emits evidence for downstream validation.
  """

  def detect(series, opts \\ []) when is_list(series) do
    min_segment = Keyword.get(opts, :min_segment, 5)
    threshold = Keyword.get(opts, :mean_shift_threshold, 2.0)

    cond do
      length(series) < min_segment * 2 ->
        {:ok, %{status: :insufficient_history, candidates: [], method: :mean_shift}}

      not Enum.all?(series, &is_number/1) ->
        {:error, :non_numeric_series}

      true ->
        candidates =
          1..(length(series) - min_segment)
          |> Enum.reduce([], fn split, acc ->
            left = Enum.take(series, split)
            right = Enum.drop(series, split)

            if length(left) < min_segment or length(right) < min_segment do
              acc
            else
              lmean = mean(left)
              rmean = mean(right)
              pooled = max(std(series), 1.0e-12)
              effect = abs(rmean - lmean) / pooled

              if effect >= threshold do
                [%{index: split, left_mean: lmean, right_mean: rmean,
                   standardized_shift: effect, status: :candidate} | acc]
              else
                acc
              end
            end
          end)
          |> Enum.reverse()

        {:ok, %{status: if(candidates == [], do: :no_candidate, else: :candidate_detected),
                candidates: candidates, method: :mean_shift,
                evidence_class: :observational_hypothesis}}
    end
  end

  defp mean(values), do: Enum.sum(values) / length(values)

  defp std(values) do
    m = mean(values)
    :math.sqrt(Enum.sum(Enum.map(values, &(:math.pow(&1 - m, 2)))) / length(values))
  end
end
