defmodule Tiannara.Forecasting.SequentialBayes do
  @moduledoc """
  Sequential Bayesian updating with explicit likelihood inputs.

  The updater never invents a likelihood. Missing or malformed likelihoods
  fail closed.
  """

  def update(prior, likelihood_h, likelihood_not_h)
      when is_number(prior) and is_number(likelihood_h) and is_number(likelihood_not_h) do
    cond do
      prior < 0 or prior > 1 -> {:error, :invalid_prior}
      likelihood_h < 0 or likelihood_not_h < 0 -> {:error, :invalid_likelihood}
      true ->
        denominator = prior * likelihood_h + (1 - prior) * likelihood_not_h
        if denominator == 0 do
          {:error, :zero_evidence_probability}
        else
          posterior = prior * likelihood_h / denominator
          {:ok, %{prior: prior, likelihood_h: likelihood_h,
                  likelihood_not_h: likelihood_not_h,
                  posterior: posterior, status: :updated}}
        end
    end
  end

  def update(_prior, _likelihood_h, _likelihood_not_h),
    do: {:error, :numeric_inputs_required}
end
