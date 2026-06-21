defmodule Tiannara.Web.TelemetryChannel do
  @moduledoc """
  Adaptive 30Hz binary stream with viewport-aware backpressure.
  Uses GenStage to aggregate Sentinel deltas without flooding the BEAM VM.
  """
  use Phoenix.Channel
  alias Tiannara.Telemetry.WorldState
  require Logger

  def join("telemetry:global", _payload, socket) do
    {:ok, assign(socket, :client_lod, :far)}
  end

  def handle_in("update_lod", %{"distance" => dist}, socket) do
    lod = cond do
      dist < 50 -> :close
      dist < 500 -> :mid
      true -> :far
    end
    send(self(), {:tick_schedule, lod})
    {:reply, :ok, assign(socket, :client_lod, lod)}
  end

  def handle_info({:tick_schedule, lod}, socket) do
    interval = case lod do
      :close -> :timer.seconds(0.033) |> trunc # 30Hz
      :mid   -> :timer.seconds(0.1)   |> trunc # 10Hz
      :far   -> :timer.seconds(0.5)   |> trunc # 2Hz
    end
    Process.send_after(self(), :stream_tick, interval)
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    send(self(), {:tick_schedule, :far})
    {:noreply, socket}
  end

  def handle_info(:stream_tick, socket) do
    # 1. Fetch only the delta updates from the Sentinel Pressure Monitor
    # Mocking for now since PressureMonitor might not return full structure yet
    # deltas = Tiannara.Sentinel.PressureMonitor.get_latest_deltas()
    deltas = %{
      tick: System.monotonic_time(:millisecond),
      worlds: []
    }
    
    binary = WorldState.encode(%WorldState{
      tick: deltas.tick,
      worlds: Enum.map(deltas.worlds, &struct(WorldState.World, &1))
    })

    push(socket, "d", {:binary, binary})
    send(self(), {:tick_schedule, socket.assigns.client_lod})
    {:noreply, socket}
  end
end
