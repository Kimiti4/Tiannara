defmodule Tiannara.Sentinel.Event do
  @moduledoc """
  A structured epistemic event — the core unit of meaning in the Sentinel
  Activation Layer. Converts raw observations into actionable intelligence.
  """

  defstruct [
    :id, :timestamp, :source, :category, :severity,
    :observation, :interpretation, :confidence,
    evidence: [],
    causal_links: [],
    recommended_actions: [],
    requires_human: false,
    metadata: %{}
  ]

  @type category :: :runtime | :scientific | :constitutional | :security | :discovery
  @type severity :: :info | :warning | :critical
  @type t :: %__MODULE__{
    id: String.t(),
    timestamp: DateTime.t(),
    source: atom(),
    category: category(),
    severity: severity(),
    observation: String.t(),
    interpretation: String.t(),
    confidence: float(),
    evidence: list(map()),
    causal_links: list(String.t()),
    recommended_actions: list(map()),
    requires_human: boolean(),
    metadata: map()
  }

  def new(source, category, severity, observation, opts \\ []) do
    %__MODULE__{
      id: "evt_#{System.unique_integer([:positive])}",
      timestamp: DateTime.utc_now(),
      source: source,
      category: category,
      severity: severity,
      observation: observation,
      interpretation: Map.get(opts, :interpretation, "Pending interpretation"),
      confidence: Map.get(opts, :confidence, 0.5),
      evidence: Map.get(opts, :evidence, []),
      causal_links: Map.get(opts, :causal_links, []),
      recommended_actions: Map.get(opts, :recommended_actions, []),
      requires_human: Map.get(opts, :requires_human, severity == :critical),
      metadata: Map.get(opts, :metadata, %{})
    }
  end
end

