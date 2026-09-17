defmodule ObservatoryApi.Channels.EngineeringChannel do
  use Phoenix.Channel
  def join("obs:engineering", _payload, socket), do: {:ok, socket}
end
