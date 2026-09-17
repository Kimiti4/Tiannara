defmodule Tiannara.MCALv2.IdentityTree do
  @moduledoc """
  MCAL v2: Recursive Identity Tree.
  
  A stateful GenServer acting as the root repository for all identities and their lineages.
  Maintains the identity ecology.
  """
  
  use GenServer
  require Logger
  
  alias Tiannara.MCALv2.Identity

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{identities: %{}, root_id: nil}, name: __MODULE__)
  end

  def register_identity(identity) do
    GenServer.cast(__MODULE__, {:register, identity})
  end
  
  def get_all_identities() do
    GenServer.call(__MODULE__, :get_all)
  end
  
  def set_root(identity) do
    GenServer.cast(__MODULE__, {:set_root, identity})
  end

  @impl true
  def init(state) do
    Logger.info("🌲 [MCAL v2] Recursive Identity Tree initialized. Awaiting root identity.")
    {:ok, state}
  end

  @impl true
  def handle_cast({:register, identity}, state) do
    Logger.debug("🌲 [MCAL v2] Registering new identity lineage: #{identity.id}")
    new_identities = Map.put(state.identities, identity.id, identity)
    {:noreply, %{state | identities: new_identities}}
  end
  
  @impl true
  def handle_cast({:set_root, identity}, state) do
    Logger.info("🌲 [MCAL v2] Establishing Root Cognitive Identity: #{identity.id}")
    new_identities = Map.put(state.identities, identity.id, identity)
    {:noreply, %{state | identities: new_identities, root_id: identity.id}}
  end

  @impl true
  def handle_call(:get_all, _from, state) do
    {:reply, Map.values(state.identities), state}
  end
end
