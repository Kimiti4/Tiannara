defmodule Tiannara.Forecasting.Lineage do
  @moduledoc """
  Connects signal provenance to forecast provenance.

  This is an audit/lineage constructor only. It does not upgrade epistemic
  status or certify a forecast.
  """

  alias Tiannara.Forecasting.{Provenance, Signal, ForecastProvenance}

  def build_forecast(attrs, signals) when is_map(attrs) and is_list(signals) do
    with :ok <- validate_signals(signals),
         {:ok, forecast} <- ForecastProvenance.build(attrs) do
      {:ok, Map.put(forecast, :signal_lineage, Enum.map(signals, &signal_entry/1))}
    end
  end

  def audit(forecast) when is_map(forecast) do
    with {:ok, _} <- ForecastProvenance.audit(forecast),
         :ok <- audit_signal_lineage(Map.get(forecast, :signal_lineage, [])) do
      {:ok, %{status: :lineage_auditable,
              forecast_id: forecast.forecast_id,
              signal_count: length(forecast.signal_lineage)}}
    end
  end

  defp validate_signals(signals) do
    if Enum.all?(signals, fn
         %Signal{} = signal -> match?({:ok, _}, Signal.validate(signal)) and Provenance.integrity?(signal)
         _ -> false
       end), do: :ok, else: {:error, :invalid_signal_lineage}
  end

  defp signal_entry(%Signal{} = signal) do
    %{id: signal.id, version: signal.version, source: signal.source,
      timestamp: signal.timestamp, provenance: Provenance.build(signal),
      lineage: signal.lineage, transformation_history: signal.transformation_history}
  end

  defp audit_signal_lineage(entries) when is_list(entries) do
    if Enum.all?(entries, fn entry ->
         is_map(entry) and is_binary(entry.id) and is_map(entry.provenance) and
           Provenance.valid?(entry.provenance)
       end), do: :ok, else: {:error, :invalid_signal_lineage}
  end
  defp audit_signal_lineage(_), do: {:error, :invalid_signal_lineage}
end
