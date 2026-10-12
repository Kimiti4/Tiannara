defmodule Tiannara.Forecasting.TemporalEvaluation do
  @moduledoc """
  Leakage-safe temporal evaluation of forecast performance history.

  Records are split by forecast creation time, never by outcome arrival order.
  The earlier window is the model-selection/evaluation history; the later
  window is a locked holdout. This module measures performance only and never
  chooses a model or updates parameters.

  A holdout record may have been observed after the selection boundary, but its
  forecast itself must have been created after that boundary. This prevents
  hindsight from entering model selection.
  """

  alias Tiannara.Forecasting.PerformanceLedger

  @min_window 5

  @spec evaluate([map()], DateTime.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def evaluate(records, cutoff, opts \\ []) when is_list(records) do
    min_window = Keyword.get(opts, :min_window, @min_window)

    with :ok <- validate_cutoff(cutoff),
         {:ok, normalized} <- normalize(records),
         {:ok, {selection, holdout}} <- split(normalized, cutoff),
         :ok <- sufficient(selection, holdout, min_window) do
      {:ok, %{
        cutoff: cutoff,
        selection_window: PerformanceLedger.summarize(selection),
        holdout_window: PerformanceLedger.summarize(holdout),
        selection_ids: Enum.map(selection, & &1.forecast_id),
        holdout_ids: Enum.map(holdout, & &1.forecast_id),
        holdout_locked: true,
        holdout_used_for_selection: false,
        winner: :not_assigned,
        model_update: :requires_independent_review,
        certification_eligible: false
      }}
    end
  end

  def evaluate(_, _, _), do: {:error, :invalid_temporal_evaluation_input}

  defp validate_cutoff(%DateTime{}), do: :ok
  defp validate_cutoff(_), do: {:error, :cutoff_required}

  defp normalize(records) do
    if Enum.all?(records, &valid_record?/1) do
      {:ok, Enum.sort_by(records, &DateTime.to_unix(&1.forecast_created_at))}
    else
      {:error, :forecast_creation_time_required}
    end
  end

  defp valid_record?(record) do
    is_binary(Map.get(record, :forecast_id)) and
      match?(%DateTime{}, Map.get(record, :forecast_created_at)) and
      Map.get(record, :status) == :resolved_not_certified
  end

  defp split(records, cutoff) do
    Enum.split_with(records, fn record ->
      DateTime.compare(record.forecast_created_at, cutoff) == :lt
    end)
    |> then(fn {selection, holdout} -> {:ok, {selection, holdout}} end)
  end

  defp sufficient(selection, holdout, min_window) do
    cond do
      length(selection) < min_window -> {:error, :selection_window_insufficient}
      length(holdout) < min_window -> {:error, :holdout_window_insufficient}
      true -> :ok
    end
  end
end
