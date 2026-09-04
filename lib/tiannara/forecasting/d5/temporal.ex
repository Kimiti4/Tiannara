defmodule Tiannara.Forecasting.D5.Temporal do
  @moduledoc """
  D5 Temporal — "what was available at the relevant time?" (contract §9).

  TemporalLabel is COMPUTED from timestamps, never self-declared:
    DECISION_TIME          — every referenced input has timestamp ≤ the target's
                             decision_time (verified against the D3 snapshot /
                             evidence store)
    POST_OUTCOME_ANALYSIS  — any referenced input postdates decision_time

  §9.2: POST_OUTCOME_ANALYSIS is legitimate analysis, permanently labeled. It
  can never write into decision-quality, forecast-quality-at-decision-time, or
  calibration fields.

  This extends the D4→D3 temporal firewall pattern to D5 (§9.3): D5 holds
  read-only handles; mutation attempts are rejected and emitted as adversarial
  audit events.
  """

  @labels [:decision_time, :post_outcome_analysis]

  @spec labels() :: [:decision_time | :post_outcome_analysis]
  def labels, do: @labels

  @doc """
  Compute the TemporalLabel for an analysis given the decision time and the
  max timestamp of all referenced inputs.

  - :decision_time         — decision_ts >= every input_ts
  - :post_outcome_analysis — some input_ts > decision_ts
  Returns `{:error, :missing_decision_time}` if decision time is absent.
  """
  @spec compute(DateTime.t() | nil, [DateTime.t()]) :: {:ok, atom()} | {:error, atom()}
  def compute(decision_ts, input_timestamps) when is_list(input_timestamps) do
    if decision_ts == nil do
      {:error, :missing_decision_time}
    else
      latest_input =
        input_timestamps
        |> Enum.reject(&is_nil/1)
        |> Enum.map(&DateTime.to_unix/1)
        |> List.flatten()
        |> case do
          [] -> 0
          list -> Enum.max(list)
        end

      if latest_input > DateTime.to_unix(decision_ts) do
        {:ok, :post_outcome_analysis}
      else
        {:ok, :decision_time}
      end
    end
  end

  @doc """
  Guard a write into decision-time fields. §9.2: POST_OUTCOME_ANALYSIS analysis
  can never write into decision-quality, forecast-quality-at-decision-time, or
  calibration fields. D5 holds read-only handles; mutation attempts are
  REJECTED and surfaced as adversarial audit events (never silently applied).
  """
  @spec guarantee_write_guard(:decision_time | :post_outcome_analysis, atom()) ::
          {:ok, :write_permitted} | {:error, :post_outcome_write_into_decision_field}
  def guarantee_write_guard(:decision_time, _field), do: {:ok, :write_permitted}

  def guarantee_write_guard(:post_outcome_analysis, field) do
    if decision_time_field?(field) do
      {:error, :post_outcome_write_into_decision_field}
    else
      {:ok, :write_permitted}
    end
  end

  @doc "Adversarial audit event for a rejected temporal write (§9.3)."
  @spec adversarial_audit_event(term(), atom(), map()) :: map()
  def adversarial_audit_event(label, field, detail) do
    %{
      event_type: "d5.temporal_firewall.adversarial_write_blocked",
      label: label,
      field: field,
      detail: detail,
      timestamp: DateTime.utc_now()
    }
  end

  # Fields that encode what was known at decision time.
  defp decision_time_field?(:decision_quality), do: true
  defp decision_time_field?(:forecast_quality_at_decision_time), do: true
  defp decision_time_field?(:calibration), do: true
  defp decision_time_field?(field), do: field in [:probability, :confidence, :recommendation]
end