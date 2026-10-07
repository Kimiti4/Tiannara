defmodule Tiannara.CEL.Services.EventStore do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  @table :cel_event_store

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def append(topic, event), do: GenServer.call(__MODULE__, {:append, topic, event})
  def read_topic(topic), do: GenServer.call(__MODULE__, {:read, topic})
  def read_since(topic, offset), do: GenServer.call(__MODULE__, {:read_since, topic, offset})

  def read_range(topic, from_offset, to_offset),
    do: GenServer.call(__MODULE__, {:read_range, topic, from_offset, to_offset})

  def latest_offset(topic), do: GenServer.call(__MODULE__, {:latest_offset, topic})

  def replay(topic, since_offset \\ 0),
    do: GenServer.call(__MODULE__, {:replay, topic, since_offset})

  def all_topics, do: GenServer.call(__MODULE__, :all_topics)
  def count(topic), do: GenServer.call(__MODULE__, {:count, topic})
  def healthy?, do: GenServer.call(__MODULE__, :healthy)
  def stats, do: GenServer.call(__MODULE__, :stats)
  def rotate, do: GenServer.call(__MODULE__, :rotate, 60_000)
  def prune, do: GenServer.call(__MODULE__, :prune, 60_000)

  @impl Tiannara.ExecutiveService
  def id, do: :event_store

  @impl Tiannara.ExecutiveService
  def version, do: "2.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities, do: [:durable_persistence, :replay, :offset_tracking]

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: id(),
      health: 1.0,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  @doc false
  def dets_path, do: Tiannara.Storage.Paths.dets("cel_event_store")

  @impl true
  def init(_opts) do
    File.mkdir_p!(Path.dirname(dets_path()))
    register_with_lifecycle()

    case open_dets_safely() do
      {:ok, _table} ->
        offset = load_latest_offset()
        {:ok, %{offset_counter: offset, degraded: false, degradation_reason: nil, event_count: 0}}

      {:error, reason} ->
        Logger.error(
          "EventStore: storage unavailable (#{inspect(reason)}). Starting in degraded mode."
        )

        {:ok, %{offset_counter: 0, degraded: true, degradation_reason: reason, event_count: 0}}
    end
  end

  @impl true
  def handle_call({:append, _topic, _event}, _from, %{degraded: true} = state) do
    {:reply, {:error, :storage_degraded}, state}
  end

  def handle_call({:append, topic, event}, _from, state) do
    offset = state.offset_counter + 1
    stamped = Map.put(event, :event_store_offset, offset)
    key = {topic, offset}

    case :dets.insert(@table, {key, stamped, DateTime.utc_now()}) do
      :ok ->
        :telemetry.execute([:tiannara, :cel, :event_store, :appended], %{count: 1}, %{
          topic: topic,
          offset: offset
        })

        {:reply, {:ok, offset},
         %{state | offset_counter: offset, event_count: state.event_count + 1}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:read, topic}, _from, %{degraded: true} = state) do
    {:reply, [], state}
  end

  def handle_call({:read, topic}, _from, state) do
    events = read_all(topic)
    {:reply, events, state}
  end

  @impl true
  def handle_call({:read_since, _topic, _offset}, _from, %{degraded: true} = state) do
    {:reply, [], state}
  end

  def handle_call({:read_since, topic, offset}, _from, state) do
    events = read_all(topic) |> Enum.filter(fn {o, _e, _ts} -> o > offset end)
    {:reply, events, state}
  end

  @impl true
  def handle_call({:read_range, _topic, _from, _to}, _from, %{degraded: true} = state) do
    {:reply, [], state}
  end

  def handle_call({:read_range, topic, from, to}, _from, state) do
    events = read_all(topic) |> Enum.filter(fn {o, _e, _ts} -> o >= from and o <= to end)
    {:reply, events, state}
  end

  @impl true
  def handle_call({:latest_offset, _topic}, _from, %{degraded: true} = state) do
    {:reply, 0, state}
  end

  def handle_call({:latest_offset, _topic}, _from, state) do
    {:reply, state.offset_counter, state}
  end

  @impl true
  def handle_call(:all_topics, _from, %{degraded: true} = state) do
    {:reply, [], state}
  end

  def handle_call(:all_topics, _from, state) do
    topics =
      :dets.traverse(@table, fn
        {{topic, _offset}, _event, _ts} -> {:continue, topic}
      end)
      |> Enum.uniq()

    {:reply, topics, state}
  end

  @impl true
  def handle_call({:replay, topic, since_offset}, _from, %{degraded: true} = state) do
    {:reply, {:error, :storage_degraded}, state}
  end

  def handle_call({:replay, topic, since_offset}, _from, state) do
    events = read_all(topic) |> Enum.filter(fn {o, _e, _ts} -> o > since_offset end)
    {:reply, {:ok, events}, state}
  end

  @impl true
  def handle_call({:count, _topic}, _from, %{degraded: true} = state) do
    {:reply, 0, state}
  end

  def handle_call({:count, topic}, _from, state) do
    cnt = read_all(topic) |> length()
    {:reply, cnt, state}
  end

  @impl true
  def handle_call(:healthy, _from, state) do
    if state.degraded do
      {:reply, false, state}
    else
      healthy = is_list(:dets.info(@table))
      {:reply, healthy, state}
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply,
     %{
       event_count: state.event_count,
       latest_offset: state.offset_counter,
       degraded: state.degraded,
       degradation_reason: state.degradation_reason
     }, state}
  end

  @impl true
  def handle_call(:rotate, _from, %{degraded: true} = state) do
    {:reply, {:error, :storage_degraded}, state}
  end

  def handle_call(:rotate, _from, state) do
    case Tiannara.Storage.Rotator.rotate(@table, dets_path(), type: :set) do
      {:ok, archive} ->
        offset = load_latest_offset()
        {:reply, {:ok, archive}, %{state | offset_counter: max(offset, state.offset_counter)}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:prune, _from, %{degraded: true} = state) do
    {:reply, {:error, :storage_degraded}, state}
  end

  def handle_call(:prune, _from, state) do
    cutoff =
      DateTime.utc_now()
      |> DateTime.add(-(event_retention_hours() * 3600), :second)

    stale_keys =
      :dets.traverse(@table, fn
        {{_topic, _offset} = key, _event, ts} when is_struct(ts, DateTime) ->
          if DateTime.compare(ts, cutoff) == :lt, do: {:continue, key}, else: {:continue, :skip}

        _ ->
          {:continue, :skip}
      end)
      |> Enum.reject(&(&1 == :skip))

    Enum.each(stale_keys, &:dets.delete(@table, &1))
    {:reply, {:ok, length(stale_keys)}, state}
  end

  defp open_dets_safely do
    path = String.to_charlist(dets_path())

    Tiannara.CEL.Services.ResilientDETS.open(@table,
      type: :set,
      file: path,
      repair: false
    )
  end

  defp load_latest_offset do
    case :dets.traverse(@table, fn
           {{_topic, offset}, _event, _ts} -> {:continue, offset}
         end) do
      [] -> 0
      offsets -> Enum.max(offsets)
    end
  end

  defp next_offset(topic) do
    max =
      :dets.traverse(@table, fn
        {{t, offset}, _e, _ts} when t == topic -> {:continue, offset}
        _ -> {:continue}
      end)
      |> Enum.max(fn -> 0 end)

    max + 1
  end

  defp read_all(topic) do
    :dets.traverse(@table, fn
      {{t, offset}, event, ts} when t == topic -> {:continue, {offset, event, ts}}
      _ -> {:continue}
    end)
    |> Enum.sort_by(fn {offset, _e, _ts} -> offset end)
  end

  defp register_with_lifecycle do
    _ = Tiannara.Storage.DetsLifecycle.register(%{id: id(), module: __MODULE__})
    :ok
  end

  defp event_retention_hours do
    Application.get_env(:tiannara, :dets_event_retention_hours, 168)
  end
end
