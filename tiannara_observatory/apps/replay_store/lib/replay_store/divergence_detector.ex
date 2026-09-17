defmodule ReplayStore.DivergenceDetector do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def compare_replay(replay_result, domain) do
    GenServer.call(__MODULE__, {:compare, replay_result, domain})
  end

  def check_integrity(domain) do
    GenServer.call(__MODULE__, {:integrity, domain})
  end

  def divergence_report do
    GenServer.call(__MODULE__, :report)
  end

  @impl true
  def init(_opts) do
    {:ok, %{checks: %{}, divergence_count: 0, last_check: nil}}
  end

  @impl true
  def handle_call({:compare, replay_result, domain}, _from, state) do
    replayed_state = replay_result[:reconstructed_state] || %{}
    replayed_events = replay_result[:event_count] || 0

    snapshot_domain = String.to_existing_atom(domain)

    ets_mirror =
      case :ets.info(snapshot_domain) do
        :undefined ->
          %{}

        _ ->
          :ets.tab2list(snapshot_domain)
          |> Map.new()
      end

    replay_keys = MapSet.new(Map.keys(replayed_state))
    ets_keys = MapSet.new(Map.keys(ets_mirror))

    added = MapSet.difference(replay_keys, ets_keys) |> MapSet.to_list()
    removed = MapSet.difference(ets_keys, replay_keys) |> MapSet.to_list()
    common = MapSet.intersection(replay_keys, ets_keys) |> MapSet.to_list()

    value_mismatches =
      Enum.filter(common, fn k ->
        replayed_state[k] != Map.get(ets_mirror, k)
      end)

    divergent = added != [] or removed != [] or value_mismatches != []

    check = %{
      domain: domain,
      timestamp: DateTime.utc_now(),
      replay_events: replayed_events,
      replay_keys: MapSet.size(replay_keys),
      ets_keys: MapSet.size(ets_keys),
      added: added,
      removed: removed,
      value_mismatches: value_mismatches,
      divergent: divergent
    }

    if divergent do
      :telemetry.execute([:observatory, :divergence, :detected], %{count: 1}, %{domain: domain})
    end

    {:reply, check,
     %{
       state
       | checks: Map.put(state.checks, domain, check),
         divergence_count:
           if(divergent, do: state.divergence_count + 1, else: state.divergence_count),
         last_check: DateTime.utc_now()
     }}
  end

  @impl true
  def handle_call({:integrity, domain}, _from, state) do
    snapshots = ReplayStore.SnapshotManager.list_by_domain(domain)

    results =
      Enum.map(snapshots, fn s ->
        ReplayStore.SnapshotManager.verify(s.id)
      end)

    all_valid = Enum.all?(results, fn r -> r.valid end)

    {:reply,
     %{
       domain: domain,
       snapshots_checked: length(results),
       all_valid: all_valid,
       results: results
     }, state}
  end

  @impl true
  def handle_call(:report, _from, state) do
    {:reply,
     %{
       total_checks: map_size(state.checks),
       divergences: state.divergence_count,
       last_check: state.last_check,
       checks: state.checks
     }, state}
  end
end
