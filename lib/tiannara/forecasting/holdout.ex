defmodule Tiannara.Forecasting.Holdout do
  @moduledoc """
  Final temporal holdout evaluation.

  The holdout is never used for feature discovery or model selection. It is a
  final out-of-sample check after the candidate has been selected elsewhere.
  """

  def evaluate(training_results, holdout_results, opts \\ []) do
    min_pairs = Keyword.get(opts, :min_pairs, 5)
    if length(holdout_results) < min_pairs do
      {:error, :insufficient_holdout_sample}
    else
      {:ok, %{training_pairs: length(training_results),
              holdout_pairs: length(holdout_results),
              training_selection_locked: true,
              holdout_used_for_selection: false,
              status: :holdout_evaluation_only,
              certification_eligible: false}}
    end
  end
end
