defmodule ObservatoryApi.Channels.MetricsChannel do
  use Phoenix.Channel

  def join("obs:metrics", _payload, socket) do
    {:ok, socket}
  end
end
