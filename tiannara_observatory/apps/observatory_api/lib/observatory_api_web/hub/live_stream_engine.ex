defmodule ObservatoryApiWeb.Hub.LiveStreamEngine do
  use GenServer

  @topics [
    :runtime,
    :science,
    :engineering,
    :knowledge,
    :ontology,
    :planetary,
    :civilization,
    :certification,
    :replay,
    :alerts,
    :mission,
    :experiments,
    :theories,
    :discovery
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def stream(topic, event) do
    GenServer.cast(__MODULE__, {:stream, topic, event})
  end

  def subscribe(topic, pid) do
    GenServer.cast(__MODULE__, {:subscribe, topic, pid})
  end

  def unsubscribe(topic, pid) do
    GenServer.cast(__MODULE__, {:unsubscribe, topic, pid})
  end

  def topic_stats do
    GenServer.call(__MODULE__, :topic_stats)
  end

  def available_topics do
    GenServer.call(__MODULE__, :topics)
  end

  @impl true
  def init(_opts) do
    topic_state =
      Map.new(@topics, fn t ->
        {t,
         %{
           subscribers: [],
           aggregator: %{batch: [], last_flush: System.system_time(:millisecond)}
         }}
      end)

    {:ok, %{topics: topic_state, streamed: 0, aggregated: 0}}
  end

  @impl true
  def handle_cast({:stream, topic, event}, %{topics: tops, streamed: s} = state) do
    case Map.get(tops, topic) do
      nil ->
        {:noreply, state}

      %{subscribers: subs, aggregator: agg} = ts ->
        batch = [event | agg.batch]
        now = System.system_time(:millisecond)

        {to_flush, updated_agg} =
          if length(batch) >= 100 or now - agg.last_flush >= 5000 do
            flushed = %{
              topic: topic,
              events: Enum.reverse(batch),
              count: length(batch),
              timestamp: DateTime.utc_now(),
              aggregated: true
            }

            Enum.each(subs, fn pid ->
              if Process.alive?(pid) do
                send(pid, {:stream_batch, flushed})
              end
            end)

            {length(batch), %{batch: [], last_flush: now}}
          else
            {0, %{batch: batch, last_flush: agg.last_flush}}
          end

        {:noreply,
         %{
           state
           | topics: Map.put(tops, topic, %{ts | aggregator: updated_agg}),
             streamed: s + 1,
             aggregated: state.aggregated + to_flush
         }}
    end
  end

  @impl true
  def handle_cast({:subscribe, topic, pid}, %{topics: tops} = state) do
    case Map.get(tops, topic) do
      nil ->
        {:noreply, state}

      %{subscribers: subs} = ts ->
        new_subs = if pid in subs, do: subs, else: [pid | subs]
        {:noreply, %{state | topics: Map.put(tops, topic, %{ts | subscribers: new_subs})}}
    end
  end

  @impl true
  def handle_cast({:unsubscribe, topic, pid}, %{topics: tops} = state) do
    case Map.get(tops, topic) do
      nil ->
        {:noreply, state}

      %{subscribers: subs} = ts ->
        {:noreply, %{state | topics: Map.put(tops, topic, %{ts | subscribers: subs -- [pid]})}}
    end
  end

  @impl true
  def handle_call(:topic_stats, _from, %{topics: tops} = state) do
    stats =
      Map.new(tops, fn {t, %{subscribers: subs, aggregator: agg}} ->
        {t, %{subscribers: length(subs), batched: length(agg.batch)}}
      end)

    {:reply, stats, state}
  end

  @impl true
  def handle_call(:topics, _from, state) do
    {:reply, @topics, state}
  end
end
