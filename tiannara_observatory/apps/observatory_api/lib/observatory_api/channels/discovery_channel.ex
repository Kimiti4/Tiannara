defmodule ObservatoryApi.Channels.DiscoveryChannel do
  use Phoenix.Channel
  def join("obs:discovery", _payload, socket), do: {:ok, socket}
end
