defmodule Tiannara.Simulation.MultiWorld.WorldComparisonAnalyzer do
  alias Tiannara.Simulation.MultiWorld.Domain.WorldComparison

  @spec compare(map(), String.t()) :: WorldComparison.t()
  def compare(world_outcomes, baseline_world_id) when is_map(world_outcomes) do
    world_ids = Map.keys(world_outcomes)
    baseline = Map.get(world_outcomes, baseline_world_id, %{})

    all_dimensions =
      world_outcomes
      |> Map.values()
      |> Enum.flat_map(&Map.keys/1)
      |> Enum.uniq()

    {divergences, convergences} =
      Enum.reduce(all_dimensions, {[], []}, fn dim, {divs, convs} ->
        values = Enum.map(world_outcomes, fn {_id, outcomes} -> Map.get(outcomes, dim, 0.0) end)
        variance = compute_variance(values)
        mean = Enum.sum(values) / max(1, length(values))

        if variance > 0.01 do
          div = %{
            dimension: dim,
            values: Map.new(world_outcomes, fn {id, outcomes} -> {id, Map.get(outcomes, dim, 0.0)} end),
            variance: variance,
            mean: mean,
            baseline_value: Map.get(baseline, dim, 0.0),
            max_divergence: Enum.max(values) - Enum.min(values)
          }
          {[div | divs], convs}
        else
          conv = %{dimension: dim, stable_value: mean, variance: variance}
          {divs, [conv | convs]}
        end
      end)

    composite =
      if all_dimensions == [] do
        0.0
      else
        length(divergences) / length(all_dimensions)
      end

    WorldComparison.new(%{
      world_ids: world_ids,
      baseline_world_id: baseline_world_id,
      dimensions: all_dimensions,
      divergences: Enum.reverse(divergences),
      convergences: Enum.reverse(convergences),
      causal_insights: generate_causal_insights(divergences, baseline_world_id),
      composite_divergence: composite
    })
  end

  @spec robust_outcomes(WorldComparison.t()) :: [map()]
  def robust_outcomes(%WorldComparison{convergences: convergences}) do
    Enum.filter(convergences, fn conv -> conv.variance < 0.001 end)
  end

  @spec fragile_outcomes(WorldComparison.t()) :: [map()]
  def fragile_outcomes(%WorldComparison{divergences: divergences}) do
    Enum.filter(divergences, fn div -> div.variance > 0.1 end)
  end

  defp compute_variance(values) do
    if length(values) < 2 do
      0.0
    else
      mean = Enum.sum(values) / length(values)
      Enum.reduce(values, 0.0, fn v, acc -> acc + :math.pow(v - mean, 2) end) / (length(values) - 1)
    end
  end

  defp generate_causal_insights(divergences, _baseline_world_id) do
    Enum.map(divergences, fn div ->
      %{
        dimension: div.dimension,
        insight: "Dimension '#{div.dimension}' diverges across worlds (variance: #{Float.round(div.variance, 4)}). " <>
                 "This suggests sensitivity to the injected changes.",
        baseline_value: div.baseline_value,
        max_divergence: div.max_divergence,
        confidence: min(1.0, div.variance * 5.0)
      }
    end)
  end
end
