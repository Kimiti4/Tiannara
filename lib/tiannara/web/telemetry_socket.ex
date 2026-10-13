defmodule TiannaraWeb.TelemetrySocket do
  @moduledoc """
  WebSocket transport for `Tiannara.Web.TelemetryChannel`
  (mounted at /telemetry — registered 2026-10-13 audit).
  """
  use Phoenix.Socket

  channel("telemetry:*", Tiannara.Web.TelemetryChannel)

  @impl true
  def connect(_params, socket, _connect_info), do: {:ok, socket}

  @impl true
  def id(_socket), do: nil
end
