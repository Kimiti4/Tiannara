defmodule ObservatoryApi.Channels.ScienceChannel do
  use Phoenix.Channel

  def join("obs:science", _payload, socket) do
    {:ok, socket}
  end
end
