defmodule Tiannara.Forecasting.FeatureValue do
  @moduledoc """
  Leakage-safe evaluation of whether a feature adds predictive information.
  This is a predictive comparison, never a causal conclusion.
  """

  def compare(controls, augmented, opts \\ []) when is_list(controls) and is_list(augmented) do
    min_pairs = Keyword.get(opts, :min_pairs, 5)
    pairs = Enum.zip(controls, augmented)

    cond do
      length(controls) != length(augmented) -> {:error, :length_mismatch}
      length(pairs) < min_pairs -> {:error, :insufficient_comparable_sample}
      not Enum.all?(pairs, &valid_pair?/1) -> {:error, :invalid_forecast_pair}
      true ->
        control_mae = mae(controls)
        augmented_mae = mae(augmented)
        {:ok, %{pairs: length(pairs), control_mae: control_mae,
          augmented_mae: augmented_mae, delta_mae: augmented_mae - control_mae,
          identical_origins_required: true, interpretation: :predictive_comparison_only,
          causal_claim: :not_established, certification_eligible: false}}
    end
  end

  defp valid_pair?({control, augmented}),
    do: valid_result?(control) and valid_result?(augmented)

  defp valid_result?(result) when is_map(result) do
    is_number(Map.get(result, :prediction)) and is_number(actual_value(result)) and Map.has_key?(result, :origin)
  end
  defp valid_result?(_), do: false

  defp actual_value(result) do
    case Map.get(result, :actual) do
      [value | _] -> value
      value -> value
    end
  end

  defp mae(results) do
    Enum.sum(Enum.map(results, fn result -> abs(Map.get(result, :prediction) - actual_value(result)) end)) / length(results)
  end
end
