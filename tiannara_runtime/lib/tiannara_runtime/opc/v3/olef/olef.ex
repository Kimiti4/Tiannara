defmodule Tiannara.OPC.V3.OLEF do
  @moduledoc """
  Observer Logic Execution Framework (OLEF)
  GenServer implementation for distributed pressure mesh
  """

  use GenServer

  alias Tiannara.OPC.V3.OLEF.PressureMesh
  alias Tiannara.OPC.V3.OLEF.DistributedObserver

  # Client API
  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init_olef(options \\ %{}) do
    case Process.whereis(__MODULE__) do
      nil -> start_link(options)
      _pid -> :ignore  # Already running
    end
  end

  def apply_pressure(source_id, pressure_value, coordinates) do
    GenServer.call(__MODULE__, {:apply_pressure, source_id, pressure_value, coordinates})
  end

  def get_pressure_field() do
    GenServer.call(__MODULE__, :get_pressure_field)
  end

  def get_equilibrium_state() do
    GenServer.call(__MODULE__, :get_equilibrium_state)
  end

  def register_observer(observer_spec) do
    GenServer.call(__MODULE__, {:register_observer, observer_spec})
  end

  # Server Callbacks
  @impl true
  def init(opts) do
    # Initialize the pressure mesh
    mesh = PressureMesh.new(Map.get(opts, :mesh_dimensions, {10, 10}))
    
    # Initialize observers
    observers = []
    
    # Set up state
    state = %{
      mesh: mesh,
      observers: observers,
      equilibrium_threshold: Map.get(opts, :equilibrium_threshold, 0.001),
      last_update: System.os_time(:millisecond)
    }
    
    {:ok, state}
  end

  @impl true
  def handle_call({:apply_pressure, source_id, pressure_value, coordinates}, _from, state) do
    updated_mesh = PressureMesh.apply_pressure(state.mesh, source_id, pressure_value, coordinates)
    updated_state = Map.put(state, :mesh, updated_mesh) |> Map.put(:last_update, System.os_time(:millisecond))
    
    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call(:get_pressure_field, _from, state) do
    pressure_field = PressureMesh.calculate_pressure_field(state.mesh)
    {:reply, {:ok, pressure_field}, state}
  end

  @impl true
  def handle_call(:get_equilibrium_state, _from, state) do
    equilibrium = PressureMesh.check_equilibrium(state.mesh, state.equilibrium_threshold)
    {:reply, {:ok, equilibrium}, state}
  end

  @impl true
  def handle_call({:register_observer, observer_spec}, _from, state) do
    new_observer = DistributedObserver.new(observer_spec)
    updated_observers = [new_observer | state.observers]
    updated_state = Map.put(state, :observers, updated_observers)
    
    {:reply, {:ok, new_observer.id}, updated_state}
  end
end
