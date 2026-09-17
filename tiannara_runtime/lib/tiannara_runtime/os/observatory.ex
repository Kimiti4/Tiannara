defmodule TiannaraRuntime.OS.Observatory do
  @moduledoc """
  Tiannara Observatory — Phase 23.0

  Scientific instrumentation system for the living organism.
  Not a dashboard. Not an admin panel.
  A laboratory-grade observatory for measuring scientific productivity,
  engineering output, constitutional integrity, and continuous evolution.

  Architecture:
  - 12 instrument screens (Phoenix LiveView)
  - Scientific metrics engine (6 categories, 50+ metrics)
  - First-class artifact storage (every event searchable)
  - Replay and archaeology integration
  - Live timeline visualization
  """

  use GenServer
  require Logger

  alias TiannaraRuntime.OS.Observatory.{
    Metrics,
    ArtifactStorage,
    Timeline,
    Screens
  }

  # ── Public API ──────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns data for a specific screen (1-12).
  """
  def get_screen_data(screen_number) when screen_number in 1..12 do
    GenServer.call(__MODULE__, {:get_screen, screen_number})
  end

  @doc """
  Returns metrics for a specific category.
  """
  def get_metrics(category) when category in [:scientific, :engineering, :cognitive, :evolution, :planetary, :civilizational] do
    GenServer.call(__MODULE__, {:get_metrics, category})
  end

  @doc """
  Returns all scientific metrics (not server metrics).
  """
  def get_all_metrics() do
    GenServer.call(__MODULE__, :get_all_metrics)
  end

  @doc """
  Records an artifact (first-class event).
  """
  def record_artifact(type, data, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:record_artifact, type, data, metadata})
  end

  @doc """
  Searches artifacts by query.
  """
  def search_artifacts(query) do
    GenServer.call(__MODULE__, {:search_artifacts, query})
  end

  @doc """
  Returns the mission timeline.
  """
  def get_timeline() do
    GenServer.call(__MODULE__, :get_timeline)
  end

  @doc """
  Returns global constitutional status.
  """
  def get_constitutional_status() do
    GenServer.call(__MODULE__, :get_constitutional_status)
  end

  # ── GenServer Callbacks ─────────────────────────────────────

  @impl true
  def init(opts) do
    Logger.info("🔭 Starting Tiannara Observatory (Phase 23.0)")

    state = %{
      artifact_storage: ArtifactStorage.new(),
      metrics: Metrics.initialize(),
      timeline: Timeline.initialize(),
      screen_cache: %{},
      last_metrics_update: System.system_time(:millisecond),
      update_interval: 60_000  # 60 seconds
    }

    # Schedule periodic metrics collection
    schedule_metrics_update(state.update_interval)

    {:ok, state}
  end

  @impl true
  def handle_call({:get_screen, screen_number}, _from, state) do
    screen_data = Screens.get_screen_data(screen_number, state.metrics, state.artifact_storage)

    # Cache the screen data
    new_cache = Map.put(state.screen_cache, screen_number, screen_data)
    {:reply, screen_data, %{state | screen_cache: new_cache}}
  end

  @impl true
  def handle_call({:get_metrics, category}, _from, state) do
    metrics = Map.get(state.metrics, category, %{})
    {:reply, metrics, state}
  end

  @impl true
  def handle_call(:get_all_metrics, _from, state) do
    {:reply, state.metrics, state}
  end

  @impl true
  def handle_call({:search_artifacts, query}, _from, state) do
    results = ArtifactStorage.search(state.artifact_storage, query)
    {:reply, results, state}
  end

  @impl true
  def handle_call(:get_timeline, _from, state) do
    timeline = Timeline.get_events(state.timeline)
    {:reply, timeline, state}
  end

  @impl true
  def handle_call(:get_constitutional_status, _from, state) do
    status = Screens.Screen01ConstitutionalHealth.get_status(state.metrics)
    {:reply, status, state}
  end

  @impl true
  def handle_cast({:record_artifact, type, data, metadata}, state) do
    artifact = %{
      type: type,
      data: data,
      metadata: metadata,
      timestamp: System.system_time(:millisecond),
      hash: :crypto.hash(:sha256, :erlang.term_to_binary({type, data})) |> Base.encode16(case: :lower)
    }

    new_storage = ArtifactStorage.add(state.artifact_storage, artifact)
    new_timeline = Timeline.add_event(state.timeline, artifact)

    Logger.debug("📦 Recorded artifact: #{type}")

    {:noreply, %{state | artifact_storage: new_storage, timeline: new_timeline}}
  end

  @impl true
  def handle_info(:update_metrics, state) do
    Logger.debug("📊 Updating observatory metrics...")

    new_metrics = Metrics.collect_all()
    new_screen_cache = invalidate_screen_cache(state.screen_cache)

    schedule_metrics_update(state.update_interval)

    {:noreply, %{state |
      metrics: new_metrics,
      screen_cache: new_screen_cache,
      last_metrics_update: System.system_time(:millisecond)
    }}
  end

  # ── Internal Functions ──────────────────────────────────────

  defp schedule_metrics_update(interval) do
    Process.send_after(self(), :update_metrics, interval)
  end

  defp invalidate_screen_cache(cache) do
    # Clear cache to force fresh data on next request
    %{}
  end
end
