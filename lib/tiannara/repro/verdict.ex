defmodule Tiannara.Repro.Verdict do
  @moduledoc """
  Compares two runs and issues a reproducibility verdict.

      Run A -> artifact bundle -+
                                +--> comparison -> reproducibility verdict
      Run B -> artifact bundle -+

  Verdicts:
      :reproduced    -- deterministic inputs match AND outcomes match
      :divergent     -- inputs match but outcomes differ (a real finding!)
      :inconclusive  -- inputs differ, so the comparison is not apples-to-apples

  A `:divergent` verdict is scientifically valuable: it locates hidden
  non-determinism. It must never be smoothed over.
  """

  alias Tiannara.Repro.Manifest

  defstruct [:verdict, :input_parity, :outcome_parity, :diffs, :config_hash_a, :config_hash_b]

  def compare(bundle_a, bundle_b, opts \\ []) do
    tolerance = Keyword.get(opts, :tolerance, 0.0)

    ha = Manifest.config_hash(bundle_a.manifest)
    hb = Manifest.config_hash(bundle_b.manifest)

    input_parity = ha == hb
    {outcome_parity, diffs} = compare_results(bundle_a.results, bundle_b.results, tolerance)

    verdict =
      cond do
        not input_parity -> :inconclusive
        outcome_parity -> :reproduced
        true -> :divergent
      end

    %__MODULE__{
      verdict: verdict,
      input_parity: input_parity,
      outcome_parity: outcome_parity,
      diffs: diffs,
      config_hash_a: ha,
      config_hash_b: hb
    }
  end

  defp compare_results(a, b, tolerance) when is_map(a) and is_map(b) do
    keys = Enum.uniq(Map.keys(a) ++ Map.keys(b))

    diffs =
      for k <- keys,
          not within?(Map.get(a, k), Map.get(b, k), tolerance),
          do: %{key: k, a: Map.get(a, k), b: Map.get(b, k)}

    {diffs == [], diffs}
  end

  defp compare_results(a, b, _tolerance) do
    if a == b, do: {true, []}, else: {false, [%{key: :result, a: a, b: b}]}
  end

  defp within?(x, y, tolerance) when is_number(x) and is_number(y), do: abs(x - y) <= tolerance
  defp within?(x, y, _tolerance), do: x == y
end
