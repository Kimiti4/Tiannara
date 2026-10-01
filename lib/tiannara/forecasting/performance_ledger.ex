defmodule Tiannara.Forecasting.PerformanceLedger do
  @moduledoc """
  Append-only performance history for resolved forecasts.

  It records measured outcomes without selecting a winning model or changing
  model parameters. Aggregation is evidence for later ACL/OAVL/CEL review.
  """
  use Agent

  @spec start_link(keyword()) :: Agent.on_start()
  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec append(map()) :: :ok | {:error, term()}
  def append(record) when is_map(record) do
    with :ok <- validate(record) do
      Agent.update(__MODULE__, fn state ->
        Map.update(state, key(record), [record], fn existing -> existing ++ [record] end)
      end)
    end
  rescue
    _ -> {:error, :performance_ledger_unavailable}
  end

  @spec history(String.t(), String.t() | nil) :: [map()]
  def history(model_ref, forecast_version \\ nil) when is_binary(model_ref) do
    Agent.get(__MODULE__, &Map.get(&1, {model_ref, forecast_version}, []))
  rescue
    _ -> []
  end

  @spec summarize([map()]) :: map()
  def summarize(records) when is_list(records) do
    scores = Enum.map(records, &Map.get(&1, :scores, %{}))
    briers = numeric(scores, :brier)
    log_losses = numeric(scores, :log_loss)
    directional = numeric(scores, :directional_accuracy)

    %{
      sample_size: length(records),
      brier_mean: mean(briers),
      log_loss_mean: mean(log_losses),
      directional_accuracy_mean: mean(directional),
      status: if(length(records) >= 5, do: :measured, else: :insufficient_sample),
      interpretation: :performance_history_only,
      model_selection: :not_assigned,
      certification_eligible: false
    }
  end

  def summarize(_), do: %{sample_size: 0, status: :insufficient_sample, certification_eligible: false}

  defp validate(record) do
    cond do
      Map.get(record, :status) != :resolved_not_certified -> {:error, :record_not_resolved}
      Map.get(record, :evidence_status) == :evidence_unresolved -> {:error, :evidence_unresolved}
      not is_binary(Map.get(record, :forecast_id)) -> {:error, :forecast_id_missing}
      true -> :ok
    end
  end

  defp key(record), do: {Map.get(record, :model_ref, :unknown), Map.get(record, :forecast_version)}
  defp numeric(records, key), do: records |> Enum.map(&Map.get(&1, key, :unknown)) |> Enum.filter(&is_number/1)
  defp mean([]), do: :unknown
  defp mean(values), do: Enum.sum(values) / length(values)
end
