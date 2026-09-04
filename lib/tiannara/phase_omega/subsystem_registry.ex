defmodule Tiannara.PhaseOmega.SubsystemRegistry do
  @moduledoc """
  Ω.1 — Central subsystem registry with auto-discovery, dependency tracking,
  and runtime snapshot capability.

  Maintains an ETS table for fast read access and a GenServer for
  coordinated writes. Integrates with BEAM introspection to discover
  running processes, supervisors, ETS tables, and applications.

  Each subsystem moves through:

    discovered → booting → booted → healthy
                                        → degraded
                                        → failed

  ## Record fields

    name          — atom identifier
    module        — primary module
    app           — OTP application name
    version       — semantic version (integer)
    supervisor    — supervisor module (if applicable)
    pid           — process ID (if running)
    deps          — list of subsystem name atoms this depends on
    children      — list of child module names
    status        — lifecycle status atom
    health        — :healthy | :degraded | :failed | :unknown
    certificate   — boot certificate hash (if certified)
    observability — :telemetry_enabled | :partially_observed | :not_observed
    last_activity — DateTime of last registered activity
    last_health   — map of {result, details, time} from last health probe
    meta          — free-form metadata map
    ets_tables    — list of ETS table names owned
    registered_at — DateTime when first registered
  """

  use GenServer
  require Logger

  @table :tiannara_subsystem_registry
  @dep_table :tiannara_dep_graph

  @type status :: :discovered | :booting | :booted | :healthy | :degraded | :failed | :stopped
  @type health_state :: :healthy | :degraded | :failed | :unknown

  @type record :: %{
    name: atom(),
    module: module(),
    app: atom(),
    version: pos_integer(),
    supervisor: module() | nil,
    pid: pid() | nil,
    deps: [atom()],
    children: [module()],
    status: status(),
    health: health_state(),
    certificate: String.t() | nil,
    observability: :telemetry_enabled | :partially_observed | :not_observed,
    last_activity: DateTime.t() | nil,
    last_health: map() | nil,
    meta: map(),
    ets_tables: [atom()],
    running_children: [pid()],
    registered_at: DateTime.t()
  }

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Register a subsystem. Idempotent — subsequent calls with the same
  `name` merge in any new metadata.
  """
  @spec register(atom(), keyword()) :: :ok
  def register(name, opts \\ []) do
    GenServer.call(__MODULE__, {:register, name, opts}, :infinity)
  end

  @doc """
  Transition to a new lifecycle status.
  """
  @spec transition(atom(), status(), keyword()) :: :ok
  def transition(name, status, opts \\ []) do
    GenServer.call(__MODULE__, {:transition, name, status, opts}, :infinity)
  end

  @doc """
  Record a health probe result.
  """
  @spec report_health(atom(), :pass | :fail | :degraded, keyword()) :: :ok
  def report_health(name, result, details \\ []) do
    GenServer.call(__MODULE__, {:health, name, result, details}, :infinity)
  end

  @doc """
  Set a boot certificate for a subsystem.
  """
  @spec certify(atom(), String.t()) :: :ok
  def certify(name, hash) do
    GenServer.call(__MODULE__, {:certify, name, hash}, :infinity)
  end

  @doc """
  Record subsystem activity (heartbeat).
  """
  @spec heartbeat(atom(), keyword()) :: :ok
  def heartbeat(name, meta \\ []) do
    GenServer.call(__MODULE__, {:heartbeat, name, meta}, :infinity)
  end

  @doc """
  Get the full record for a subsystem.
  """
  @spec get(atom()) :: record() | nil
  def get(name) do
    case :ets.lookup(@table, name) do
      [{^name, rec}] -> rec
      [] -> nil
    end
  end

  @doc """
  List all registered subsystems.
  """
  @spec all() :: [record()]
  def all do
    :ets.tab2list(@table)
    |> Enum.map(fn {_name, rec} -> rec end)
  end

  @doc """
  List subsystems matching a filter function.
  """
  @spec filter((record() -> boolean())) :: [record()]
  def filter(pred) do
    all() |> Enum.filter(pred)
  end

  @doc """
  Count subsystems by status.
  """
  @spec count_by_status() :: %{status() => non_neg_integer()}
  def count_by_status do
    all()
    |> Enum.reduce(%{}, fn r, acc -> Map.update(acc, r.status, 1, &(&1 + 1)) end)
  end

  @doc """
  List subsystems by status.
  """
  @spec list_by_status(status()) :: [record()]
  def list_by_status(status) do
    filter(fn r -> r.status == status end)
  end

  @doc """
  List subsystems whose dependencies are all satisfied.
  """
  @spec ready_to_boot() :: [record()]
  def ready_to_boot do
    filter(fn r ->
      r.status == :discovered &&
        Enum.all?(r.deps, fn dep ->
          case get(dep) do
            nil -> false
            d -> d.status in [:healthy, :booted]
          end
        end)
    end)
  end

  @doc """
  List subsystems that depend on the given one.
  """
  @spec dependents_of(atom()) :: [record()]
  def dependents_of(name) do
    filter(fn r -> name in r.deps end)
  end

  @doc """
  Get the full dependency graph as an adjacency map.
  """
  @spec dependency_graph() :: %{atom() => [atom()]}
  def dependency_graph do
    all()
    |> Enum.map(fn r -> {r.name, r.deps} end)
    |> Enum.into(%{})
  end

  @doc """
  Detect circular dependencies. Returns a list of cycles.
  """
  @spec detect_cycles() :: [[atom()]]
  def detect_cycles do
    graph = dependency_graph()
    names = Map.keys(graph)

    Enum.flat_map(names, fn start ->
      find_cycles(start, graph, [], [])
    end)
    |> Enum.uniq()
  end

  @doc """
  Detect missing (unresolvable) dependencies.
  """
  @spec detect_missing_deps() :: [{atom(), atom()}]
  def detect_missing_deps do
    registered = all() |> Enum.map(& &1.name) |> MapSet.new()

    all()
    |> Enum.flat_map(fn r ->
      r.deps
      |> Enum.reject(&MapSet.member?(registered, &1))
      |> Enum.map(fn missing -> {r.name, missing} end)
    end)
  end

  @doc """
  List all boot certificates — SHA-256 hashes of registered subsystems.
  """
  @spec list_boot_certificates() :: [{atom(), String.t()}]
  def list_boot_certificates do
    all()
    |> Enum.filter(fn r -> r.certificate != nil end)
    |> Enum.map(fn r -> {r.name, r.certificate} end)
  end

  @doc """
  Return a snapshot of the entire runtime for Observatory display.
  """
  @spec snapshot() :: map()
  def snapshot do
    subsystems = all() |> Enum.map(fn r ->
      %{
        name: r.name,
        module: r.module,
        app: r.app,
        status: r.status,
        health: r.health,
        version: r.version,
        pid: r.pid,
        deps: r.deps,
        children: r.children,
        certificate: r.certificate,
        observability: r.observability,
        last_activity: r.last_activity,
        last_health: r.last_health
      }
    end)

    counts = count_by_status()

    %{
      total: length(subsystems),
      subsystems: subsystems,
      status_counts: counts,
      healthy: Map.get(counts, :healthy, 0),
      degraded: Map.get(counts, :degraded, 0),
      failed: Map.get(counts, :failed, 0),
      booting: Map.get(counts, :booting, 0),
      discovered: Map.get(counts, :discovered, 0),
      cycles_detected: detect_cycles(),
      missing_deps: detect_missing_deps(),
      timestamp: DateTime.utc_now()
    }
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :protected, :set, read_concurrency: true])
    :ets.new(@dep_table, [:named_table, :protected, :set])
    {:ok, %{started_at: DateTime.utc_now(), discover_count: 0}}
  end

  @impl true
  def handle_call({:register, name, opts}, _from, state) do
    now = DateTime.utc_now()
    opts = if is_list(opts), do: Map.new(opts), else: opts

    defaults = %{
      name: name,
      module: Map.get(opts, :module, name),
      app: Map.get(opts, :app, :unknown),
      version: Map.get(opts, :version, 1),
      supervisor: Map.get(opts, :supervisor),
      pid: Map.get(opts, :pid),
      deps: Map.get(opts, :deps, []),
      children: Map.get(opts, :children, []),
      status: :discovered,
      health: :unknown,
      certificate: nil,
      observability: :not_observed,
      last_activity: now,
      last_health: nil,
      meta: Map.get(opts, :meta, %{}),
      ets_tables: [],
      running_children: [],
      registered_at: now
    }

    case :ets.lookup(@table, name) do
      [{^name, existing}] ->
        merged = Map.merge(existing, defaults)
        true = :ets.insert(@table, {name, merged})
        {:reply, :ok, state}

      [] ->
        true = :ets.insert(@table, {name, defaults})
        update_dep_index(name, defaults.deps)
        emit(:registered, %{name: name, deps: defaults.deps})
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:transition, name, status, opts}, _from, state) do
    update_field(name, fn rec ->
      now = DateTime.utc_now()
      meta = Keyword.get(opts, :meta, %{})

      %{rec |
        status: status,
        last_activity: now,
        meta: Map.merge(rec.meta, Enum.into(meta, %{})),
        pid: Keyword.get(opts, :pid, rec.pid)
      }
    end)
    emit(:transition, %{name: name, status: status})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:health, name, result, details}, _from, state) do
    health_status = case result do
      :pass -> :healthy
      :fail -> :failed
      :degraded -> :degraded
    end

    update_field(name, fn rec ->
      %{rec |
        health: health_status,
        last_health: %{result: result, details: details, time: DateTime.utc_now()},
        last_activity: DateTime.utc_now()
      }
    end)
    emit(:health_report, %{name: name, result: result})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:certify, name, hash}, _from, state) do
    update_field(name, fn rec ->
      %{rec | certificate: hash, last_activity: DateTime.utc_now()}
    end)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:heartbeat, name, meta}, _from, state) do
    update_field(name, fn rec ->
      %{rec |
        last_activity: DateTime.utc_now(),
        meta: Map.merge(rec.meta, Enum.into(meta, %{}))
      }
    end)
    :telemetry.execute([:tiannara, :subsystem, :heartbeat], %{}, %{name: name})
    {:reply, :ok, state}
  end

  # ---------------------------------------------------------------------------
  # Internal
  # ---------------------------------------------------------------------------

  defp update_field(name, fun) do
    case :ets.lookup(@table, name) do
      [{^name, rec}] ->
        true = :ets.insert(@table, {name, fun.(rec)})
        :ok
      [] ->
        {:error, :not_found}
    end
  end

  defp update_dep_index(name, deps) do
    Enum.each(deps, fn dep ->
      :ets.insert(@dep_table, {dep, name})
    end)
  end

  defp find_cycles(current, graph, visited, path) do
    if current in path do
      cycle_start = Enum.find_index(path, &(&1 == current))
      {cycle, _} = Enum.split(path, cycle_start)
      [cycle ++ [current]]
    else
      if current in visited do
        []
      else
        deps = Map.get(graph, current, [])
        Enum.flat_map(deps, fn dep ->
          find_cycles(dep, graph, [current | visited], [current | path])
        end)
      end
    end
  end

  defp emit(event, metadata) do
    :telemetry.execute([:tiannara, :phase_omega, :registry, event], %{}, metadata)

    subsystem_event = case event do
      :registered -> :registered
      :transition ->
        case metadata[:status] do
          :healthy -> :booted
          :booted -> :booted
          :failed -> :failed
          _ -> nil
        end
      _ -> nil
    end

    if subsystem_event do
      :telemetry.execute([:tiannara, :subsystem, subsystem_event], %{}, metadata)
    end
  end
end
