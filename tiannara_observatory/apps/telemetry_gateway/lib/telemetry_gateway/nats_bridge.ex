defmodule TelemetryGateway.NATSBridge do
  @moduledoc """
  Bridges NATS messages from tiannara_runtime into the telemetry gateway pipeline.

  Connects to the shared NATS server, subscribes to configured subjects,
  and feeds received events into `TelemetryGateway.Receiver.ingest/1`.
  """
  use GenServer

  alias TelemetryGateway.Receiver

  @nats_host Application.compile_env(:telemetry_gateway, :nats_host, "localhost")
  @nats_port Application.compile_env(:telemetry_gateway, :nats_port, 4222)
  @subscribe_subjects Application.compile_env(
    :telemetry_gateway,
    :nats_subscribe_subjects,
    ["tiannara.>"]
  )

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    connection_string = "nats://#{@nats_host}:#{@nats_port}"

    case Gnat.start_link(%{host: @nats_host, port: @nats_port}, name: :telemetry_gateway_nats) do
      {:ok, conn} ->
        subscribe_all(conn)
        {:ok, %{conn: conn, connected: true}}

      {:error, reason} ->
        {:stop, "Failed to connect to NATS at #{connection_string}: #{inspect(reason)}"}
    end
  end

  defp subscribe_all(conn) do
    Enum.each(@subscribe_subjects, fn subject ->
      Gnat.sub(conn, self(), subject)
    end)
  end

  @impl true
  def handle_info({:msg, %{body: body, topic: _topic, subject: subject}}, state) do
    handle_nats_message(body, subject, state)
  end

  def handle_info({:msg, %{body: body, subject: subject}}, state) do
    handle_nats_message(body, subject, state)
  end

  defp handle_nats_message(body, subject, state) do
    body
    |> Jason.decode!()
    |> Map.put("_nats_subject", subject)
    |> Receiver.ingest()

    {:noreply, state}
  end
end
