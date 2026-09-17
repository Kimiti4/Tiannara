defmodule Tiannara.MetaEcology.WorldRegistry do
  @moduledoc """
  Meta-Ecology: World Registry.
  
  Manages a graph of 8-16 specialized worlds. Each world acts as a node
  in the higher ecological graph, preventing monoculture collapse by enforcing
  specialization roles (e.g., Engineering, Chaos, Archive).
  """
  
  use GenServer
  require Logger
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Registers a new specialized world.
  """
  def register_world(world_id, role) do
    GenServer.call(__MODULE__, {:register, world_id, role})
  end
  
  @doc """
  Returns the active ecosystem map.
  """
  def get_ecosystem() do
    GenServer.call(__MODULE__, :get_ecosystem)
  end
  
  # ── GenServer Callbacks ───────────────────────────────────────────────────
  
  @impl true
  def init(_opts) do
    Logger.info("📋 [Meta-Ecology] WorldRegistry initialized. Managing global cognitive ecosystem.")
    {:ok, %{}}
  end
  
  @impl true
  def handle_call({:register, world_id, role}, _from, state) do
    Logger.info("🌍 [Meta-Ecology] Registered new world: #{world_id} [Role: #{role}]")
    new_state = Map.put(state, world_id, %{role: role, active: true})
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call(:get_ecosystem, _from, state) do
    {:reply, state, state}
  end
end
