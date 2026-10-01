defmodule Tiannara.Forecasting.SignalFilterTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.SignalFilter

  test "filter records rare observations instead of silently treating them as truth or noise" do
    data = [%{value: 1}, %{value: 1}, %{value: 9}]
    assert {:ok, report} = SignalFilter.filter(data)
    assert Enum.map(report.accepted, & &1.value) == [1, 1]
    assert Enum.any?(report.rejected, &(&1.reason == :insufficient_recurrence))
    assert report.status == :filtered_not_certified
  end

  test "rare signals can be preserved for adversarial analysis" do
    data = [%{value: 1}, %{value: 1}, %{value: 9}]
    assert {:ok, report} = SignalFilter.filter(data, rare_policy: :preserve)
    assert length(report.accepted) == 3
  end

  test "small samples do not trigger outlier deletion" do
    assert {:ok, report} = SignalFilter.reject_outliers([%{value: 1}, %{value: 100}])
    assert report.status == :insufficient_sample
    assert report.rejected == []
  end
end
