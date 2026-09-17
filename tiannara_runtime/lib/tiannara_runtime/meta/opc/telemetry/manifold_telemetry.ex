defmodule Tiannara.Meta.OPC.Telemetry.ManifoldTelemetry do
  @moduledoc """
  Phase 5F.6 — Manifold Telemetry

  Emits structured telemetry events for observer manifold state changes
  produced by the OPC pipeline. Downstream consumers (dashboards, MSCL)
  subscribe via `:telemetry` handlers.

  ## Events emitted

  | Event                                  | Measurements          | Metadata              |
  |----------------------------------------|-----------------------|-----------------------|
  | `[:tiannara, :opc, :manifold, :drift]` | `%{value: float}`     | `%{observer_id: id}`  |
  | `[:tiannara, :opc, :manifold, :compile]`| `%{duration_ms: int}` | `%{observer_id: id}`  |
  | `[:tiannara, :opc, :manifold, :reject]`| `%{count: int}`       | `%{reason: atom}`     |

  ## Usage

      ManifoldTelemetry.emit_drift("obs_001", 0.42)
      ManifoldTelemetry.emit_compile("obs_001", 38)
      ManifoldTelemetry.emit_reject(:entropy_limit_exceeded)
  """

  require Logger

  @doc "Emits a manifold drift measurement for an observer."
  def emit_drift(observer_id, drift_value) when is_number(drift_value) do
    :telemetry.execute(
      [:tiannara, :opc, :manifold, :drift],
      %{value: drift_value},
      %{observer_id: observer_id}
    )

    Logger.debug("[ManifoldTelemetry] drift observer=#{observer_id} value=#{Float.round(drift_value * 1.0, 4)}")
  end

  @doc "Emits a compilation duration measurement for an observer."
  def emit_compile(observer_id, duration_ms) when is_integer(duration_ms) do
    :telemetry.execute(
      [:tiannara, :opc, :manifold, :compile],
      %{duration_ms: duration_ms},
      %{observer_id: observer_id}
    )

    Logger.debug("[ManifoldTelemetry] compile observer=#{observer_id} duration_ms=#{duration_ms}")
  end

  @doc "Emits a rejection event with the failure reason."
  def emit_reject(reason) when is_atom(reason) do
    :telemetry.execute(
      [:tiannara, :opc, :manifold, :reject],
      %{count: 1},
      %{reason: reason}
    )

    Logger.debug("[ManifoldTelemetry] reject reason=#{reason}")
  end
end
