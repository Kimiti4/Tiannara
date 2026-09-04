defmodule Tiannara.Omega.TelemetryWindow do
  @moduledoc """
  Rolling observation buffer. Collects live telemetry via the adapter and
  maintains a bounded window the Sentinel heartbeat reads from.

  Separates observation COLLECTION from anomaly ANALYSIS (the Heartbeat's job),
  honoring the Architecture Philosophy's "clear responsibilities."

  Constitutional basis: Observability, Bottleneck Discovery, "Detect degraded
  performance."
  """
  use GenServer

  alias Tiannara.Telemetry.Observation

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @doc "Push a new observation into the window."
  def observe(server, %Observation{} = obs), do: GenServer.cast(server, {:observe, obs})

  @doc "Return the current observation window (oldest → newest)."
  def window(server), do: GenServer.call(server, :window)

  @doc "Return the number of observations currently held."
  def size(server), do: GenServer.call(server, :size)

  @impl true
  def init(opts) do
    {
      :ok,
      %{
        adapter: Keyword.get(opts, :adapter, Tiannara.Telemetry.RuntimeAdapter),
        window_size: Keyword.get(opts, :window_size, 5),
        observations: []
      }
    }
  end

  @impl true
  def handle_cast({:observe, obs}, state) do
    observations = [obs | state.observations] |> Enum.take(state.window_size) |> Enum.reverse()
    {:noreply, %{state | observations: observations}}
  end

  @impl true
  def handle_call(:window, _from, state), do: {:reply, state.observations, state}
  def handle_call(:size, _from, state), do: {:reply, length(state.observations), state}

  @impl true
  def handle_info(:collect, state) do
    obs = state.adapter.collect([])
    observations = [obs | state.observations] |> Enum.take(state.window_size) |> Enum.reverse()
    {:noreply, %{state | observations: observations}}
  end
end