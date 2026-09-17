defmodule TiannaraRuntime.Omega.SentinelEventBus do
  @moduledoc """
  Local replayable event bus for Omega readiness.

  This bus is intentionally in-VM and independent from NATS. It gives the soak
  runtime a continuous observation path even when external messaging is absent.
  Events are also mirrored into CPL when available.
  """

  use GenServer

  alias TiannaraRuntime.Omega.SafeCPL

  @default_max_events 1_000

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec publish(atom() | String.t(), term(), map()) :: {:ok, map()} | {:error, term()}
  def publish(topic, payload, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:publish, topic, payload, metadata})
  end

  @spec subscribe(atom() | String.t()) :: :ok
  def subscribe(topic \\ :all) do
    GenServer.call(__MODULE__, {:subscribe, topic, self()})
  end

  @spec recent_events(non_neg_integer()) :: [map()]
  def recent_events(limit \\ 100) do
    GenServer.call(__MODULE__, {:recent_events, limit})
  end

  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def init(opts) do
    {:ok,
     %{
       events: [],
       event_count: 0,
       max_events: Keyword.get(opts, :max_events, @default_max_events),
       subscribers: %{},
       monitors: %{}
     }}
  end

  @impl true
  def handle_call({:subscribe, topic, pid}, _from, state) when is_pid(pid) do
    ref = Process.monitor(pid)

    subscribers =
      state.subscribers
      |> Map.update(topic, MapSet.new([pid]), &MapSet.put(&1, pid))

    monitors = Map.put(state.monitors, ref, {topic, pid})

    {:reply, :ok, %{state | subscribers: subscribers, monitors: monitors}}
  end

  @impl true
  def handle_call({:publish, topic, payload, metadata}, _from, state) do
    event = %{
      id: "omega_evt_#{System.unique_integer([:positive])}",
      topic: topic,
      payload: payload,
      metadata: metadata,
      timestamp: System.system_time(:millisecond),
      monotonic_time: System.monotonic_time(:millisecond)
    }

    SafeCPL.record_event(:sentinel_event, %{
      topic: inspect(topic),
      payload: payload,
      metadata: metadata,
      timestamp: event.timestamp
    })

    dispatch(event, state.subscribers)

    events = [event | state.events] |> Enum.take(state.max_events)
    {:reply, {:ok, event}, %{state | events: events, event_count: state.event_count + 1}}
  end

  @impl true
  def handle_call({:recent_events, limit}, _from, state) do
    {:reply, Enum.take(state.events, limit), state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    subscriber_count =
      state.subscribers
      |> Map.values()
      |> Enum.reduce(0, fn set, acc -> acc + MapSet.size(set) end)

    {:reply,
     %{
       event_count: state.event_count,
       retained_events: length(state.events),
       subscriber_count: subscriber_count
     }, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    case Map.pop(state.monitors, ref) do
      {nil, monitors} ->
        {:noreply, %{state | monitors: monitors}}

      {{topic, pid}, monitors} ->
        subscribers =
          Map.update(state.subscribers, topic, MapSet.new(), &MapSet.delete(&1, pid))

        {:noreply, %{state | subscribers: subscribers, monitors: monitors}}
    end
  end

  defp dispatch(event, subscribers) do
    subscribers
    |> matching_subscribers(event.topic)
    |> Enum.each(fn pid -> send(pid, {:tiannara_event, event}) end)
  end

  defp matching_subscribers(subscribers, topic) do
    exact = Map.get(subscribers, topic, MapSet.new())
    all = Map.get(subscribers, :all, MapSet.new())

    exact
    |> MapSet.union(all)
    |> MapSet.to_list()
  end
end
