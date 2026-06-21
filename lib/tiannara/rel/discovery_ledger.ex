defmodule Tiannara.REL.DiscoveryLedger do
  @moduledoc """
  Tracks Discoveries and their ownership across civilizations.
  Handles knowledge maintenance and loss.
  """
  
  use GenServer
  require Logger

  alias Tiannara.REL.EconomyEngine
  alias Tiannara.Core.WorldModel.Discovery

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Register a new discovery created by a civilization."
  def register_discovery(civ_id, %Discovery{} = discovery) do
    GenServer.call(__MODULE__, {:register, civ_id, discovery})
  end

  @doc "A civilization unlocks/inherits an existing discovery."
  def unlock_discovery(civ_id, discovery_id) do
    GenServer.call(__MODULE__, {:unlock, civ_id, discovery_id})
  end

  @doc "Get all discoveries known by a civilization."
  def get_known_discoveries(civ_id) do
    GenServer.call(__MODULE__, {:get_known, civ_id})
  end

  @doc "Tick a civilization, charging maintenance for its discoveries."
  def tick_maintenance(civ_id) do
    GenServer.cast(__MODULE__, {:tick_maintenance, civ_id})
  end

  @doc "Grant a license from one civilization to another."
  def grant_license(owner_civ_id, licensee_civ_id, discovery_id, cost_map) do
    GenServer.call(__MODULE__, {:grant_license, owner_civ_id, licensee_civ_id, discovery_id, cost_map})
  end

  @doc "Process active licenses (transfer funds)."
  def process_licenses do
    GenServer.cast(__MODULE__, :process_licenses)
  end

  @doc "Update an existing discovery."
  def update_discovery(discovery) do
    GenServer.cast(__MODULE__, {:update_discovery, discovery})
  end

  @doc "Remove a discovery from a civilization (e.g. curing a disease)."
  def remove_discovery(civ_id, discovery_id) do
    GenServer.cast(__MODULE__, {:remove_discovery, civ_id, discovery_id})
  end

  @doc "Orphan all discoveries for an extinct civilization, returning the relics."
  def orphan_for_civilization(civ_id) do
    GenServer.call(__MODULE__, {:orphan_for_civilization, civ_id})
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting REL Discovery Ledger")
    state = %{
      # id -> %Discovery{}
      discoveries: %{},
      # civ_id -> MapSet.new([discovery_ids])
      ownership: %{},
      # license_id -> %DiscoveryLicense{}
      licenses: %{}
    }
    {:ok, state}
  end

  @impl true
  def handle_call({:register, civ_id, discovery}, _from, state) do
    new_discoveries = Map.put(state.discoveries, discovery.id, discovery)
    civ_ownership = Map.get(state.ownership, civ_id, MapSet.new()) |> MapSet.put(discovery.id)
    new_ownership = Map.put(state.ownership, civ_id, civ_ownership)
    
    Tiannara.Sentinel.DiscoveryGenealogy.record_discovery(discovery)
    Tiannara.Sentinel.EpistemicArchaeology.analyze_for_precursors(discovery)
    
    Logger.info("💡 [REL] Civilization #{civ_id} made discovery: #{discovery.name}")
    {:reply, :ok, %{state | discoveries: new_discoveries, ownership: new_ownership}}
  end

  def handle_call({:unlock, civ_id, discovery_id}, _from, state) do
    if Map.has_key?(state.discoveries, discovery_id) do
      # Enforce prerequisites or quantum leap?
      # For now, just grant it, the logic for quantum leap costs can be in the caller or here.
      civ_ownership = Map.get(state.ownership, civ_id, MapSet.new()) |> MapSet.put(discovery_id)
      new_ownership = Map.put(state.ownership, civ_id, civ_ownership)
      {:reply, :ok, %{state | ownership: new_ownership}}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:grant_license, owner, licensee, disc_id, cost_map}, _from, state) do
    if MapSet.member?(Map.get(state.ownership, owner, MapSet.new()), disc_id) do
      license = Tiannara.REL.DiscoveryLicense.new(owner, licensee, disc_id, cost_map)
      
      # The licensee gains ownership/access to the discovery
      civ_ownership = Map.get(state.ownership, licensee, MapSet.new()) |> MapSet.put(disc_id)
      new_ownership = Map.put(state.ownership, licensee, civ_ownership)
      
      new_licenses = Map.put(state.licenses, license.id, license)
      Logger.info("📜 [REL] #{owner} licensed #{disc_id} to #{licensee}")
      
      # EC-4: Award Influence Capital to the licensor
      Tiannara.REL.EconomyEngine.grant_influence_capital(owner, 50.0)
      
      # EDM-1: Transmission vector
      disc = Map.get(state.discoveries, disc_id)
      if disc do
        for disease_id <- Map.get(disc, :infected_by, []) do
          Logger.warn("🦠 [EDM] Disease #{disease_id} transmitted via license of #{disc_id} to #{licensee}!")
          # A fully realized engine would register the infection on the licensee side.
          # We'll just log the transmission here.
        end
      end

      {:reply, {:ok, license.id}, %{state | licenses: new_licenses, ownership: new_ownership}}
    else
      {:reply, {:error, :owner_lacks_discovery}, state}
    end
  end

  def handle_call({:get_known, civ_id}, _from, state) do
    ids = Map.get(state.ownership, civ_id, MapSet.new())
    known = Enum.map(ids, &Map.get(state.discoveries, &1))
    {:reply, known, state}
  end

  def handle_call({:orphan_for_civilization, civ_id}, _from, state) do
    ids = Map.get(state.ownership, civ_id, MapSet.new())
    relics = Enum.map(ids, &Map.get(state.discoveries, &1))
    
    # We remove the active ownership from this civilization
    new_ownership = Map.delete(state.ownership, civ_id)
    
    # In a fully realized implementation, we would set discoveries to a :relic status
    # if nobody else owns them. For now, we return them to the caller to be bundled into the EpochClosure/Ruin.
    
    Logger.info("🏛️ [REL] Civilization #{civ_id} extinct. Orphaned #{length(relics)} discoveries to relic state.")
    {:reply, relics, %{state | ownership: new_ownership}}
  end

  @impl true
  def handle_cast({:tick_maintenance, civ_id}, state) do
    ids = Map.get(state.ownership, civ_id, MapSet.new())
    
    # Calculate total maintenance for this civilization's discoveries
    total_cost = Enum.reduce(ids, 0, fn id, acc -> 
      discovery = state.discoveries[id]
      acc + (discovery.complexity_cost || 0)
    end)

    if total_cost > 0 do
      # Attempt to charge the EconomyEngine
      case EconomyEngine.consume(civ_id, %{ontological_capital: total_cost, compute: div(total_cost, 2)}) do
        :ok -> 
          {:noreply, state}
        {:error, _} ->
          # If they can't pay, they start forgetting discoveries (dark ages)
          if MapSet.size(ids) > 0 do
             forgotten_id = Enum.random(ids)
             new_ids = MapSet.delete(ids, forgotten_id)
             new_ownership = Map.put(state.ownership, civ_id, new_ids)
             
             # Terminate any licenses where this civ is the licensee for this discovery
             new_licenses = state.licenses
             |> Enum.reject(fn {_id, lic} -> lic.licensee_civ_id == civ_id and lic.discovery_id == forgotten_id end)
             |> Enum.into(%{})

             Logger.warn("🌑 [REL] Dark Age! Civilization #{civ_id} forgot discovery #{state.discoveries[forgotten_id].name} due to lack of resources. Associated licenses terminated.")
             {:noreply, %{state | ownership: new_ownership, licenses: new_licenses}}
          else
             {:noreply, state}
          end
      end
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:update_discovery, discovery}, state) do
    new_discoveries = Map.put(state.discoveries, discovery.id, discovery)
    {:noreply, %{state | discoveries: new_discoveries}}
  end

  @impl true
  def handle_cast({:remove_discovery, civ_id, discovery_id}, state) do
    ids = Map.get(state.ownership, civ_id, MapSet.new())
    new_ids = MapSet.delete(ids, discovery_id)
    new_ownership = Map.put(state.ownership, civ_id, new_ids)
    
    # Also terminate licenses just like in tick_maintenance
    new_licenses = state.licenses
    |> Enum.reject(fn {_id, lic} -> lic.licensee_civ_id == civ_id and lic.discovery_id == discovery_id end)
    |> Enum.into(%{})
    
    {:noreply, %{state | ownership: new_ownership, licenses: new_licenses}}
  end

  @impl true
  def handle_cast(:process_licenses, state) do
    # Transfer funds for all active licenses
    Enum.each(state.licenses, fn {_, lic} ->
      case EconomyEngine.consume(lic.licensee_civ_id, lic.cost_per_tick) do
        :ok ->
          EconomyEngine.inject(lic.owner_civ_id, lic.cost_per_tick)
        _ ->
          # If they can't pay, they default. The tick_maintenance will eventually shed the discovery.
          :ok
      end
    end)
    {:noreply, state}
  end
end
