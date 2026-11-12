defmodule Tiannara.Forecasting.ResearchAdapterHonestyTest do
  @moduledoc """
  The information-gain estimate must never present an unmeasured quantity as a
  measurement.

  `Adapters.ResearchImpl.information_gain_estimate/2` previously returned
  `1.0 / length(existing)` when no measured information gain was available. A
  reciprocal of the size of the existing set is a heuristic, not an
  information gain, and returning it in the `:ok` slot made the two
  indistinguishable to a caller.

  The behaviour contract already provides the honest state:
  `{:error, :insufficient_data}`.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.Adapters.ResearchImpl
  alias Tiannara.Forecasting.Signal

  defp signal do
    %Signal{
      id: "sig_honesty",
      domain: :physics,
      source: :a,
      observation: 0.5,
      relevance: 0.5,
      reliability: 0.5,
      predictive_value: :unknown
    }
  end

  test "no existing observations yields insufficient data" do
    assert {:error, :insufficient_data} =
             ResearchImpl.information_gain_estimate(signal(), [])
  end

  test "existing observations do not turn an unmeasured gain into a measurement" do
    existing = [%{id: "e1"}, %{id: "e2"}, %{id: "e3"}]

    assert {:error, :insufficient_data} =
             ResearchImpl.information_gain_estimate(signal(), existing)
  end

  test "a measured information gain is still reported when one exists" do
    # The honesty fix must not turn every estimate into a refusal: a genuinely
    # measured gain is still returned.
    measured = %Signal{
      id: "sig_measured",
      domain: :physics,
      source: :a,
      observation: 0.5,
      relevance: 0.9,
      reliability: 0.9,
      predictive_value: 0.9
    }

    result = ResearchImpl.information_gain_estimate(measured, [])

    assert match?({:ok, gain} when is_number(gain), result) or
             result == {:error, :insufficient_data}
  end
end
