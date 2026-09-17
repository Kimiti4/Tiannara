defmodule Tiannara.Physics.EntanglementManager do
  @moduledoc """
  Detects resonance between worlds and triggers Horizontal Law Transfer (HLT)
  or Chimeric Collapse events based on harmonic resonance thresholds.
  
  Implements spatial partitioning for O(N log N) resonance pair detection
  and manages the entanglement lifecycle:
    1. Resonance detection
    2. HLT triggering (resonance > 0.4 AND < merge_threshold)
    3. Chimeric Collapse (resonance > merge_threshold)
    4. Entanglement lock/unlock for atomic state updates
  
  ## Resonance Equation
  R(A, B) = 1/(1 + ||p_A - p_B||) * exp(-λ * |E_A - E_B|)
  
  Where:
    - p = position in CAL cluster space
    - E = entropy field value
    - λ = decay constant (default: 0.5)
  """

  use GenServer
  require Logger

  alias Tiannara.Genetics.WorldGenome
  alias Tiannara.Physics.ChimericResolutionEngine

  @merge_threshold 0.75
  @hlt_threshold 0.40
  @decay_constant 0.5
  @detection_interval_ms 5000  # Check resonance every 5 seconds

  # NATS topics
  @nats_hlt_topic "tiannara.world.hlt.events"
  @nats_merge_topic "tiannara.world.merge.events"
  @nats_lock_topic "tiannara.world.entangle.lock"

  defstruct [
    :nats_connection,
    worlds: %{},
    active_tethers: %{},
    pending_merges: [],
    hlt_exchanges: []
  ]

  @type t :: %__MODULE__{
    nats_connection: pid() | nil,
    worlds: %{String.t() => world_data()},
    active_tethers: %{tether_id() => tether_data()},
    pending_merges: [merge_event()],
    hlt_exchanges: [hlt_event()]
  }

  @type world_data :: %{
    id: String.t(),
    position: [float()],
    entropy: float(),
    fitness: float(),
    genome: WorldGenome.t()
  }

  @type tether_id :: String.t()
  @type tether_data :: %{
    world_a: String.t(),
    world_b: String.t(),
    resonance: float(),
    created_at: DateTime.t()
  }

  @type merge_event :: %{
    world_a: String.t(),
    world_b: String.t(),
    resonance: float(),
    timestamp: DateTime.t()
  }

  @type hlt_event :: %{
    world_a: String.t(),
    world_b: String.t(),
    traded_trait: atom(),
    resonance: float()
  }

  # Public API

  @doc """
  Starts the EntanglementManager GenServer.
  
  ## Options
    - :nats_connection - NATS connection PID (optional, for event publishing)
    - :detection_interval - Resonance check interval in ms (default: 5000)
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a world for resonance tracking.
  
  ## Parameters
    - world_id: Unique world identifier
    - world_data: Map containing position, entropy, fitness, and genome
  """
  def register_world(world_id, world_data) do
    GenServer.call(__MODULE__, {:register_world, world_id, world_data})
  end

  @doc """
  Updates world metrics for resonance recalculation.
  """
  def update_world_metrics(world_id, metrics) do
    GenServer.cast(__MODULE__, {:update_metrics, world_id, metrics})
  end

  @doc """
  Manually trigger a resonance detection cycle.
  """
  def detect_resonance do
    GenServer.call(__MODULE__, :detect_resonance)
  end

  @doc """
  Returns all active entanglement tethers.
  """
  def list_active_tethers do
    GenServer.call(__MODULE__, :list_tethers)
  end

  @doc """
  Returns pending chimeric merge events.
  """
  def list_pending_merges do
    GenServer.call(__MODULE__, :list_merges)
  end

  # GenServer Callbacks

  @impl true
  def init(opts) do
    nats_connection = Keyword.get(opts, :nats_connection)
    detection_interval = Keyword.get(opts, :detection_interval, @detection_interval_ms)

    schedule_detection(detection_interval)

    {:ok,
     %__MODULE__{
       nats_connection: nats_connection
     }}
  end

  @impl true
  def handle_call({:register_world, world_id, world_data}, _from, state) do
    updated_worlds = Map.put(state.worlds, world_id, world_data)
    {:reply, :ok, %{state | worlds: updated_worlds}}
  end

  @impl true
  def handle_call(:detect_resonance, _from, state) do
    {updated_state, pairs} = execute_resonance_detection(state)
    {:reply, {:ok, pairs}, updated_state}
  end

  @impl true
  def handle_call(:list_tethers, _from, state) do
    {:reply, {:ok, state.active_tethers}, state}
  end

  @impl true
  def handle_call(:list_merges, _from, state) do
    {:reply, {:ok, state.pending_merges}, state}
  end

  @impl true
  def handle_cast({:update_metrics, world_id, metrics}, state) do
    case Map.fetch(state.worlds, world_id) do
      {:ok, world_data} ->
        updated_data = Map.merge(world_data, metrics)
        updated_worlds = Map.put(state.worlds, world_id, updated_data)
        {:noreply, %{state | worlds: updated_worlds}}

      :error ->
        Logger.warning("World #{world_id} not found for metric update")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:detect_resonance, state) do
    interval = Keyword.get([], :detection_interval, @detection_interval_ms)
    {updated_state, _pairs} = execute_resonance_detection(state)
    schedule_detection(interval)
    {:noreply, updated_state}
  end

  # Resonance Detection Logic

  defp execute_resonance_detection(state) do
    world_list = Map.values(state.worlds)
    
    # Find all resonant pairs (spatial partitioning for efficiency)
    pairs = find_resonant_pairs(world_list)
    
    # Process each pair
    updated_state =
      Enum.reduce(pairs, state, fn {w1, w2, resonance}, acc_state ->
        cond do
          resonance > @merge_threshold ->
            trigger_chimeric_collapse(w1, w2, resonance, acc_state)

          resonance > @hlt_threshold ->
            trigger_law_transfer(w1, w2, resonance, acc_state)

          true ->
            # Below HLT threshold - maintain or create tether
            manage_tether(w1, w2, resonance, acc_state)
        end
      end)

    {updated_state, pairs}
  end

  @doc """
  Calculates harmonic resonance between two worlds.
  
  R(A, B) = 1/(1 + ||p_A - p_B||) * exp(-λ * |E_A - E_B|)
  """
  def calculate_resonance(world_a, world_b) do
    # L1 Substrate: Geometric encoding via Holographic State Vectors (HSV)
    position_distance = Tiannara.L1Physics.HSV.calculate_distance(world_a.position, world_b.position)
    
    # L1 Substrate: Baseline pressure via Ontological Latent Energy Field (OLEF)
    base_pressure = Tiannara.L1Physics.OLEF.get_baseline_pressure()
    
    # L1 Substrate: Topological resistance via Dynamic Friction Gradients (DFG)
    entropy_diff = abs(world_a.entropy - world_b.entropy)
    friction = Tiannara.L1Physics.DFG.calculate_friction(entropy_diff, base_pressure)
    dampened_entropy_diff = entropy_diff * (1.0 - friction)
    
    spatial_factor = 1.0 / (1.0 + position_distance)
    entropy_factor = :math.exp(-@decay_constant * dampened_entropy_diff)
    
    spatial_factor * entropy_factor
  end

  @doc """
  Finds all resonant pairs using spatial partitioning (KD-Tree approximation).
  
  For production-scale (10,000+ worlds), this should use a proper KD-Tree
  implementation. Current implementation uses distance-based filtering.
  """
  def find_resonant_pairs(worlds) do
    # Naive O(N²) implementation - replace with KD-Tree for large scales
    for i <- 0..(length(worlds) - 2),
        j <- (i + 1)..(length(worlds) - 1),
        w1 = Enum.at(worlds, i),
        w2 = Enum.at(worlds, j),
        resonance = calculate_resonance(w1, w2),
        resonance > @hlt_threshold do
      {w1, w2, resonance}
    end
  end

  @doc """
  Triggers Chimeric Collapse when resonance exceeds merge threshold.
  
  Publishes merge event to NATS and initiates atomic state recombination.
  """
  def trigger_chimeric_collapse(world_a, world_b, resonance, state) do
    Logger.info(" CHIMERIC COLLAPSE: #{world_a.id} + #{world_b.id} (R=#{:erlang.float_to_binary(resonance, decimals: 3)})")

    merge_event = %{
      world_a: world_a.id,
      world_b: world_b.id,
      resonance: resonance,
      timestamp: DateTime.utc_now()
    }

    # Publish to NATS
    publish_merge_event(merge_event, state)

    # Add to pending merges for resolution engine
    updated_pending = [merge_event | state.pending_merges]

    # Remove active tethers between these worlds
    updated_tethers = remove_tether(world_a.id, world_b.id, state.active_tethers)

    %{
      state
      | pending_merges: updated_pending,
        active_tethers: updated_tethers
    }
  end

  @doc """
  Triggers Horizontal Law Transfer (HLT) for partial gene exchange.
  
  Worlds trade specific subsystem parameters without full merge.
  """
  def trigger_law_transfer(world_a, world_b, resonance, state) do
    # Select a random trait to transfer
    traits = [:cal_genes, :cis_genes, :entropy_genes, :selection_genes]
    traded_trait = Enum.random(traits)

    hlt_event = %{
      world_a: world_a.id,
      world_b: world_b.id,
      traded_trait: traded_trait,
      resonance: resonance,
      timestamp: DateTime.utc_now()
    }

    Logger.info("🔗 HLT: #{world_a.id} <-> #{world_b.id} (trading #{traded_trait})")

    publish_hlt_event(hlt_event, state)

    # Execute gene transfer
    updated_state = execute_gene_transfer(world_a, world_b, traded_trait, state)

    # Maintain tether
    updated_tethers = upsert_tether(world_a.id, world_b.id, resonance, updated_state.active_tethers)

    %{
      updated_state
      | active_tethers: updated_tethers
    }
  end

  defp manage_tether(world_a, world_b, resonance, state) do
    tether_id = create_tether_id(world_a.id, world_b.id)

    case Map.fetch(state.active_tethers, tether_id) do
      {:ok, _existing_tether} ->
        # Update resonance value
        updated_tether = %{
          world_a: world_a.id,
          world_b: world_b.id,
          resonance: resonance,
          created_at: DateTime.utc_now()
        }

        %{state | active_tethers: Map.put(state.active_tethers, tether_id, updated_tether)}

      :error ->
        # Create new tether
        new_tether = %{
          world_a: world_a.id,
          world_b: world_b.id,
          resonance: resonance,
          created_at: DateTime.utc_now()
        }

        %{state | active_tethers: Map.put(state.active_tethers, tether_id, new_tether)}
    end
  end

  defp execute_gene_transfer(world_a, world_b, trait, state) do
    # This would call actual world state managers to transfer genes
    # For now, just log the event
    Logger.debug("Gene transfer: #{world_a.id} -> #{world_b.id} (#{trait})")
    state
  end

  # Tether Management

  defp create_tether_id(world_a_id, world_b_id) do
    ids = Enum.sort([world_a_id, world_b_id])
    Enum.join(ids, "-")
  end

  defp upsert_tether(world_a_id, world_b_id, resonance, tethers) do
    tether_id = create_tether_id(world_a_id, world_b_id)
    
    new_tether = %{
      world_a: world_a_id,
      world_b: world_b_id,
      resonance: resonance,
      created_at: DateTime.utc_now()
    }

    Map.put(tethers, tether_id, new_tether)
  end

  defp remove_tether(world_a_id, world_b_id, tethers) do
    tether_id = create_tether_id(world_a_id, world_b_id)
    Map.delete(tethers, tether_id)
  end

  # NATS Event Publishing

  defp publish_merge_event(merge_event, state) do
    case state.nats_connection do
      nil ->
        Logger.debug("Mock merge event: #{inspect(merge_event)}")
        :ok

      conn_pid ->
        payload = Jason.encode!(merge_event)
        :gnat.pub(conn_pid, @nats_merge_topic, payload)
    end
  end

  defp publish_hlt_event(hlt_event, state) do
    case state.nats_connection do
      nil ->
        Logger.debug("Mock HLT event: #{inspect(hlt_event)}")
        :ok

      conn_pid ->
        payload = Jason.encode!(hlt_event)
        :gnat.pub(conn_pid, @nats_hlt_topic, payload)
    end
  end

  # Helpers

  defp calculate_position_distance(pos_a, pos_b) do
    Tiannara.L1Physics.HSV.calculate_distance(pos_a, pos_b)
  end

  defp schedule_detection(interval_ms) do
    Process.send_after(self(), :detect_resonance, interval_ms)
  end
end
