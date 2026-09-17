defmodule ObservatoryApi.Channels.AlertsChannel do
  use Phoenix.Channel
  def join("obs:alerts", _payload, socket), do: {:ok, socket}
end
