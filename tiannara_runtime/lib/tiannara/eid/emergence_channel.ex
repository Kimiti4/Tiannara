defmodule Tiannara.UI.EmergenceChannel do
  @moduledoc """
  Tiannara.UI.EmergenceChannel: Phoenix Channel to stream dynamic emergence frameworks and live heat field hotspots.
  """
  use Phoenix.Channel

  def join("emergence:live", _msg, socket) do
    {:ok, socket}
  end

  def handle_info({:emergence_tick, data}, socket) do
    push(socket, "emergence_frame", %{
      global_slef: data.global,
      worlds: data.worlds,
      hotspots: data.hotspots
    })

    {:noreply, socket}
  end
end
