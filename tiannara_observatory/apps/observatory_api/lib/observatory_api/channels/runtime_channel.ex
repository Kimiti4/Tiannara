defmodule ObservatoryApi.Channels.RuntimeChannel do
  use Phoenix.Channel

  def join("obs:runtime", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{timestamp: DateTime.utc_now()}}, socket}
  end
end
