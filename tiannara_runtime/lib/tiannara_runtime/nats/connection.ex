defmodule TiannaraRuntime.NATS.Connection do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @impl true
  def init(_opts) do
    port = String.to_integer(System.get_env("NATS_PORT", "4222"))
    state = %{
      listen_socket: nil,
      port: port,
      clients: %{},
      connected: false
    }
    case :gen_tcp.listen(port, [:binary, packet: :line, reuseaddr: true, active: false]) do
      {:ok, listen_socket} ->
        Logger.info("NATS TCP listener started on port #{port}")
        send(self(), :accept)
        {:ok, %{state | listen_socket: listen_socket, connected: true}}
      {:error, reason} ->
        Logger.warning("NATS TCP listener failed on port #{port}: #{inspect(reason)}")
        {:ok, state}
    end
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:accept, %{listen_socket: listen_socket} = state) when listen_socket != nil do
    case :gen_tcp.accept(listen_socket) do
      {:ok, client_socket} ->
        pid = spawn_link(fn -> handle_client(client_socket) end)
        :gen_tcp.controlling_process(client_socket, pid)
        send(self(), :accept)
        {:noreply, %{state | clients: Map.put(state.clients, pid, client_socket)}}
      {:error, _reason} ->
        send(self(), :accept)
        {:noreply, state}
    end
  end

  defp handle_client(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, line} ->
        line = String.trim(line)
        case Jason.decode(line) do
          {:ok, %{"subject" => subject, "payload" => payload}} ->
            TiannaraRuntime.NATS.Bus.publish(subject, payload)
          {:ok, %{"subject" => subject}} ->
            TiannaraRuntime.NATS.Bus.publish(subject, %{})
          _ ->
            :gen_tcp.send(socket, ~s/{"status":"error","reason":"invalid_format"}\n/)
        end
        handle_client(socket)
      {:error, _reason} ->
        :ok
    end
  end
end
