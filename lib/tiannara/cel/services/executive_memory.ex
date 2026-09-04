defmodule Tiannara.CEL.Services.ExecutiveMemory do
  use Tiannara.ExecutiveService.Base
  use GenServer
  require Logger

  alias Tiannara.CEL.Services.EventStore

  @snapshot_interval 50
  @table_name :cel_memory_v2

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def record_event(event_type, payload), do: record_event(event_type, payload, %{})

  def record_event(category, action, payload, metadata) do
    record_event(category, %{action: action, payload: payload, metadata: metadata})
  end

  def record_event(event_type, payload, metadata) do
    GenServer.call(__MODULE__, {:record, event_type, payload, metadata})
  end

  def record_decision(decision_id, event_type, payload, metadata \\ %{}) do
    record_event(event_type, payload, Map.put(metadata, :correlation_id, decision_id))
  end

  def get_lineage(correlation_id) do
    GenServer.call(__MODULE__, {:lineage, correlation_id})
  end

  def find_lessons(tags) when is_list(tags) do
    GenServer.call(__MODULE__, {:find_lessons, tags})
  end

  def find_lessons(tag) do
    find_lessons([tag])
  end

  def snapshot, do: GenServer.call(__MODULE__, :snapshot)
  def replay_since(offset), do: GenServer.call(__MODULE__, {:replay, offset})
  def count, do: GenServer.call(__MODULE__, :count)

  @impl true
  def id, do: :executive_memory

  @impl true
  def version, do: "2.0.0"

  @impl true
  def capabilities, do: [:persistent_memory, :decision_history, :institutional_knowledge, :event_sourced_lineage]

  @impl true
  def dependencies, do: [:event_store]

  @impl true
  def health do
    case :dets.info(@table_name) do
      info when is_list(info) -> :healthy
      _ -> :unhealthy
    end
  end

  @impl true
  def constitutional_score do
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :executive_memory,
      health: 1.0,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 0.95,
      human_oversight: 0.85,
      computed_at: DateTime.utc_now()
    }
  end

  @impl true
  def init(_opts) do
    case :dets.open_file(@table_name, type: :set, file: ~c"./cel_memory_v2.dets") do
      {:ok, _table} ->
        state = %{event_count: 0, last_snapshot: nil, snapshot_offset: 0, backend: :dets, status: :healthy}
        Logger.info("ExecutiveMemory v2: Event-sourced memory initialized")
        {:ok, state}

      {:error, reason} ->
        Logger.warning("ExecutiveMemory v2: DETS failed (#{inspect(reason)}). Falling back to volatile ETS.")
        ref = :ets.new(:executive_memory_fallback, [:set, :public])
        :telemetry.execute(
          [:tiannara, :cel, :executive_memory, :degraded],
          %{count: 1},
          %{service: __MODULE__, reason: {:dets_open_failed, reason}, fallback: :ets, impact: :volatile_memory_only}
        )
        {:ok, %{event_count: 0, last_snapshot: nil, snapshot_offset: 0, backend: :ets, ets_ref: ref, status: :degraded, original_path: ~c"./cel_memory_v2.dets"}}
    end
  end

  @impl true
  def handle_call({:record, event_type, payload, metadata}, _from, state) do
    event = %{
      id: generate_id(),
      event_type: event_type,
      payload: payload,
      metadata: metadata,
      correlation_id: Map.get(metadata, :correlation_id, generate_id()),
      timestamp: DateTime.utc_now()
    }

    case EventStore.append(:executive_memory, event) do
      {:ok, offset} ->
        store_index(event, offset)
        new_count = state.event_count + 1
        new_state = maybe_snapshot(%{state | event_count: new_count}, new_count, event)
        :telemetry.execute([:tiannara, :cel, :memory, :recorded], %{count: 1}, %{event_type: event_type})
        {:reply, {:ok, event.id}, new_state}

      {:error, reason} ->
        Logger.error("ExecutiveMemory: EventStore append failed: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:lineage, correlation_id}, _from, state) do
    result =
      try do
        :dets.foldl(fn
          {_event_id, %{correlation_id: cid} = ev, _offset}, acc when cid == correlation_id -> [ev | acc]
          _, acc -> acc
        end, [], @table_name)
      catch
        _, _ -> {:error, :lineage_unavailable}
      end

    case result do
      {:error, _} -> {:reply, {:error, :lineage_unavailable}, state}
      events when is_list(events) ->
        sorted = Enum.sort_by(events, fn e -> e.timestamp end)
        {:reply, sorted, state}
      _ -> {:reply, {:error, :lineage_unavailable}, state}
    end
  end

  @impl true
  def handle_call({:find_lessons, tags}, _from, state) do
    result =
      try do
        :dets.foldl(fn
          {_event_id, %{event_type: :lesson, payload: %{tags: t}} = ev, _offset}, acc ->
            if Enum.any?(tags, &(&1 in t)) do
              [ev | acc]
            else
              acc
            end
          _, acc -> acc
        end, [], @table_name)
      catch
        _, _ -> {:error, :lineage_unavailable}
      end

    case result do
      {:error, _} -> {:reply, {:error, :lineage_unavailable}, state}
      results when is_list(results) -> {:reply, results, state}
      _ -> {:reply, {:error, :lineage_unavailable}, state}
    end
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    snapshot = build_snapshot()
    {:reply, snapshot, state}
  end

  @impl true
  def handle_call({:replay, since_offset}, _from, state) do
    events = EventStore.read_since(:executive_memory, since_offset)
    {:reply, events, state}
  end

  @impl true
  def handle_call(:count, _from, state) do
    {:reply, state.event_count, state}
  end

  defp store_index(event, offset) do
    :dets.insert(@table_name, {event.id, event, offset})
  end

  defp maybe_snapshot(state, count, event) when rem(count, @snapshot_interval) == 0 do
    Logger.info("ExecutiveMemory: Taking snapshot at event #{count}")
    emit_constitutional_event(:memory_snapshot, %{event_count: count, last_event: event.id})
    %{state | last_snapshot: event, snapshot_offset: count}
  end

  defp maybe_snapshot(state, _count, _event), do: state

  defp build_snapshot do
    events =
      :dets.traverse(@table_name, fn
        {_id, ev, _offset} -> {:continue, ev}
      end)
    %{
      total_events: length(events),
      snapshot_at: DateTime.utc_now(),
      recent_events: Enum.take(Enum.sort_by(events, & &1.timestamp, :desc), 100)
    }
  end

  defp generate_id, do: "mem_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
end
