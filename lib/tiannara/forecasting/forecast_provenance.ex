defmodule Tiannara.Forecasting.ForecastProvenance do
  @moduledoc """
  Immutable-at-construction forecast lineage.

  A forecast is not evidence merely because it has provenance. The record makes
  the information boundary and validation state auditable.
  """

  @required [:forecast_id, :origin, :model_id, :model_version, :training_window,
             :feature_ids, :excluded_signal_ids, :validation, :uncertainty]

  def build(attrs) when is_map(attrs) do
    missing = Enum.filter(@required, &(not Map.has_key?(attrs, &1)))
    if missing != [] do
      {:error, {:missing_provenance, missing}}
    else
      {:ok, Map.merge(attrs, %{
        evidence_status: :derived_not_certified,
        created_at: Map.get(attrs, :created_at, DateTime.utc_now()),
        information_boundary: :forecast_origin_only
      })}
    end
  end

  def audit(record) when is_map(record) do
    missing = Enum.filter(@required, &(not Map.has_key?(record, &1)))
    cond do
      missing != [] -> {:error, {:missing_provenance, missing}}
      not is_map(record.validation) -> {:error, :invalid_validation_provenance}
      not is_map(record.uncertainty) -> {:error, :invalid_uncertainty_provenance}
      record.information_boundary != :forecast_origin_only ->
        {:error, :future_information_boundary_violation}
      true -> {:ok, %{status: :auditable, evidence_status: record.evidence_status}}
    end
  end
end
