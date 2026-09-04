defmodule Tiannara.Forecasting.RegressionToMean do
  @moduledoc """
  D4 regression-to-the-mean analysis.

  Measures extremity of the first observation against a reference class and
  reports whether reversion of later observations toward the class mean is
  plausible. By construction this module emits NO causal-claim field — a
  regression analysis is structurally incapable of attributing reversion to a
  cause.

  Constitutional rules:
    - without a reference class, `rtm_plausibility` is `:unknown` (first-class,
      not 0.0/`false`).
    - a single observation cannot be regressed against itself; `:unknown`.
    - the report map has no `:causal_claim` / `:causation` key.
  """

  alias Tiannara.Forecasting.Contracts.RegressionToMeanReport

  @type t :: RegressionToMeanReport.t()

  @doc """
  Analyzes a chronological series of numeric observations.

  `reference_class` may be `%{mean: number(), std: number()}` or `nil`. When
  the reference class is unknown, extremity is `:unknown` and so is
  plausibility.
  """
  @spec analyze([number()] | map(), map() | nil) :: RegressionToMeanReport.t()
  def analyze(observations, reference_class) do
    obs = unwrap(observations)

    initial = List.first(obs)
    later_mean = later_mean(obs)
    z = extremity(initial, later_mean, reference_class)

    %RegressionToMeanReport{
      report_id: "rtm_" <> Tiannara.Executive.Types.new_id(),
      observations: obs,
      initial_value: initial,
      later_mean: later_mean,
      reference_class: reference_class,
      extremity_index: z,
      rtm_plausibility: plausibility(z, length(obs), reference_class),
      created_at: DateTime.utc_now()
    }
  end

  @doc """
  Returns true only for reports whose schema retains no causal claim key.
  """
  @spec causal_claim_free?(map() | RegressionToMeanReport.t()) :: boolean()
  def causal_claim_free?(report)
      when is_map(report) do
    not Map.has_key?(normalize(report), :causal_claim) and
      not Map.has_key?(normalize(report), :causation)
  end

  @doc false
  def extremity_index(obs, reference_class) do
    obs = unwrap(obs)
    extremity(List.first(obs), later_mean(obs), reference_class)
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp unwrap(obs) when is_list(obs), do: Enum.reject(obs, &(not is_number(&1)))
  defp unwrap(obs) when is_map(obs) and map_size(obs) > 0,
    do: obs |> Enum.sort_by(&elem(&1, 0)) |> Enum.map(&elem(&1, 1)) |> Enum.reject(&(not is_number(&1)))

  defp unwrap(_), do: []

  defp later_mean(obs) when length(obs) > 1 do
    Enum.sum(tl(obs)) / length(tl(obs))
  end

  defp later_mean(_), do: nil

  defp extremity(initial, _later, _ref) when not is_number(initial), do: :unknown

  defp extremity(_initial, _later, nil), do: :unknown

  defp extremity(_initial, _later, %{std: s}) when is_number(s) and s == 0,
    do: :unknown

  defp extremity(initial, _later, %{std: s, mean: m})
       when is_number(initial) and is_number(s) and is_number(m) and s > 0 do
    (initial - m) / s
  end

  defp extremity(_initial, _later, _ref), do: :unknown

  defp plausibility(_z, n, _ref) when n < 2, do: :unknown

  defp plausibility(:unknown, _n, _ref), do: :unknown

  defp plausibility(_z, _n, nil), do: :unknown

  defp plausibility(_z, _n, %{std: s}) when is_number(s) and s == 0, do: :unknown

  defp plausibility(z, _n, _ref) when is_number(z) do
    cond do
      abs(z) >= 2 -> :likely
      abs(z) >= 1 -> :possible
      true -> :unlikely
    end
  end

  defp plausibility(_z, _n, _ref), do: :unknown

  defp normalize(report) when is_map(report) and not is_struct(report), do: report

  defp normalize(report) do
    Map.from_struct(report)
  end
end