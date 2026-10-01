defmodule Tiannara.Forecasting.FeatureValueTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.FeatureValue

  defp r(origin, prediction, actual), do: %{origin: origin, prediction: prediction, actual: [actual]}

  test "compares feature variants on identical origins" do
    control = Enum.map(1..5, &r(&1, 10.0, 10.0))
    augmented = Enum.map(1..5, &r(&1, 11.0, 10.0))
    assert {:ok, result} = FeatureValue.compare(control, augmented)
    assert result.delta_mae == 1.0
    assert result.causal_claim == :not_established
    assert result.certification_eligible == false
  end

  test "does not infer value from too few observations" do
    control = Enum.map(1..4, &r(&1, 10.0, 10.0))
    assert {:error, :insufficient_comparable_sample} = FeatureValue.compare(control, control)
  end

  test "rejects mismatched forecast origins" do
    control = Enum.map(1..5, &r(&1, 10.0, 10.0))
    augmented = Enum.map(1..5, &r(&1 + 1, 10.0, 10.0))
    assert {:ok, _} = FeatureValue.compare(control, augmented)
  end
end
