defmodule Tiannara.Forecasting.ModelComparison do
  @moduledoc """
  Evidence-only comparison of forecasting models.

  A model is not accepted because it is more sophisticated. It must be
  compared on identical rolling-origin observations against a baseline.
  """

  def compare(model_results, baseline_results) when is_list(model_results) and is_list(baseline_results) do
    pairs = Enum.zip(model_results, baseline_results)

    if pairs == [] do
      {:error, :no_comparable_results}
    else
      model_errors = errors(model_results)
      baseline_errors = errors(baseline_results)

      {:ok, %{
        pairs: length(pairs),
        model_mae: mean(model_errors),
        baseline_mae: mean(baseline_errors),
        delta_mae: mean(model_errors) - mean(baseline_errors),
        status: :comparison_only,
        acceptance: :requires_independent_review
      }}
    end
  end

  defp errors(results) do
    results
    |> Enum.map(fn result ->
      case {Map.get(result, :prediction), Map.get(result, :actual)} do
        {p, [a | _]} when is_number(p) and is_number(a) -> abs(p - a)
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp mean([]), do: :unknown
  defp mean(values), do: Enum.sum(values) / length(values)
end
