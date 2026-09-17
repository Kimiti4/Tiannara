defmodule Tiannara.Runtime.OLEF.Field do
  @moduledoc """
  Ontological Load Equilibrium Field (OLEF) - Tracks pressure and calculates equilibrium drift.
  """

  use GenServer

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def reset() do
    GenServer.call(__MODULE__, :reset)
  end

  def update_pressure(manifold_id, pressure) do
    GenServer.call(__MODULE__, {:update_pressure, manifold_id, pressure})
  end

  def get_equilibrium_drift() do
    GenServer.call(__MODULE__, :get_equilibrium_drift)
  end

  def snapshot() do
    GenServer.call(__MODULE__, :snapshot)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    {:ok, %{pressures: %{}, routes: []}}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{pressures: %{}, routes: []}}
  end

  @impl true
  def handle_call({:update_pressure, manifold_id, pressure}, _from, state) do
    new_pressures = Map.put(state.pressures, manifold_id, pressure)

    # Calculate routes if any pressure exceeds 1000.0
    new_routes =
      if Enum.any?(new_pressures, fn {_id, p} -> p > 1000.0 end) do
        # Target all other nodes with lower pressure
        new_pressures
        |> Enum.filter(fn {_id, p} -> p <= 1000.0 end)
        |> Enum.map(fn {id, _p} -> %{target: id} end)
      else
        []
      end

    {:reply, :ok, %{state | pressures: new_pressures, routes: new_routes}}
  end

  @impl true
  def handle_call(:get_equilibrium_drift, _from, state) do
    avg =
      if map_size(state.pressures) == 0 do
        0.0
      else
        Enum.sum(Map.values(state.pressures)) / map_size(state.pressures)
      end

    {:reply, {:ok, avg}, state}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, %{diffusion_routes: state.routes}, state}
  end

  # Child spec
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
