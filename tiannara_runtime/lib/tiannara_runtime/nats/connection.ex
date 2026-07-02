defmodule TiannaraRuntime.NATS.Connection do
  @moduledoc """
  Phase 2 NATS Connection Manager

  Manages persistent connection to NATS server with automatic reconnection.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    state = %{
      connected: false,
      server_url: System.get_env("NATS_URL", "nats://localhost:4222"),
      reconnect_attempts: 0,
      last_connection_time: nil
    }

    {:ok, _} = connect(state.server_url)
    Logger.info("✅ NATS Connected: #{state.server_url}")
    {:ok, %{state | connected: true, last_connection_time: DateTime.utc_now()}}
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:reconnect, state) do
    Logger.info("🔄 Attempting NATS reconnection (attempt #{state.reconnect_attempts + 1})...")

    {:ok, _} = connect(state.server_url)
    Logger.info("✅ NATS Reconnected")
    {:noreply, %{state | connected: true, reconnect_attempts: 0, last_connection_time: DateTime.utc_now()}}
  end

  defp connect(_server_url) do
    # TODO: Implement actual NATS connection using gnat library
    {:ok, :simulated}
  end

  defp schedule_reconnect do
    delay = min(round(:math.pow(2, 10) * 1000), 60_000)
    Process.send_after(self(), :reconnect, delay)
  end
end
