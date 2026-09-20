defmodule Tiannara.CEL.Services.EventBus do
  use Tiannara.ExecutiveService.Base
  use GenServer
  require Logger

  alias Tiannara.CEL.Services.EventStore
  alias Tiannara.CEL.Models.CivilizationalEvent

  @max_retries 3
  @dlq_table_name :cel_event_bus_dlq

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def publish(topic, payload, opts \\ []) do
    GenServer.call(__MODULE__, {:publish, topic, payload, opts})
  end

  def subscribe(topic, handler_pid \\ self()) do
    GenServer.call(__MODULE__, {:subscribe, topic, handler_pid})
  end

  def unsubscribe(topic, handler_pid) do
    GenServer.call(__MODULE__, {:unsubscribe, topic, handler_pid})
  end

  def replay(topic, since_offset \\ 0) do
    GenServer.call(__MODULE__, {:replay, topic, since_offset})
  end

  def dlq_size, do: GenServer.call(__MODULE__, :dlq_size)
  def retry_dlq, do: GenServer.call(__MODULE__, :retry_dlq)
  def healthy?, do: GenServer.call(__MODULE__, :healthy)

  @impl true
  def id, do: :executive_service_bus

  @impl true
  def version, do: "2.0.0"

  @impl true
  def capabilities, do: [:event_transport, :command_routing, :observation_broadcast, :durable_replay, :dead_letter_queue,
    :durable_delivery, :replay, :dead_letter_handling]

  @impl true
  def dependencies, do: [:event_store]

  @impl true
  def health do
    case :dets.info(@dlq_table_name) do
      info when is_list(info) -> :healthy
      _ -> :unhealthy
    end
  end

  @impl true
  def constitutional_score do
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :executive_service_bus,
      health: 1.0,
      constitutional_alignment: 0.95,
      transparency: 0.9,
      explainability: 0.85,
      evidence_quality: 0.9,
      human_oversight: 0.75,
      computed_at: DateTime.utc_now()
    }
  end

  @impl true
  def init(_opts) do
    case :dets.open_file(@dlq_table_name, type: :set, file: ~c"./cel_event_bus_dlq.dets") do
      {:ok, _table} ->
        state = %{subscribers: %{}, processed_count: 0, dlq_count: 0}
        Logger.info("EventBus v2: Durable event bus initialized")
        {:ok, state}

      {:error, reason} ->
        Logger.error("EventBus v2: Failed to open DLQ DETS: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:publish, topic, payload, opts}, _from, state) do
    civ_event = normalize(topic, payload, opts)

    case EventStore.append(topic, civ_event) do
      {:ok, offset} ->
        civ_event = %{civ_event | routing_destination: topic}
        backpressure = Keyword.get(opts, :backpressure, false)
        subs = Map.get(state.subscribers, topic, MapSet.new()) |> MapSet.to_list()
        result = deliver(subs, civ_event, backpressure)

        if result == :failed do
          dlq_event = %{civ_event: civ_event, topic: topic, origin: payload, failed_at: DateTime.utc_now(), retries: 0}
          enqueue_dlq(dlq_event)
          Logger.warning("EventBus: Event #{civ_event.id} sent to DLQ (topic: #{topic})")
          {:reply, {:delayed, :dlq, civ_event.id, offset}, %{state | dlq_count: state.dlq_count + 1}}
        else
          new_state = %{state | processed_count: state.processed_count + 1}
          :telemetry.execute([:tiannara, :cel, :event_bus, :published], %{count: 1}, %{topic: topic, origin: payload})
          {:reply, {:ok, civ_event.id, offset}, new_state}
        end

      {:error, reason} ->
        Logger.error("EventBus: EventStore append failed: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:subscribe, topic, pid}, _from, state) do
    subs = Map.get(state.subscribers, topic, MapSet.new())
    {:reply, :ok, put_in(state, [:subscribers, topic], MapSet.put(subs, pid))}
  end

  @impl true
  def handle_call({:unsubscribe, topic, pid}, _from, state) do
    subs = Map.get(state.subscribers, topic, MapSet.new())
    {:reply, :ok, put_in(state, [:subscribers, topic], MapSet.delete(subs, pid))}
  end

  @impl true
  def handle_call({:replay, topic, since_offset}, _from, state) do
    events = EventStore.read_since(topic, since_offset)
    subs = Map.get(state.subscribers, topic, MapSet.new()) |> MapSet.to_list()
    Enum.each(events, fn {_offset, event, _ts} ->
      deliver(subs, event, false)
    end)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:dlq_size, _from, state) do
    size =
      :dets.traverse(@dlq_table_name, fn {_id, _ev} -> {:continue, 1} end)
      |> Enum.sum()
    {:reply, size, state}
  end

  @impl true
  def handle_call(:retry_dlq, _from, state) do
    dlq_events =
      :dets.traverse(@dlq_table_name, fn {id, ev} -> {:continue, {id, ev}} end)

    new_dlq =
      Enum.reduce(dlq_events, 0, fn {id, dlq_event}, failed_count ->
        subs = Map.get(state.subscribers, dlq_event.topic, MapSet.new()) |> MapSet.to_list()
        case retry_one(dlq_event, subs) do
          :ok ->
            :dets.delete(@dlq_table_name, id)
            failed_count
          :permanent_failure ->
            Logger.error("EventBus DLQ: Permanent failure for event #{dlq_event.civ_event.id}")
            failed_count + 1
          :retry ->
            update_dlq_retry(id, dlq_event)
            failed_count + 1
        end
      end)

    {:reply, %{retried: length(dlq_events), remaining: new_dlq}, state}
  end

  @impl true
  def handle_call(:healthy, _from, state) do
    dlq_ok =
      case :dets.info(@dlq_table_name) do
        info when is_list(info) -> true
        _ -> false
      end

    store_ok =
      try do
        EventStore.healthy?()
      rescue
        _ -> false
      end

    {:reply, dlq_ok and store_ok, state}
  end

  defp normalize(topic, payload, opts) do
    %CivilizationalEvent{
      id: generate_id(),
      origin: payload,
      type: infer_event_type(payload),
      raw_payload: payload,
      mission_id: Keyword.get(opts, :mission_id),
      evidence: Map.get(payload, :evidence, 0.5),
      confidence: Map.get(payload, :confidence, 0.5),
      urgency: Map.get(payload, :urgency, :medium),
      impact: Map.get(payload, :impact, 0.5),
      risk: Map.get(payload, :risk, 0.0),
      resource_cost: Map.get(payload, :resource_cost, 0.0),
      timestamp: DateTime.utc_now(),
      affected_domains: Keyword.get(opts, :affected_domains, []),
      related_entities: Keyword.get(opts, :related_entities, []),
      dependencies: Keyword.get(opts, :dependencies, []),
      lineage: Keyword.get(opts, :lineage, [])
    }
  end

  defp infer_event_type(%{__struct__: Tiannara.Agency.Models.AgencyEvent}), do: :investigate
  defp infer_event_type(%{__struct__: Tiannara.Sentinel.Activation.Event}), do: :detect
  defp infer_event_type(_), do: :generic

  defp infer_topic(:investigate), do: :agency
  defp infer_topic(:detect), do: :sentinel
  defp infer_topic(:generic), do: :generic
  defp infer_topic(type), do: type

  defp deliver(subs, event, backpressure) do
    if backpressure do
      results = Enum.map(subs, fn pid -> safe_send(pid, {:event, event}, 5_000) end)
      if Enum.all?(results, &(&1 == :ok)), do: :ok, else: :failed
    else
      Enum.each(subs, fn pid -> send(pid, {:event, event}) end)
      :ok
    end
  end

  @impl true
  def handle_call({:subscribers_for, topic}, _from, state) do
    {:reply, Map.get(state.subscribers, topic, MapSet.new()) |> MapSet.to_list(), state}
  end

  defp safe_send(pid, msg, timeout) do
    case Process.info(pid, :status) do
      {:status, :alive} ->
        send(pid, msg)
        :ok
      _ ->
        :failed
    end
  rescue
    _ -> :failed
  end

  defp enqueue_dlq(dlq_event) do
    id = "dlq_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
    :dets.insert(@dlq_table_name, {id, dlq_event})
  end

  defp retry_one(%{civ_event: civ_event, topic: topic, retries: retries} = dlq, subs) do
    if retries >= @max_retries do
      :permanent_failure
    else
      case deliver(subs, civ_event, false) do
        :ok -> :ok
        _ ->
          :retry
      end
    end
  end

  defp update_dlq_retry(id, dlq_event) do
    updated = %{dlq_event | retries: dlq_event.retries + 1, last_retry: DateTime.utc_now()}
    :dets.insert(@dlq_table_name, {id, updated})
  end

  defp generate_id, do: "evt_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
end
