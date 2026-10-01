defmodule Tiannara.Forecasting.SignalFilter do
  @moduledoc """
  Evidence-aware signal/noise filtering for forecasting.

  Filtering never upgrades evidence class or forecast confidence. It only
  produces a candidate dataset with an auditable disposition for each datum.
  """

  @type datum :: %{required(:value) => number(), optional(atom()) => term()}

  def filter(data, opts \\ []) when is_list(data) do
    min_support = Keyword.get(opts, :min_support, 2)
    rare_policy = Keyword.get(opts, :rare_policy, :flag)
    numeric_only = Keyword.get(opts, :numeric_only, true)

    if numeric_only and not Enum.all?(data, &valid_numeric_datum?/1) do
      {:error, :invalid_numeric_dataset}
    else
      {accepted, rejected} =
        data
        |> Enum.with_index()
        |> Enum.split_with(fn {datum, _index} ->
          supported?(datum, data, min_support) or rare_policy == :preserve
        end)

      {:ok, %{
        accepted: Enum.map(accepted, &elem(&1, 0)),
        rejected: Enum.map(rejected, &annotate_rejection(elem(&1, 0), data, min_support)),
        policy: %{min_support: min_support, numeric_only: numeric_only, rare_policy: rare_policy},
        status: :filtered_not_certified
      }}
    end
  end

  def reject_outliers(data, opts \\ []) when is_list(data) do
    threshold = Keyword.get(opts, :mad_threshold, 3.5)
    values = Enum.map(data, &value/1)

    if length(values) < 5 do
      {:ok, %{accepted: data, rejected: [], status: :insufficient_sample}}
    else
      med = median(values)
      deviations = Enum.map(values, &abs(&1 - med))
      mad = median(deviations)

      if mad == 0 do
        {:ok, %{accepted: data, rejected: [], status: :zero_mad_no_rejection}}
      else
        {accepted, rejected} =
          Enum.split_with(data, fn datum ->
            abs(0.6745 * (value(datum) - med) / mad) <= threshold
          end)

        {:ok, %{accepted: accepted, rejected: rejected,
                method: :modified_z_score, threshold: threshold}}
      end
    end
  end

  defp supported?(datum, data, min_support) do
    v = value(datum)
    Enum.count(data, fn other -> value(other) == v end) >= min_support
  end

  defp annotate_rejection(datum, data, min_support) do
    %{datum: datum, reason: :insufficient_recurrence,
      support_count: Enum.count(data, fn other -> value(other) == value(datum) end),
      required_support: min_support}
  end

  defp valid_numeric_datum?(datum) when is_map(datum), do: is_number(Map.get(datum, :value))
  defp valid_numeric_datum?(_), do: false
  defp value(datum), do: Map.fetch!(datum, :value)

  defp median([]), do: :nan
  defp median(values) do
    sorted = Enum.sort(values)
    n = length(sorted)
    if rem(n, 2) == 1, do: Enum.at(sorted, div(n, 2)),
      else: (Enum.at(sorted, div(n, 2) - 1) + Enum.at(sorted, div(n, 2))) / 2
  end
end
