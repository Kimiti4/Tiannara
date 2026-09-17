defmodule ObservatoryApi.Channels.ReplayChannel do
  use Phoenix.Channel
  def join("obs:replay", _payload, socket), do: {:ok, socket}
end
