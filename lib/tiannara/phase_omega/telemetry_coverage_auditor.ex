defmodule Tiannara.PhaseOmega.TelemetryCoverageAuditor do
  @moduledoc """
  Ω.9 — Telemetry Coverage Audit.

  Verifies telemetry handler coverage only. Handler presence is not treated as proof
  that a subsystem emitted an event or that delivery succeeded.
  """

  require Logger

  @required_events [
    [:observatory, :event, :ingested],
    [:observatory, :boot, :phase_start],
    [:observatory, :boot, :phase_complete],
    [:observatory, :error, :unhandled],
    [:tiannara, :subsystem, :registered],
    [:tiannara, :subsystem, :booted],
    [:tiannara, :subsystem, :failed],
    [:tiannara, :subsystem, :heartbeat],
    [:tiannara, :event, :emitted],
    [:tiannara, :event, :processed],
    [:tiannara, :metric, :recorded]
  ]

  def audit do
    Logger.info("[PhaseΩ:Telemetry] Auditing telemetry coverage...")

    registered = list_telemetry_handlers()
    covered = Enum.filter(@required_events, fn event ->
      Enum.any?(registered, fn handler ->
        event_matches?(handler.event_name, event)
      end)
    end)

    missing = @required_events -- covered

    %{
      total_required: length(@required_events),
      covered: length(covered),
      status: if(missing == [], do: :unknown, else: :fail),
      verification_scope: :handler_presence_only,
      missing_count: length(missing),
      missing_events: missing,
      handlers_found: length(registered),
      handler_list: registered,
      timestamp: DateTime.utc_now()
    }
  end

  defp list_telemetry_handlers do
    try do
      :telemetry.list_handlers([])
    rescue
      _ -> []
    catch
      _ -> []
    end
  end

  defp event_matches?([prefix|rest], [target|trest]) when prefix == target do
    if rest == [] || trest == [] do
      true
    else
      event_matches?(rest, trest)
    end
  end
  defp event_matches?([_prefix|_rest], [_target|_trest]), do: false
  defp event_matches?([], _target), do: true
  defp event_matches?(_prefix, []), do: false
end
