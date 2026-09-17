defmodule TiannaraRuntime.WorldModel.Prediction.ForecastComparator do
  @moduledoc """
  Phase 17.4.5 — ForecastComparator: compares multiple forecasts, computes
  divergence metrics, builds consensus, and ranks by confidence.
  """
  alias TiannaraRuntime.WorldModel.Prediction.{Forecast, ForecastStep, ForecastComparison}

  @spec compare([Forecast.t()]) ::
    {:ok, ForecastComparison.t()} | {:error, String.t()}
  def compare(forecasts) when length(forecasts) < 2 do
    {:error, "Need at least 2 forecasts to compare"}
  end

  def compare(forecasts) do
    divergence = compute_overall_divergence(forecasts)
    consensus = build_consensus(forecasts)
    ranking = rank_by_confidence(forecasts)

    ForecastComparison.new(
      forecasts: forecasts,
      divergence: divergence,
      consensus: consensus,
      confidence_ranking: ranking,
      explanation: build_explanation(divergence, ranking)
    )
  end

  @spec compute_divergence(Forecast.t(), Forecast.t()) :: float()
  def compute_divergence(%Forecast{} = a, %Forecast{} = b) do
    step_pairs = align_steps(a.time_steps, b.time_steps)

    case step_pairs do
      [] -> 1.0
      pairs ->
        squared_errors =
          Enum.flat_map(pairs, fn {%ForecastStep{values: va}, %ForecastStep{values: vb}} ->
            common_vars = MapSet.intersection(
              MapSet.new(Map.keys(va)),
              MapSet.new(Map.keys(vb))
            )

            Enum.map(common_vars, fn v ->
              av = Map.get(va, v, 0.0)
              bv = Map.get(vb, v, 0.0)
              (av - bv) ** 2
            end)
          end)

        case squared_errors do
          [] -> 0.5
          se -> :math.sqrt(Enum.sum(se) / length(se)) |> clamp()
        end
    end
  end

  @spec rank_by_confidence([Forecast.t()]) :: [String.t()]
  def rank_by_confidence(forecasts) do
    forecasts
    |> Enum.map(fn %Forecast{forecast_id: id, governing_equations: eqs} ->
      {id, length(eqs)}
    end)
    |> Enum.sort_by(fn {_, count} -> -count end)
    |> Enum.map(fn {id, _} -> id end)
  end

  defp compute_overall_divergence(forecasts) do
    pairs = for a <- forecasts, b <- forecasts, a != b, do: {a, b}
    divergences = Enum.map(pairs, fn {a, b} -> compute_divergence(a, b) end)

    case divergences do
      [] -> 0.0
      ds -> Enum.sum(ds) / length(ds)
    end
  end

  defp align_steps(steps_a, steps_b) do
    step_map_a = Map.new(steps_a, fn %ForecastStep{step: s} = fs -> {s, fs} end)
    step_map_b = Map.new(steps_b, fn %ForecastStep{step: s} = fs -> {s, fs} end)

    common_steps = MapSet.intersection(
      MapSet.new(Map.keys(step_map_a)),
      MapSet.new(Map.keys(step_map_b))
    )

    common_steps
    |> Enum.map(fn s -> {Map.get(step_map_a, s), Map.get(step_map_b, s)} end)
    |> Enum.sort_by(fn {%ForecastStep{step: s}, _} -> s end)
  end

  defp build_consensus(forecasts) do
    all_steps =
      forecasts
      |> Enum.flat_map(fn %Forecast{time_steps: steps} -> steps end)

    step_groups = Enum.group_by(all_steps, fn %ForecastStep{step: s} -> s end)

    Map.new(step_groups, fn {step, steps} ->
      values_maps = Enum.map(steps, fn %ForecastStep{values: v} -> v end)
      all_keys =
        values_maps
        |> Enum.flat_map(&Map.keys/1)
        |> Enum.uniq()

      avg_values =
        Map.new(all_keys, fn key ->
          vals = Enum.map(values_maps, fn m -> Map.get(m, key, 0.0) end)
          {key, Enum.sum(vals) / max(length(vals), 1)}
        end)

      {step, avg_values}
    end)
  end

  defp build_explanation(divergence, ranking) do
    "divergence=#{Float.round(divergence, 4)}, ranking=#{Enum.join(ranking, " > ")}"
  end

  defp clamp(v) when v < 0.0, do: 0.0
  defp clamp(v) when v > 1.0, do: 1.0
  defp clamp(v), do: v
end
