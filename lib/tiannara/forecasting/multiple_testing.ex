defmodule Tiannara.Forecasting.MultipleTesting do
  @moduledoc """
  Conservative multiple-hypothesis screening for candidate forecasting signals.

  The correction is a screening aid, not proof of a predictive or causal
  relationship. Candidates should still undergo temporal holdout validation.
  """

  def bonferroni(p_values, alpha \\ 0.05)
      when is_list(p_values) and is_number(alpha) and alpha > 0 and alpha < 1 do
    n = length(p_values)
    if n == 0 or not Enum.all?(p_values, &(is_number(&1) and &1 >= 0 and &1 <= 1)) do
      {:error, :invalid_p_values}
    else
      adjusted = Enum.map(p_values, &min(&1 * n, 1.0))
      threshold = alpha / n
      {:ok, %{raw_p_values: p_values, adjusted_p_values: adjusted,
              family_size: n, alpha: alpha, threshold: threshold,
              method: :bonferroni, status: :screening_only,
              certification_eligible: false}}
    end
  end

  def benjamini_hochberg(p_values, q \\ 0.05)
      when is_list(p_values) and is_number(q) and q > 0 and q < 1 do
    n = length(p_values)
    if n == 0 or not Enum.all?(p_values, &(is_number(&1) and &1 >= 0 and &1 <= 1)) do
      {:error, :invalid_p_values}
    else
      ranked = p_values |> Enum.with_index() |> Enum.sort_by(fn {p, _} -> p end)
      adjusted = ranked
        |> Enum.with_index(1)
        |> Enum.map(fn {{p, idx}, rank} -> {idx, min(p * n / rank, 1.0)} end)
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.map(&elem(&1, 1))
      {:ok, %{raw_p_values: p_values, adjusted_p_values: adjusted,
              family_size: n, q: q, method: :benjamini_hochberg,
              status: :screening_only, certification_eligible: false}}
    end
  end
end
