defmodule ReplayStore.ReplayEngine do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def replay_deterministic(target_timestamp, domains \\ :all) do
    GenServer.call(__MODULE__, {:replay, :deterministic, target_timestamp, domains})
  end

  def replay_fast_forward(target_timestamp, domains \\ :all) do
    GenServer.call(__MODULE__, {:replay, :fast_forward, target_timestamp, domains})
  end

  def replay_frame_by_frame(target_timestamp, frame_size_ms \\ 1000) do
    GenServer.call(__MODULE__, {:replay, :frame_by_frame, target_timestamp, frame_size_ms})
  end

  def replay_comparative(timestamp_a, timestamp_b, domains \\ :all) do
    GenServer.call(__MODULE__, {:replay, :comparative, {timestamp_a, timestamp_b}, domains})
  end

  def replay_streaming(start_timestamp, batch_size \\ 100) do
    GenServer.call(__MODULE__, {:replay, :streaming, start_timestamp, batch_size})
  end

  def replay_to_event(event_id) do
    GenServer.call(__MODULE__, {:replay_to_event, event_id})
  end

  @impl true
  def init(_opts) do
    {:ok, %{replays: %{}, active_sessions: %{}}}
  end

  @impl true
  def handle_call({:replay, :deterministic, target_ts, domains}, _from, state) do
    result = reconstruct_at(target_ts, domains)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:replay, :fast_forward, target_ts, domains}, _from, state) do
    result = reconstruct_at(target_ts, domains)
    {:reply, Map.put(result, :mode, :fast_forward), state}
  end

  @impl true
  def handle_call({:replay, :frame_by_frame, target_ts, frame_ms}, _from, state) do
    frames = generate_frames(target_ts, frame_ms)

    {:reply,
     %{
       mode: :frame_by_frame,
       frames: frames,
       total_frames: length(frames),
       frame_interval_ms: frame_ms
     }, state}
  end

  @impl true
  def handle_call({:replay, :comparative, {ts_a, ts_b}, domains}, _from, state) do
    state_a = reconstruct_at(ts_a, domains)
    state_b = reconstruct_at(ts_b, domains)
    diff = compute_diff(state_a, state_b)

    {:reply,
     %{
       mode: :comparative,
       timestamp_a: ts_a,
       timestamp_b: ts_b,
       state_a: state_a,
       state_b: state_b,
       diff: diff
     }, state}
  end

  @impl true
  def handle_call({:replay, :streaming, start_ts, batch_size}, _from, state) do
    session_id = Ecto.UUID.generate()
    batch = stream_batch(start_ts, batch_size)
    session = %{id: session_id, cursor: start_ts, batch_size: batch_size, mode: :streaming}

    {:reply,
     %{
       mode: :streaming,
       session_id: session_id,
       batch: batch,
       has_more: length(batch) == batch_size
     }, %{state | active_sessions: Map.put(state.active_sessions, session_id, session)}}
  end

  @impl true
  def handle_call({:replay_to_event, event_id}, _from, state) do
    event = EventStore.Reader.get(event_id)

    case event do
      nil ->
        {:reply, {:error, :event_not_found}, state}

      event ->
        ts = event.timestamp
        result = reconstruct_at(ts, :all)
        {:reply, Map.put(result, :target_event_id, event_id), state}
    end
  end

  defp reconstruct_at(timestamp, domains) do
    events =
      EventStore.Reader.list_by_time_range(
        ~U[2020-01-01 00:00:00Z],
        timestamp
      )

    filtered =
      if domains == :all, do: events, else: Enum.filter(events, fn e -> e.domain in domains end)

    state =
      Enum.reduce(filtered, %{}, fn e, acc ->
        domain_key = String.to_atom(e.domain)
        Map.put(acc, domain_key, e)
      end)

    %{
      timestamp: timestamp,
      domains: Map.keys(state),
      event_count: length(filtered),
      total_events_processed: length(filtered),
      reconstructed_state: state
    }
  end

  defp generate_frames(target_ts, frame_ms) do
    start = ~U[2020-01-01 00:00:00Z]
    duration = DateTime.diff(target_ts, start, :millisecond)
    frame_count = div(max(duration, 1), max(frame_ms, 1)) + 1

    Enum.map(0..min(frame_count, 1000), fn i ->
      frame_ts = DateTime.add(start, i * frame_ms, :millisecond)
      frame_ts = if DateTime.compare(frame_ts, target_ts) == :gt, do: target_ts, else: frame_ts
      state = reconstruct_at(frame_ts, :all)
      %{frame: i, timestamp: frame_ts, event_count: state.event_count, domains: state.domains}
    end)
  end

  defp compute_diff(state_a, state_b) do
    keys_a = MapSet.new(Map.keys(state_a[:reconstructed_state] || %{}))
    keys_b = MapSet.new(Map.keys(state_b[:reconstructed_state] || %{}))

    %{
      added: MapSet.difference(keys_b, keys_a) |> MapSet.to_list(),
      removed: MapSet.difference(keys_a, keys_b) |> MapSet.to_list(),
      common: MapSet.intersection(keys_a, keys_b) |> MapSet.to_list(),
      events_a: state_a[:event_count] || 0,
      events_b: state_b[:event_count] || 0,
      delta: (state_b[:event_count] || 0) - (state_a[:event_count] || 0)
    }
  end

  defp stream_batch(cursor, batch_size) do
    events = EventStore.Reader.list_by_time_range(cursor, DateTime.utc_now(), limit: batch_size)
    events
  end
end
