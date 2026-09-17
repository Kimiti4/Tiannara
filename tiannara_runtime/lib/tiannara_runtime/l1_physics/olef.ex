defmodule Tiannara.L1Physics.OLEF do
  @moduledoc """
  L1 - Ontological Latent Energy Field (OLEF)
  
  Manages baseline pressure and continuous computational force 
  across the substrate without imposing any L2+ semantics.
  """

  use GenServer
  require Logger

  @default_pressure 100.0

  defstruct [
    global_pressure: @default_pressure,
    local_gradients: %{}
  ]

  # Public API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def apply_pressure(node_id, pressure_delta) do
    GenServer.cast(__MODULE__, {:apply_pressure, node_id, pressure_delta})
  end

  def get_baseline_pressure do
    GenServer.call(__MODULE__, :get_pressure)
  end

  # Callbacks

  @impl true
  def init(_opts) do
    Logger.info("L1 OLEF initialized. Baseline pressure set to #{@default_pressure}")
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_cast({:apply_pressure, node_id, delta}, state) do
    current = Map.get(state.local_gradients, node_id, state.global_pressure)
    new_pressure = max(0.0, current + delta)
    
    updated_gradients = Map.put(state.local_gradients, node_id, new_pressure)
    
    # Recalculate global pressure as an average
    new_global = Enum.reduce(updated_gradients, 0.0, fn {_, p}, acc -> acc + p end) / 
                 max(1, map_size(updated_gradients))

    {:noreply, %{state | local_gradients: updated_gradients, global_pressure: new_global}}
  end

  @impl true
  def handle_call(:get_pressure, _from, state) do
    {:reply, state.global_pressure, state}
  end
end
