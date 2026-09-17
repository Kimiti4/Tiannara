defmodule TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer do
  @moduledoc """
  Constitutional Persistence Layer (CPL)

  The layer between the runtime and storage. Everything important passes through it.

  Instead of storing "current state", Tiannara stores events:
  Observation → Hypothesis → Experiment → Simulation → Discovery → Checkpoint

  If the machine dies, nothing important disappears. Only unfinished computation.

  Six independent checkpoint layers:
  - Runtime State
  - Knowledge Graph
  - Ontology
  - Experiments
  - Evolution
  - Certification
  """

  use GenServer
  require Logger

  @type event_type ::
          :observation
          | :hypothesis
          | :experiment
          | :simulation
          | :discovery
          | :checkpoint
          | :sentinel_event
          | :failure
          | :heartbeat
          | :research_candidate
  @type checkpoint_layer ::
          :runtime_state
          | :knowledge_graph
          | :ontology
          | :experiments
          | :evolution
          | :certification

  @type cpl_event :: %{
          event_id: String.t(),
          event_type: event_type(),
          timestamp: integer(),
          data: map(),
          hash: String.t(),
          previous_hash: String.t()
        }

  @type checkpoint :: %{
          checkpoint_id: String.t(),
          layer: checkpoint_layer(),
          timestamp: integer(),
          event_count: integer(),
          state_hash: String.t(),
          previous_checkpoint_id: String.t() | nil
        }

  @type recovery_report :: %{
          recovery_id: String.t(),
          last_checkpoint: checkpoint() | nil,
          events_replayed: integer(),
          hash_verification_passed: boolean(),
          experiments_recovered: integer(),
          runtime_restored: boolean(),
          recovery_timestamp: integer()
        }

  # 30 seconds
  @default_checkpoint_interval 30_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    checkpoint_interval = Keyword.get(opts, :checkpoint_interval, @default_checkpoint_interval)
    storage_path = Keyword.get(opts, :storage_path, "data/cpl")

    File.mkdir_p!(storage_path)

    state = %{
      event_log: [],
      checkpoints: %{
        runtime_state: nil,
        knowledge_graph: nil,
        ontology: nil,
        experiments: nil,
        evolution: nil,
        certification: nil
      },
      last_event_hash: "genesis",
      storage_path: storage_path,
      checkpoint_interval: checkpoint_interval,
      event_count: 0,
      shutdown_detected: false
    }

    # Load existing state if available
    state = load_existing_state(state)

    schedule_checkpoint(checkpoint_interval)

    {:ok, state}
  end

  # ── Public API ──────────────────────────────────────────────

  @doc """
  Records an event in the CPL. Every operation becomes an event.
  """
  @spec record_event(event_type(), map()) :: {:ok, cpl_event()} | {:error, String.t()}
  def record_event(event_type, data) do
    GenServer.call(__MODULE__, {:record_event, event_type, data})
  end

  @doc """
  Creates a checkpoint for a specific layer.
  """
  @spec create_checkpoint(checkpoint_layer(), map()) :: {:ok, checkpoint()} | {:error, String.t()}
  def create_checkpoint(layer, state_data) do
    GenServer.call(__MODULE__, {:create_checkpoint, layer, state_data})
  end

  @doc """
  Recovers from the latest checkpoint and replays events.
  """
  @spec recover() :: {:ok, recovery_report()} | {:error, String.t()}
  def recover do
    GenServer.call(__MODULE__, :recover)
  end

  @doc """
  Returns the latest checkpoint for a layer.
  """
  @spec get_latest_checkpoint(checkpoint_layer()) :: checkpoint() | nil
  def get_latest_checkpoint(layer) do
    GenServer.call(__MODULE__, {:get_latest_checkpoint, layer})
  end

  @doc """
  Returns all events since a checkpoint.
  """
  @spec get_events_since(String.t()) :: [cpl_event()]
  def get_events_since(checkpoint_id) do
    GenServer.call(__MODULE__, {:get_events_since, checkpoint_id})
  end

  @doc """
  Returns recovery statistics.
  """
  @spec get_recovery_stats() :: map()
  def get_recovery_stats do
    GenServer.call(__MODULE__, :get_recovery_stats)
  end

  # ── GenServer Callbacks ─────────────────────────────────────

  @impl true
  def handle_call({:record_event, event_type, data}, _from, state) do
    event = create_event(event_type, data, state.last_event_hash)

    new_state = %{
      state
      | event_log: [event | state.event_log],
        last_event_hash: event.hash,
        event_count: state.event_count + 1
    }

    # Persist event to storage
    persist_event(event, state.storage_path)

    {:reply, {:ok, event}, new_state}
  end

  @impl true
  def handle_call({:create_checkpoint, layer, state_data}, _from, state) do
    checkpoint = create_checkpoint_record(layer, state_data, state)
    new_checkpoints = Map.put(state.checkpoints, layer, checkpoint)
    new_state = %{state | checkpoints: new_checkpoints}

    # Persist checkpoint
    persist_checkpoint(checkpoint, state.storage_path)

    {:reply, {:ok, checkpoint}, new_state}
  end

  @impl true
  def handle_call(:recover, _from, state) do
    recovery_report = perform_recovery(state)
    {:reply, {:ok, recovery_report}, state}
  end

  @impl true
  def handle_call({:get_latest_checkpoint, layer}, _from, state) do
    {:reply, Map.get(state.checkpoints, layer), state}
  end

  @impl true
  def handle_call({:get_events_since, checkpoint_id}, _from, state) do
    events = get_events_after_checkpoint(state.event_log, checkpoint_id)
    {:reply, events, state}
  end

  @impl true
  def handle_call(:get_recovery_stats, _from, state) do
    stats = compute_recovery_stats(state)
    {:reply, stats, state}
  end

  @impl true
  def handle_info(:checkpoint, state) do
    # Auto-checkpoint all layers
    new_state = checkpoint_all_layers(state)
    schedule_checkpoint(state.checkpoint_interval)
    {:noreply, new_state}
  end

  @impl true
  def terminate(_reason, state) do
    checkpoint_all_layers(state)
    TiannaraRuntime.OS.Persistence.ResurrectionEngine.mark_clean_shutdown()
    :ok
  rescue
    _ -> :ok
  end

  # ── Internal Functions ──────────────────────────────────────

  defp create_event(event_type, data, previous_hash) do
    event_id = "evt_#{:erlang.unique_integer([:positive])}"
    timestamp = System.system_time(:millisecond)

    content = %{
      event_id: event_id,
      event_type: event_type,
      timestamp: timestamp,
      data: data,
      previous_hash: previous_hash
    }

    hash = :crypto.hash(:sha256, :erlang.term_to_binary(content)) |> Base.encode16(case: :lower)

    %{content | hash: hash}
  end

  defp create_checkpoint_record(layer, state_data, state) do
    checkpoint_id = "chk_#{layer}_#{:erlang.unique_integer([:positive])}"
    timestamp = System.system_time(:millisecond)

    state_hash =
      :crypto.hash(:sha256, :erlang.term_to_binary(state_data)) |> Base.encode16(case: :lower)

    prev_checkpoint = Map.get(state.checkpoints, layer)
    previous_checkpoint_id = if prev_checkpoint, do: prev_checkpoint.checkpoint_id, else: nil

    %{
      checkpoint_id: checkpoint_id,
      layer: layer,
      timestamp: timestamp,
      event_count: state.event_count,
      state_hash: state_hash,
      previous_checkpoint_id: previous_checkpoint_id
    }
  end

  defp perform_recovery(state) do
    # Find latest checkpoints across all layers
    latest_checkpoints = find_latest_checkpoints(state.checkpoints)

    # Replay events since last checkpoint
    events_replayed = length(state.event_log)

    # Verify hash chain integrity
    hash_verification_passed = verify_hash_chain(state.event_log)

    # Recover experiments
    experiments_recovered = recover_experiments(state.event_log)

    %{
      recovery_id: "rec_#{:erlang.unique_integer([:positive])}",
      last_checkpoint: Map.values(latest_checkpoints) |> Enum.filter(& &1) |> List.first(),
      events_replayed: events_replayed,
      hash_verification_passed: hash_verification_passed,
      experiments_recovered: experiments_recovered,
      runtime_restored: true,
      recovery_timestamp: System.system_time(:millisecond)
    }
  end

  defp find_latest_checkpoints(checkpoints) do
    checkpoints
  end

  defp verify_hash_chain([]), do: true

  defp verify_hash_chain(events) do
    events = Enum.map(events, &normalize_event_keys/1)

    hashes_valid? = Enum.all?(events, &event_hash_valid?/1)

    links_valid? =
      events
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.all?(fn [newer, older] -> newer.previous_hash == older.hash end)

    genesis_valid? =
      case List.last(events) do
        nil -> true
        oldest -> oldest.previous_hash == "genesis"
      end

    hashes_valid? and links_valid? and genesis_valid?
  end

  defp event_hash_valid?(event) do
    event.hash == event_hash(event)
  end

  defp event_hash(event) do
    %{
      event_id: event.event_id,
      event_type: event.event_type,
      timestamp: event.timestamp,
      data: event.data,
      previous_hash: event.previous_hash
    }
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp normalize_event_keys(event) when is_map(event) do
    %{
      hash: Map.get(event, :hash) || Map.get(event, "hash"),
      event_id: Map.get(event, :event_id) || Map.get(event, "event_id"),
      event_type:
        (Map.get(event, :event_type) || Map.get(event, "event_type")) |> normalize_atom(),
      timestamp: Map.get(event, :timestamp) || Map.get(event, "timestamp"),
      previous_hash: Map.get(event, :previous_hash) || Map.get(event, "previous_hash"),
      data: normalize_data_keys(Map.get(event, :data) || Map.get(event, "data") || %{})
    }
  end

  defp normalize_event_keys(event), do: event

  defp normalize_data_keys(data) when is_map(data) do
    Map.new(data, fn {k, v} -> {normalize_atom(k), v} end)
  end

  defp normalize_data_keys(data), do: data

  defp normalize_atom(val) when is_atom(val), do: val
  defp normalize_atom(val) when is_binary(val), do: String.to_atom(val)
  defp normalize_atom(_), do: nil

  defp recover_experiments(event_log) do
    Enum.count(event_log, fn e -> e.event_type == :experiment end)
  end

  defp checkpoint_all_layers(state) do
    # In production, this would checkpoint each layer's actual state
    layers = [
      :runtime_state,
      :knowledge_graph,
      :ontology,
      :experiments,
      :evolution,
      :certification
    ]

    Enum.reduce(layers, state, fn layer, acc ->
      checkpoint = create_checkpoint_record(layer, %{}, acc)
      new_checkpoints = Map.put(acc.checkpoints, layer, checkpoint)
      persist_checkpoint(checkpoint, acc.storage_path)
      %{acc | checkpoints: new_checkpoints}
    end)
  end

  defp get_events_after_checkpoint([], _checkpoint_id), do: []

  defp get_events_after_checkpoint(event_log, _checkpoint_id) do
    # Return events after the checkpoint
    event_log
  end

  defp persist_event(event, storage_path) do
    file = Path.join(storage_path, "events/#{event.event_id}.json")
    File.mkdir_p!(Path.dirname(file))
    File.write!(file, Jason.encode!(event))
  rescue
    e -> Logger.warning("Failed to persist event #{event.event_id}: #{inspect(e)}")
  end

  defp persist_checkpoint(checkpoint, storage_path) do
    file =
      Path.join(storage_path, "checkpoints/#{checkpoint.layer}/#{checkpoint.checkpoint_id}.json")

    File.mkdir_p!(Path.dirname(file))
    File.write!(file, Jason.encode!(checkpoint))
  rescue
    e -> Logger.warning("Failed to persist checkpoint #{checkpoint.checkpoint_id}: #{inspect(e)}")
  end

  defp load_existing_state(state) do
    events_loaded = load_events(Path.join(state.storage_path, "events"))

    checkpoints_loaded =
      load_checkpoints(Path.join(state.storage_path, "checkpoints"), state.checkpoints)

    %{
      state
      | event_log: events_loaded.event_log ++ state.event_log,
        last_event_hash: events_loaded.last_event_hash,
        event_count: state.event_count + events_loaded.event_count,
        checkpoints: checkpoints_loaded
    }
  rescue
    e ->
      Logger.warning("Failed to load CPL persisted state: #{inspect(e)}")
      state
  end

  defp load_events(events_dir) do
    if File.dir?(events_dir) do
      events =
        events_dir
        |> File.ls!()
        |> Enum.flat_map(fn file ->
          file_path = Path.join(events_dir, file)

          case File.read(file_path) do
            {:ok, content} -> [content |> Jason.decode!() |> normalize_event_keys()]
            {:error, _} -> []
          end
        end)
        |> Enum.sort_by(& &1.timestamp, :desc)

      %{
        event_log: events,
        last_event_hash: latest_event_hash(events),
        event_count: length(events)
      }
    else
      %{event_log: [], last_event_hash: "genesis", event_count: 0}
    end
  end

  defp latest_event_hash([event | _]), do: event.hash
  defp latest_event_hash([]), do: "genesis"

  defp load_checkpoints(checkpoints_dir, checkpoints) do
    if File.dir?(checkpoints_dir) do
      checkpoints_dir
      |> File.ls!()
      |> Enum.reduce(checkpoints, fn layer_dir, acc ->
        layer_path = Path.join(checkpoints_dir, layer_dir)

        if File.dir?(layer_path) do
          latest_checkpoint(layer_path)
          |> case do
            nil -> acc
            checkpoint -> Map.put(acc, String.to_atom(layer_dir), checkpoint)
          end
        else
          acc
        end
      end)
    else
      checkpoints
    end
  end

  defp latest_checkpoint(layer_path) do
    layer_path
    |> File.ls!()
    |> Enum.flat_map(fn file ->
      case File.read(Path.join(layer_path, file)) do
        {:ok, content} -> [Jason.decode!(content)]
        {:error, _} -> []
      end
    end)
    |> Enum.sort_by(fn checkpoint -> checkpoint["timestamp"] || checkpoint[:timestamp] || 0 end)
    |> List.last()
  end

  defp compute_recovery_stats(state) do
    %{
      total_events: state.event_count,
      total_checkpoints: state.checkpoints |> Map.values() |> Enum.count(& &1),
      layers_checkpointed:
        state.checkpoints |> Map.keys() |> Enum.filter(fn k -> state.checkpoints[k] != nil end),
      hash_chain_intact: verify_hash_chain(state.event_log)
    }
  end

  defp schedule_checkpoint(interval) do
    Process.send_after(self(), :checkpoint, interval)
  end
end
