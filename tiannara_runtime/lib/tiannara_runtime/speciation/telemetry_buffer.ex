defmodule Tiannara.Speciation.TelemetryBuffer do
  @moduledoc """
  Collects multi-dimensional world physics signatures and flushes them
  to the Python UMAP pipeline for speciation analysis.
  
  This GenServer batches incoming NATS world physics updates into
  compressed float arrays, streaming them to the Python embedding engine
  at regular generation intervals.
  
  ## Architecture
  - Ingests world state updates from NATS topic: `tiannara.world.*.state`
  - Batches feature vectors for efficient transmission
  - Flushes to Python UMAP pipeline every 2 seconds
  - Publishes raw data to: `tiannara.analytics.speciation.raw`
  
  ## Feature Vector Components
  [fitness, entropy, cal_force_magnitude, cis_pressure_dampening, mutation_rate]
  """

  use GenServer
  require Logger

  @flush_interval_ms 2000
  @nats_client :tiannara_nats
  @min_worlds_for_flush 5

  defstruct [
    :nats_connection,
    buffer: %{},
    generation: 0
  ]

  @type t :: %__MODULE__{
    nats_connection: pid() | nil,
    buffer: %{String.t() => [float()]},
    generation: non_neg_integer()
  }

  # Public API

  @doc """
  Starts the TelemetryBuffer GenServer.
  
  ## Options
    - :nats_connection - NATS connection PID
    - :flush_interval - Flush interval in milliseconds (default: 2000)
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Manually trigger a flush of the current buffer.
  """
  def flush do
    GenServer.call(__MODULE__, :flush)
  end

  @doc """
  Get current buffer size.
  """
  def get_buffer_size do
    GenServer.call(__MODULE__, :buffer_size)
  end

  # GenServer Callbacks

  @impl true
  def init(opts) do
    nats_connection = Keyword.get(opts, :nats_connection)
    flush_interval = Keyword.get(opts, :flush_interval, @flush_interval_ms)

    # Subscribe to world state updates
    # Note: In production, use actual NATS subscription
    # :ok = Gnat.sub(nats_connection, self(), "tiannara.world.*.state")

    schedule_flush(flush_interval)

    {:ok,
     %__MODULE__{
       nats_connection: nats_connection,
       buffer: %{},
       generation: 0
     }}
  end

  @impl true
  def handle_call(:flush, _from, state) do
    {new_state, _} = execute_flush(state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:buffer_size, _from, state) do
    {:reply, {:ok, map_size(state.buffer)}, state}
  end

  @impl true
  def handle_info({:msg, %{topic: topic, body: body}}, state) do
    world_id = parse_world_id(topic)

    case Jason.decode(body) do
      {:ok, data} ->
        # Extract the multi-dimensional vector representing the world's physical footprint
        vector = [
          Map.get(data, "fitness", 0.0),
          Map.get(data, "entropy", 0.0),
          Map.get(data, "cal_force_magnitude", 0.0),
          Map.get(data, "cis_pressure_dampening", 0.0),
          Map.get(data, "mutation_rate", 0.0)
        ]

        new_buffer = Map.put(state.buffer, world_id, vector)
        {:noreply, %{state | buffer: new_buffer}}

      _ ->
        Logger.warning("Failed to decode world state message: #{body}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:flush, state) do
    flush_interval = Keyword.get([], :flush_interval, @flush_interval_ms)
    {new_state, _} = execute_flush(state)
    schedule_flush(flush_interval)
    {:noreply, new_state}
  end

  # Flush Logic

  defp execute_flush(state) do
    if map_size(state.buffer) >= @min_worlds_for_flush do
      Logger.debug(" Flushing telemetry buffer: #{map_size(state.buffer)} worlds (gen #{state.generation})")

      # Dispatch to Python via NATS
      send_to_python_pipeline(state.buffer, state.generation, state.nats_connection)

      new_state = %{
        state
        | buffer: %{},
          generation: state.generation + 1
      }

      {new_state, :flushed}
    else
      Logger.debug("Buffer too small for flush: #{map_size(state.buffer)} worlds (min: #{@min_worlds_for_flush})")
      {state, :skipped}
    end
  end

  defp send_to_python_pipeline(buffer, generation, nats_connection) do
    payload = Jason.encode!(%{generation: generation, data: buffer})

    case nats_connection do
      nil ->
        Logger.debug("Mock telemetry flush: #{map_size(buffer)} worlds")

      conn_pid ->
        try do
          :gnat.pub(conn_pid, "tiannara.analytics.speciation.raw", payload)
          Logger.debug(" Telemetry flushed to Python pipeline (gen #{generation})")
        rescue
          e -> Logger.error("Failed to publish telemetry: #{inspect(e)}")
        end
    end
  end

  # Helpers

  defp parse_world_id(topic) do
    # Expected format: tiannara.world.{world_id}.state
    topic
    |> String.split(".")
    |> Enum.at(2, "unknown")
  end

  defp schedule_flush(interval_ms) do
    Process.send_after(self(), :flush, interval_ms)
  end
end
