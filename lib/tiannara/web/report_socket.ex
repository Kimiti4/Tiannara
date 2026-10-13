defmodule TiannaraWeb.ReportSocket do
  @moduledoc """
  WebSocket transport for `Tiannara.Web.ReportChannel`
  (mounted at /report — registered 2026-10-13 audit).
  """
  use Phoenix.Socket

  channel("report:*", Tiannara.Web.ReportChannel)

  @impl true
  def connect(_params, socket, _connect_info), do: {:ok, socket}

  @impl true
  def id(_socket), do: nil
end
