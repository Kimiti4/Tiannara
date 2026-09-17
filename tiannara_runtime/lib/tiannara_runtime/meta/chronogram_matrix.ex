defmodule Tiannara.Meta.ChronogramMatrix do
  @moduledoc """
  Phase 5F.4 — Holographic Chronogram Memory Substrate

  Stores all observer histories as interference-encoded memory states.
  Replaces DAG/lineage systems with frequency-indexed memory blobs.

  ## Core Principle

  > There is no "history lookup." There is only **wave projection under observer frequency**

  ## Architecture

  - ETS-backed chronogram matrix storing encoded memories
  - Observer MEI (Memory Entanglement Index) registry for frequency assignment
  - Phase encoding/decoding based on observer frequency
  - Amplitude represents entropy/stability of memory

  ## Usage

      # Register observer
      {:ok, mei} = ChronogramMatrix.register_observer("obs_001")

      # Write memory (encoded with observer frequency)
      state = %{coordinate: "event_001", data: "important event", entropy: 0.3}
      :ok = ChronogramMatrix.write("obs_001", state)

      # Read memory (decoded through observer filter)
      {payload, amplitude} = ChronogramMatrix.read("obs_001", "event_001")

  ## Key Properties

  - **Observer-relative truth**: Same coordinate returns different results per observer
  - **No global timeline**: All histories coexist in interference pattern
  - **Frequency separation**: Contradictions encoded as phase offsets, not conflicts
  - **Compression via encoding**: Physical interference collapse replaces algorithmic pruning
  """

  use GenServer
  require Logger

  # ETS table names
  @table :chronogram_matrix
  @observer_table :observer_mei_registry

  # Base frequency for root observers (golden ratio for stability)
  @base_frequency 1.618

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the ChronogramMatrix GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Writes a causal state to the chronogram, encoded with observer's MEI frequency.

  ## Parameters
  - `observer_id`: The observer writing the memory
  - `causal_state`: Map containing at least `:coordinate` field

  ## Returns
  - `:ok` on success
  - `{:error, :observer_not_registered}` if observer hasn't been registered

  ## Example

      state = %{
        coordinate: "world_event_001",
        data: "Important observation",
        entropy: 0.3,
        timestamp: System.system_time(:second)
      }

      :ok = ChronogramMatrix.write("obs_001", state)
  """
  def write(observer_id, causal_state) do
    GenServer.cast(__MODULE__, {:write, observer_id, causal_state})
  end

  @doc """
  Reads a memory from the chronogram, decoded through observer's MEI filter.

  ## Parameters
  - `observer_id`: The observer requesting the memory
  - `coordinate`: The memory coordinate to retrieve

  ## Returns
  - `{:ok, {payload, amplitude}}` with decoded memory and confidence amplitude
  - `{:empty, 0.0}` if no memory exists at that coordinate for this observer

  ## Key Property

  Two observers querying the same coordinate may receive different results
  because truth is filtered through their unique MEI frequency.
  """
  def read(observer_id, coordinate) do
    GenServer.call(__MODULE__, {:read, observer_id, coordinate})
  end

  @doc """
  Registers a new observer with a unique MEI frequency.

  ## Parameters
  - `observer_id`: Unique identifier for the observer
  - `parent_id`: Optional parent observer ID (for lineage-based frequency derivation)

  ## Returns
  - `{:ok, mei}` with the assigned Memory Entanglement Index (frequency)

  ## Frequency Assignment

  - Root observers get `@base_frequency` (1.618)
  - Child observers get parent frequency + phase shift (π / random(10))
  - Ensures no two observers share identical MEI unless explicitly cloned

  ## Example

      # Root observer
      {:ok, mei} = ChronogramMatrix.register_observer("obs_root")

      # Child observer (derived frequency)
      {:ok, child_mei} = ChronogramMatrix.register_observer("obs_child", "obs_root")
  """
  def register_observer(observer_id, parent_id \\ nil) do
    GenServer.call(__MODULE__, {:register_observer, observer_id, parent_id})
  end

  @doc """
  Gets the MEI frequency for an observer.

  ## Returns
  - `{:ok, mei}` if observer is registered
  - `{:error, :not_found}` if observer doesn't exist
  """
  def get_observer_mei(observer_id) do
    case :ets.lookup(@observer_table, observer_id) do
      [{^observer_id, mei}] -> {:ok, mei}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Lists all registered observers and their MEI frequencies.
  """
  def list_observers do
    :ets.tab2list(@observer_table)
    |> Enum.map(fn {id, mei} -> %{observer_id: id, mei: mei} end)
  end

  @doc """
  Gets statistics about the chronogram matrix.
  """
  def get_stats do
    total_entries = :ets.info(@table, :size)
    total_observers = :ets.info(@observer_table, :size)

    %{
      total_memory_entries: total_entries,
      total_registered_observers: total_observers,
      table_name: @table,
      observer_table_name: @observer_table
    }
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("🌌 ChronogramMatrix initialized (Phase 5F.4 Holographic Memory)")

    # Create ETS tables
    :ets.new(@table, [:set, :public, :named_table])
    :ets.new(@observer_table, [:set, :public, :named_table])

    state = %{base_frequency: @base_frequency}

    {:ok, state}
  end

  @impl true
  def handle_cast(:reset, state) do
    :ets.delete_all_objects(@table)
    :ets.delete_all_objects(@observer_table)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:write, observer_id, causal_state}, state) do
    case get_mei(observer_id) do
      nil ->
        Logger.error("❌ Chronogram write rejected: observer #{observer_id} not registered")
        {:noreply, state}

      mei ->
        # Encode state with observer's MEI frequency
        encoded = encode_state(causal_state, mei)

        # Store in chronogram matrix
        :ets.insert(@table, {
          {observer_id, causal_state.coordinate},
          encoded
        })

        Logger.debug("✅ Chronogram write: observer=#{observer_id}, coord=#{causal_state.coordinate}")

        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:read, observer_id, coord}, _from, state) do
    mei = get_mei(observer_id)

    result =
      case :ets.lookup(@table, {observer_id, coord}) do
        [] ->
          Logger.debug("📭 Chronogram read empty: observer=#{observer_id}, coord=#{coord}")
          {:empty, 0.0}

        [{_, encoded}] ->
          # Decode through observer's MEI filter
          decoded = decode_state(encoded, mei)
          Logger.debug("📖 Chronogram read: observer=#{observer_id}, coord=#{coord}, amplitude=#{elem(decoded, 1)}")
          decoded
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:register_observer, id, parent}, _from, state) do
    # Calculate MEI frequency
    mei =
      case parent do
        nil ->
          # Root observer gets base frequency + small random offset for uniqueness
          state.base_frequency + :rand.uniform() * 0.1

        parent_id ->
          # Child observer gets parent frequency + phase shift
          parent_mei = get_mei(parent_id) || state.base_frequency + :rand.uniform() * 0.1
          phase_shift = :math.pi() / :rand.uniform(10)
          parent_mei + phase_shift
      end

    # Register in observer table
    :ets.insert(@observer_table, {id, mei})

    Logger.info("👁️ Observer registered: id=#{id}, mei=#{:erlang.float_to_binary(mei, decimals: 6)}, parent=#{inspect(parent)}")

    {:reply, {:ok, mei}, state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp get_mei(id) do
    case :ets.lookup(@observer_table, id) do
      [{^id, mei}] -> mei
      _ -> nil
    end
  end

  @doc false
  def encode_state(state, mei) do
    # Phase encoding based on observer's MEI frequency
    phase = mei * 0.1

    # Amplitude represents entropy/stability of the memory
    amplitude = compute_entropy(state)

    %{
      payload: state,
      amplitude: amplitude,
      phase: phase,
      encoded_at: System.system_time(:second)
    }
  end

  @doc false
  def decode_state(encoded, mei) do
    # Apply observer-specific filter (cosine projection)
    filter = :math.cos(mei * 0.1)

    # Return decoded payload with filtered amplitude
    {
      encoded.payload,
      encoded.amplitude * filter
    }
  end

  defp compute_entropy(state) do
    # Stable entropy metric based on state complexity
    # In production, this would use sophisticated entropy calculation
    # For now, use map size as proxy for complexity
    try do
      map_size(Map.from_struct(state)) / 10.0
    rescue
      _ -> map_size(state) / 10.0
    end
  end
end
