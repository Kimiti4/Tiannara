defmodule Tiannara.Forecasting.ReferenceClass do
  @moduledoc """
  Reference-class forecasting support.

  Historical cohorts are explicit and conditional; a reference class is never
  treated as interchangeable with the current regime.
  """

  def build(records, selectors \\ %{}) when is_list(records) and is_map(selectors) do
    selected = Enum.filter(records, &matches?(&1, selectors))
    {:ok, %{records: selected, sample_size: length(selected), selectors: selectors,
            status: if(selected == [], do: :insufficient_reference_class, else: :available)}}
  end

  def frequency(records, outcome) when is_list(records) do
    n = length(records)
    if n == 0, do: :unknown,
      else: Enum.count(records, &(&1 == outcome)) / n
  end

  def adequacy(%{sample_size: n}) when n >= 5, do: :adequate
  def adequacy(_), do: :insufficient

  defp matches?(record, selectors) when is_map(record) do
    Enum.all?(selectors, fn {key, expected} ->
      Map.get(record, key) == expected
    end)
  end
  defp matches?(_, _), do: false
end
