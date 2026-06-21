defmodule Tiannara.ASC.Observatory.ProjectObservatory do
  @moduledoc """
  The ASC Project Observatory — the instrument that transforms software
  project execution into scientific data.

  Analogous to `Tiannara.Sentinel.D2.BreakthroughAnalyzer` and the
  Operational Observatory but scoped to software engineering metrics.

  ## Responsibilities

  1. Accepts metric updates from all ASC sub-civilizations via `record/2`.
  2. Maintains a time-series of `Metrics` snapshots per project in ETS.
  3. Periodically flushes snapshots to disk (`data/asc_projects/<id>/telemetry/`).
  4. Provides aggregated views for `Laws.Discoverer` to extract patterns across projects.
  5. Emits `[:tiannara, :asc, :observatory, :snapshot]` telemetry events on flush.

  ## Why This Makes Software Engineering Science

  Without this observatory, ASC builds software. With it, ASC accumulates
  empirical evidence about *which* engineering choices produce *which* outcomes.
  Over enough projects the Laws Discoverer can establish statistically robust
  laws: "Event-driven architectures require 40% more crucible iterations
  than modular monoliths at equivalent team size."
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.Observatory.Metrics

  @table :asc_observatory
  @flush_interval_ms Application.compile_env(:tiannara, [:asc, :observatory_flush_ms], 60_000)

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Record a partial metrics update for a project."
  @spec record(String.t(), map()) :: :ok
  def record(project_id, updates) when is_map(updates) do
    GenServer.cast(__MODULE__, {:record, project_id, updates})
  end

  @doc "Return the current metrics snapshot for a project."
  @spec snapshot(String.t()) :: {:ok, Metrics.t()} | {:error, :not_found}
  def snapshot(project_id) do
    case :ets.lookup(@table, project_id) do
      [{^project_id, metrics}] -> {:ok, metrics}
      [] -> {:error, :not_found}
    end
  end

  @doc "Return all project snapshots — used by Laws.Discoverer."
  @spec all_snapshots() :: [Metrics.t()]
  def all_snapshots do
    try do
      :ets.tab2list(@table) |> Enum.map(&elem(&1, 1))
    rescue
      ArgumentError -> []
    end
  end

  @doc "Return the composite observatory score for a project."
  @spec score(String.t()) :: {:ok, float()} | {:error, :not_found}
  def score(project_id) do
    case snapshot(project_id) do
      {:ok, metrics} -> {:ok, Metrics.composite_score(metrics)}
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    schedule_flush()
    Logger.info("[ASC.Observatory] Project Observatory initialized. Flush interval: #{@flush_interval_ms}ms")
    {:ok, %{flush_count: 0}}
  end

  @impl true
  def handle_cast({:record, project_id, updates}, state) do
    current =
      case :ets.lookup(@table, project_id) do
        [{^project_id, m}] -> m
        [] -> Metrics.new(project_id)
      end

    updated = struct(current, Map.put(updates, :recorded_at, DateTime.utc_now()))
    :ets.insert(@table, {project_id, updated})

    :telemetry.execute(
      [:tiannara, :asc, :observatory, :update],
      %{composite: Metrics.composite_score(updated)},
      %{project_id: project_id}
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(:flush, state) do
    flush_to_disk()
    schedule_flush()
    {:noreply, %{state | flush_count: state.flush_count + 1}}
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp schedule_flush do
    Process.send_after(self(), :flush, @flush_interval_ms)
  end

  defp flush_to_disk do
    snapshots = all_snapshots()

    Enum.each(snapshots, fn metrics ->
      if metrics.project_id do
        dir = Path.join(["data/asc_projects", metrics.project_id, "telemetry"])
        File.mkdir_p!(dir)

        ts = DateTime.utc_now() |> DateTime.to_unix()
        path = Path.join(dir, "observatory_#{ts}.json")

        File.write!(path, Jason.encode!(metrics, pretty: true))
      end
    end)

    :telemetry.execute(
      [:tiannara, :asc, :observatory, :snapshot],
      %{projects_flushed: length(snapshots)},
      %{}
    )

    Logger.debug("[ASC.Observatory] Flushed #{length(snapshots)} project snapshots to disk")
  rescue
    e -> Logger.warning("[ASC.Observatory] Flush error: #{inspect(e)}")
  end
end
