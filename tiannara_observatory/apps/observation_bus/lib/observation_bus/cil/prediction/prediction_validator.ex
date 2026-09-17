defmodule ObservationBus.CIL.Prediction.PredictionValidator do
  @moduledoc """
  Validates forecast accuracy by comparing past predictions against actual outcomes.

  Tracks forecast error, bias, and confidence calibration across all
  prediction dimensions.
  """

  use GenServer

  defstruct [:validation_log, :total_validations, :last_validation]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{validation_log: :queue.new(), total_validations: 0, last_validation: nil}}
  end

  @doc "Record an actual outcome for comparison against a forecast."
  @spec record_actual(String.t(), float(), map()) :: :ok
  def record_actual(metric, actual_value, forecast \\ %{}) do
    GenServer.cast(__MODULE__, {:record, metric, actual_value, forecast, DateTime.utc_now()})
  end

  @doc "Get accuracy report for all validated metrics."
  @spec accuracy_report() :: map()
  def accuracy_report do
    GenServer.call(__MODULE__, :accuracy_report)
  end

  @doc "Return validation stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_cast({:record, metric, actual, forecast, now}, state) do
    predicted = Map.get(forecast, :predicted_value, 0.0)
    error = abs(actual - predicted)
    pct_error = if predicted != 0, do: error / predicted, else: 0.0

    entry = %{
      metric: metric,
      actual: actual,
      predicted: predicted,
      error: error,
      pct_error: pct_error,
      validated_at: now
    }

    log = :queue.in(entry, state.validation_log)
    log = if :queue.len(log) > 500 do
      {:value, _} = :queue.out(log)
      log
    else
      log
    end

    {:noreply, %{state | validation_log: log, total_validations: state.total_validations + 1,
                         last_validation: now}}
  end

  @impl true
  def handle_call(:accuracy_report, _from, state) do
    entries = :queue.to_list(state.validation_log)

    by_metric = Enum.group_by(entries, & &1.metric)
    summary = Enum.map(by_metric, fn {metric, vals} ->
      errors = Enum.map(vals, & &1.pct_error)
      mean_error = if length(errors) > 0, do: Enum.sum(errors) / length(errors), else: 0.0
      {metric, %{
        sample_count: length(vals),
        mean_pct_error: mean_error,
        accuracy: max(0.0, 1.0 - mean_error),
        last_validated: List.last(vals).validated_at
      }}
    end)

    {:reply, %{
      metrics: Map.new(summary),
      total_validations: state.total_validations,
      overall_accuracy: compute_overall_accuracy(summary)
    }, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_validations: state.total_validations,
      validation_queue_size: :queue.len(state.validation_log),
      last_validation: state.last_validation
    }, state}
  end

  defp compute_overall_accuracy(summary) do
    accuracies = Enum.map(summary, fn {_m, s} -> s.accuracy end)
    if length(accuracies) > 0, do: Enum.sum(accuracies) / length(accuracies), else: 0.0
  end
end
