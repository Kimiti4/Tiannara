defmodule ReplayStore.TimelineIndex do
  use GenServer

  @jump_targets [
    :checkpoint,
    :discovery,
    :experiment,
    :certification,
    :restart,
    :theory_creation,
    :deployment,
    :milestone
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_jump(target_type, domain, reference) do
    GenServer.cast(__MODULE__, {:record, target_type, domain, reference})
  end

  def find_jump(target_type, domain, opts \\ []) do
    GenServer.call(__MODULE__, {:find, target_type, domain, opts})
  end

  def list_jumps(domain, limit \\ 100) do
    GenServer.call(__MODULE__, {:list, domain, limit})
  end

  def nearest_jump(target_type, domain, timestamp) do
    GenServer.call(__MODULE__, {:nearest, target_type, domain, timestamp})
  end

  def available_targets do
    GenServer.call(__MODULE__, :targets)
  end

  @impl true
  def init(_opts) do
    {:ok, %{jumps: %{}, domain_index: %{}, total: 0}}
  end

  @impl true
  def handle_cast(
        {:record, target_type, domain, reference},
        %{jumps: j, domain_index: di, total: t} = state
      ) do
    entry = %{
      id: Ecto.UUID.generate(),
      type: target_type,
      domain: domain,
      reference: reference,
      timestamp: DateTime.utc_now(),
      generation: reference[:generation] || reference["generation"]
    }

    key = {target_type, domain}
    existing = Map.get(j, key, [])
    domain_entries = Map.get(di, domain, [])

    {:noreply,
     %{
       state
       | jumps: Map.put(j, key, [entry | existing]),
         domain_index: Map.put(di, domain, [entry | domain_entries]),
         total: t + 1
     }}
  end

  @impl true
  def handle_call({:find, target_type, domain, opts}, _from, %{jumps: j} = state) do
    entries = Map.get(j, {target_type, domain}, [])
    result = maybe_filter(entries, opts)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:list, domain, limit}, _from, %{domain_index: di} = state) do
    entries = Map.get(di, domain, []) |> Enum.take(limit)
    {:reply, entries, state}
  end

  @impl true
  def handle_call({:nearest, target_type, domain, timestamp}, _from, %{jumps: j} = state) do
    entries = Map.get(j, {target_type, domain}, [])

    nearest =
      Enum.min_by(entries, fn e ->
        ref_ts = e.reference[:timestamp] || e.reference["timestamp"] || DateTime.utc_now()
        abs(DateTime.diff(ref_ts, timestamp, :millisecond))
      end)

    {:reply, nearest, state}
  end

  @impl true
  def handle_call(:targets, _from, state) do
    {:reply, @jump_targets, state}
  end

  defp maybe_filter(entries, opts) do
    entries
    |> maybe_filter_since(opts[:since])
    |> maybe_filter_before(opts[:before])
    |> Enum.take(opts[:limit] || 100)
  end

  defp maybe_filter_since(entries, nil), do: entries

  defp maybe_filter_since(entries, since) do
    Enum.filter(entries, fn e ->
      ref_ts = e.reference[:timestamp] || e.reference["timestamp"] || DateTime.utc_now()
      DateTime.compare(ref_ts, since) != :lt
    end)
  end

  defp maybe_filter_before(entries, nil), do: entries

  defp maybe_filter_before(entries, before) do
    Enum.filter(entries, fn e ->
      ref_ts = e.reference[:timestamp] || e.reference["timestamp"] || DateTime.utc_now()
      DateTime.compare(ref_ts, before) != :gt
    end)
  end
end