defmodule Tiannara.Sentinel.Events do
  @moduledoc """
  Sentinel Event Store — records, queries, and manages the lifecycle of
  structured epistemic events generated from Sentinel observations.

  Converts "metric changed" into "meaningful state transition detected."
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.Event

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Records a new epistemic event. Returns the event ID.
  """
  def record(source, category, severity, observation, opts \\ []) do
    event = Event.new(source, category, severity, observation, opts)
    GenServer.cast(__MODULE__, {:record, event})
    event.id
  end

  @doc """
  Records a pre-constructed Event struct.
  """
  def record_event(%Event{} = event) do
    GenServer.cast(__MODULE__, {:record, event})
    event.id
  end

  @doc """
  Retrieves an event by ID.
  """
  def get(event_id) do
    GenServer.call(__MODULE__, {:get, event_id})
  end

  @doc """
  Queries events by filter criteria.
  """
  def query(filters \\ []) do
    GenServer.call(__MODULE__, {:query, filters})
  end

  @doc """
  Returns events pending human attention.
  """
  def pending_human_attention do
    GenServer.call(__MODULE__, :pending_human)
  end

  @doc """
  Returns recent events within a time window.
  """
  def recent(minutes \\ 60) do
    GenServer.call(__MODULE__, {:recent, minutes})
  end

  @doc """
  Returns events by category.
  """
  def by_category(category) do
    GenServer.call(__MODULE__, {:by_category, category})
  end

  @doc """
  Returns event statistics.
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @doc """
  Marks an event as acknowledged by a human.
  """
  def acknowledge(event_id, response \\ nil) do
    GenServer.cast(__MODULE__, {:acknowledge, event_id, response})
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    :ets.new(:sentinel_events, [:set, :public, :named_table])
    Logger.info("[EVENTS] Sentinel Event System initialized.")
    {:ok, %{table: :sentinel_events}}
  end

  @impl true
  def handle_cast({:record, %Event{} = event}, state) do
    :ets.insert(state.table, {event.id, event, :unacknowledged, nil})
    Logger.info("[EVENTS] #{event.category}/#{event.severity}: #{event.observation}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:acknowledge, event_id, response}, state) do
    case :ets.lookup(state.table, event_id) do
      [{id, event, _status, _prev}] ->
        :ets.insert(state.table, {id, event, :acknowledged, response})
      _ -> :ok
    end
    {:noreply, state}
  end

  @impl true
  def handle_call({:get, event_id}, _from, state) do
    result = case :ets.lookup(state.table, event_id) do
      [{_id, event, status, response}] ->
        %{event: event, status: status, human_response: response}
      [] -> {:error, :not_found}
    end
    {:reply, result, state}
  end

  @impl true
  def handle_call({:query, filters}, _from, state) do
    results = filter_events(:ets.tab2list(state.table), filters)
    {:reply, results, state}
  end

  @impl true
  def handle_call(:pending_human, _from, state) do
    results = :ets.tab2list(state.table)
    |> Enum.filter(fn {_id, ev, status, _resp} -> ev.requires_human and status == :unacknowledged end)
    |> Enum.map(fn {_id, ev, status, resp} -> %{event: ev, status: status, human_response: resp} end)
    |> Enum.sort_by(fn %{event: ev} -> ev.timestamp end, :desc)
    {:reply, results, state}
  end

  @impl true
  def handle_call({:recent, minutes}, _from, state) do
    cutoff = DateTime.add(DateTime.utc_now(), -minutes * 60, :second)
    results = :ets.tab2list(state.table)
    |> Enum.filter(fn {_id, ev, _status, _resp} -> DateTime.compare(ev.timestamp, cutoff) != :lt end)
    |> Enum.map(fn {_id, ev, status, resp} -> %{event: ev, status: status, human_response: resp} end)
    |> Enum.sort_by(fn %{event: ev} -> ev.timestamp end, :desc)
    {:reply, results, state}
  end

  @impl true
  def handle_call({:by_category, category}, _from, state) do
    results = :ets.tab2list(state.table)
    |> Enum.filter(fn {_id, ev, _status, _resp} -> ev.category == category end)
    |> Enum.map(fn {_id, ev, status, resp} -> %{event: ev, status: status, human_response: resp} end)
    |> Enum.sort_by(fn %{event: ev} -> ev.timestamp end, :desc)
    {:reply, results, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    all = :ets.tab2list(state.table)
    total = length(all)
    by_category = all |> Enum.group_by(fn {_id, ev, _s, _r} -> ev.category end) |> Map.map(fn _k, v -> length(v) end)
    by_severity = all |> Enum.group_by(fn {_id, ev, _s, _r} -> ev.severity end) |> Map.map(fn _k, v -> length(v) end)
    unacknowledged = Enum.count(all, fn {_id, _ev, status, _r} -> status == :unacknowledged end)

    {:reply, %{
      total: total,
      by_category: by_category,
      by_severity: by_severity,
      unacknowledged: unacknowledged,
      pending_human: Enum.count(all, fn {_id, ev, s, _r} -> ev.requires_human and s == :unacknowledged end)
    }, state}
  end

  defp filter_events(entries, filters) do
    entries
    |> Enum.reduce(entries, fn
      {:category, cat}, acc -> Enum.filter(acc, fn {_id, ev, _, _} -> ev.category == cat end)
      {:severity, sev}, acc -> Enum.filter(acc, fn {_id, ev, _, _} -> ev.severity == sev end)
      {:source, src}, acc -> Enum.filter(acc, fn {_id, ev, _, _} -> ev.source == src end)
      {:status, st}, acc -> Enum.filter(acc, fn {_id, _, s, _} -> s == st end)
      {:min_confidence, mc}, acc -> Enum.filter(acc, fn {_id, ev, _, _} -> ev.confidence >= mc end)
      _, acc -> acc
    end)
    |> Enum.map(fn {_id, ev, status, resp} -> %{event: ev, status: status, human_response: resp} end)
    |> Enum.sort_by(fn %{event: ev} -> ev.timestamp end, :desc)
  end
end
