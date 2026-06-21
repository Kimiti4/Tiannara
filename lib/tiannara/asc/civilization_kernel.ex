defmodule Tiannara.ASC.CivilizationKernel do
  @moduledoc """
  The civilization-level state store for ASC.

  Holds the registry of active and historical projects, civilization
  health metrics, and global configuration resolved from application
  config at startup.

  Analogous to `TiannaraOS.CivilizationKernel` but scoped to the
  software engineering civilization.
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.Project

  @type state :: %{
    projects: %{String.t() => Project.t()},
    config: map(),
    started_at: DateTime.t(),
    metrics: map()
  }

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Register a new software project and return its ID."
  @spec start_project(String.t(), map()) :: {:ok, String.t()} | {:error, term()}
  def start_project(goal, opts \\ %{}) do
    GenServer.call(__MODULE__, {:start_project, goal, opts})
  end

  @doc "Return the full project struct by ID."
  @spec get_project(String.t()) :: {:ok, Project.t()} | {:error, :not_found}
  def get_project(id) do
    GenServer.call(__MODULE__, {:get_project, id})
  end

  @doc "Update a project struct in place."
  @spec update_project(Project.t()) :: :ok
  def update_project(%Project{} = project) do
    GenServer.cast(__MODULE__, {:update_project, project})
  end

  @doc "List all projects (active + historical)."
  @spec list_projects() :: [Project.t()]
  def list_projects do
    GenServer.call(__MODULE__, :list_projects)
  end

  @doc "Return civilization health summary."
  @spec health() :: map()
  def health do
    GenServer.call(__MODULE__, :health)
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    config = Application.get_env(:tiannara, :asc, [])

    state = %{
      projects: %{},
      config: Map.new(config),
      started_at: DateTime.utc_now(),
      metrics: %{
        total_projects_started: 0,
        total_projects_completed: 0,
        total_projects_failed: 0
      }
    }

    Logger.info("[ASC.CivilizationKernel] Initialized. Project data dir: #{config[:project_data_dir]}")
    {:ok, state}
  end

  @impl true
  def handle_call({:start_project, goal, opts}, _from, state) do
    id = "asc_proj_#{:erlang.unique_integer([:positive, :monotonic])}"

    project = Project.new(id, goal, opts)

    # Ensure project directory exists on disk
    project_dir = Path.join([
      state.config[:project_data_dir] || "data/asc_projects",
      id
    ])

    Enum.each(["source", "tests", "docs", "infrastructure", "telemetry", "history"],
      &File.mkdir_p!(Path.join(project_dir, &1)))

    new_state = state
      |> put_in([:projects, id], project)
      |> update_in([:metrics, :total_projects_started], &(&1 + 1))

    :telemetry.execute([:tiannara, :asc, :project, :started], %{count: 1}, %{id: id, goal: goal})

    Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:project:created", %{project_id: id, goal: goal})

    Logger.info("[ASC.CivilizationKernel] Project #{id} created: #{goal}")
    {:reply, {:ok, id}, new_state}
  end

  @impl true
  def handle_call({:get_project, id}, _from, state) do
    case Map.get(state.projects, id) do
      nil -> {:reply, {:error, :not_found}, state}
      project -> {:reply, {:ok, project}, state}
    end
  end

  @impl true
  def handle_call(:list_projects, _from, state) do
    {:reply, Map.values(state.projects), state}
  end

  @impl true
  def handle_call(:health, _from, state) do
    report = %{
      civilization: :asc,
      uptime_seconds: DateTime.diff(DateTime.utc_now(), state.started_at),
      active_projects: state.projects |> Map.values() |> Enum.count(&(&1.status == :active)),
      total_projects: map_size(state.projects),
      metrics: state.metrics
    }
    {:reply, report, state}
  end

  @impl true
  def handle_cast({:update_project, project}, state) do
    new_state = put_in(state, [:projects, project.id], project)
    {:noreply, new_state}
  end
end
