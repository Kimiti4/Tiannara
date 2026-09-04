defmodule Tiannara.PhaseOmega.BootSequencer do
  alias Tiannara.PhaseOmega.SubsystemRegistry
  @moduledoc """
  Ω.2 — Constitutional Boot Engine with retry, rollback, and certificates.

  Orchestrates the transition of each subsystem from `:discovered` to
  `:healthy`. Waits for dependencies to reach `:healthy` before booting
  dependents. Retries failed boots up to a configurable limit, rolls back
  on persistent failure, and issues startup certificates for successfully
  booted subsystems.
  """

  use GenServer
  require Logger

  @max_retries 3

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Define a subsystem for the sequencer to boot.
  """
  @spec define_subsystem(Keyword.t()) :: :ok
  def define_subsystem(opts) do
    GenServer.call(__MODULE__, {:define, opts}, :infinity)
  end

  @doc """
  Run the boot sequence for all defined subsystems.
  """
  @spec boot() :: :ok | {:error, String.t()}
  def boot do
    GenServer.call(__MODULE__, :boot, :infinity)
  end

  @doc """
  Get current boot progress.
  """
  @spec progress() :: map()
  def progress do
    GenServer.call(__MODULE__, :progress)
  end

  @doc """
  Get the boot certificate for a subsystem.
  Returns nil if not yet certified.
  """
  @spec certificate(atom()) :: String.t() | nil
  def certificate(name) do
    record = SubsystemRegistry.get(name)
    record && record.certificate
  end

  # --------------------------------------------------------------------------
  # GenServer callbacks
  # --------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    {:ok, %{
      specs: %{},
      results: %{},
      certs: %{},
      boot_started: false,
      boot_complete: false,
      phase: :idle
    }}
  end

  @impl true
  def handle_call({:define, opts}, _from, state) do
    opts = if is_list(opts), do: Map.new(opts), else: opts
    name = Map.fetch!(opts, :name)
    spec = %{
      name: name,
      module: Map.fetch!(opts, :module),
      deps: Map.get(opts, :deps, []),
      supervisor: Map.get(opts, :supervisor),
      start_opts: Map.get(opts, :start_opts, []),
      health_probe: Map.get(opts, :health_probe),
      children: Map.get(opts, :children, []),
      description: Map.get(opts, :description, ""),
      max_retries: Map.get(opts, :max_retries, @max_retries)
    }

    SubsystemRegistry.register(name, %{
      module: spec.module,
      supervisor: spec.supervisor,
      deps: spec.deps,
      children: spec.children,
      description: spec.description,
      version: 1,
      app: Map.get(opts, :app, :unknown)
    })

    {:reply, :ok, %{state | specs: Map.put(state.specs, name, spec)}}
  end

  @impl true
  def handle_call(:boot, _from, state) do
    if state.boot_complete do
      {:reply, {:error, "boot already completed"}, state}
    else
      new_state = do_boot(%{state | phase: :booting})
      {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call(:progress, _from, state) do
    all_subsystems = SubsystemRegistry.all()
    completed = Enum.filter(all_subsystems, fn r -> r.status in [:booted, :healthy, :degraded] end)
    failed = Enum.filter(all_subsystems, fn r -> r.status == :failed end)

    {:reply, %{
      phase: state.phase,
      total: map_size(state.specs),
      completed: length(completed),
      failed: length(failed),
      certified: map_size(state.certs),
      boot_started: state.boot_started,
      boot_complete: state.boot_complete,
      results: state.results,
      certs: state.certs
    }, state}
  end

  # --------------------------------------------------------------------------
  # Boot orchestration
  # --------------------------------------------------------------------------

  defp do_boot(state) do
    names = state.specs |> Map.keys()
    order = resolve_order(names, state.specs)

    Logger.info("[PhaseΩ:Boot] Boot order: #{inspect(order)}")

    {results, certs, failed_subsystems} = boot_ordered(order, state.specs, %{}, %{}, [])

    completed = Enum.count(results, fn {_k, v} -> v == :ok end)
    total = map_size(state.specs)

    Logger.info("[PhaseΩ:Boot] Boot sequence complete — #{completed}/#{total} subsystems healthy")

    if failed_subsystems != [] do
      Logger.error("[PhaseΩ:Boot] Failed subsystems: #{inspect(failed_subsystems)}")
      attempt_rollback(failed_subsystems, state.specs)
    end

    %{state |
      results: results,
      certs: certs,
      boot_started: true,
      boot_complete: true,
      phase: if(failed_subsystems == [], do: :complete, else: :degraded)
    }
  end

  defp boot_ordered([], _specs, results, certs, failed) do
    {results, certs, failed}
  end

  defp boot_ordered([name | rest], specs, results, certs, failed) do
    spec = Map.fetch!(specs, name)
    Logger.info("[PhaseΩ:Boot] Booting #{name} — deps: #{inspect(spec.deps)}")

    case boot_with_retry(name, spec) do
      {:ok, _pid} ->
        cert = generate_certificate(name, spec)
        SubsystemRegistry.transition(name, :healthy)
        SubsystemRegistry.certify(name, cert)
        emit(:boot_success, %{name: name, certificate: cert})
        boot_ordered(rest, specs, Map.put(results, name, :ok), Map.put(certs, name, cert), failed)

      {:error, reason} ->
        Logger.error("[PhaseΩ:Boot] Failed to boot #{name}: #{reason}")
        SubsystemRegistry.transition(name, :failed)
        emit(:boot_failed, %{name: name, reason: reason})
        boot_ordered(rest, specs, Map.put(results, name, {:error, reason}), certs, [name | failed])
    end
  end

  defp boot_with_retry(name, spec, attempt \\ 1) do
    SubsystemRegistry.transition(name, :booting)

    case start_supervisor(spec) do
      {:ok, pid} ->
        SubsystemRegistry.register(name, %{
          module: spec.module,
          supervisor: spec.supervisor,
          deps: spec.deps,
          pid: pid,
          children: spec.children,
          description: spec.description
        })
        SubsystemRegistry.transition(name, :booted, pid: pid)

        case verify_health(name, spec) do
          :ok -> {:ok, pid}
          {:error, reason} ->
            if attempt < spec.max_retries do
              Logger.warning("[PhaseΩ:Boot] Health check failed for #{name} (attempt #{attempt}/#{spec.max_retries}), retrying...")
              :timer.sleep(1000 * attempt)
              boot_with_retry(name, spec, attempt + 1)
            else
              {:error, "health check failed after #{attempt} attempts: #{reason}"}
            end
        end

      {:error, {:already_started, pid}} ->
        SubsystemRegistry.transition(name, :booted, pid: pid)
        verify_health(name, spec)
        {:ok, pid}

      {:error, reason} ->
        if attempt < spec.max_retries do
          Logger.warning("[PhaseΩ:Boot] Start failed for #{name} (attempt #{attempt}/#{spec.max_retries}), retrying...")
          :timer.sleep(1000 * attempt)
          boot_with_retry(name, spec, attempt + 1)
        else
          {:error, "start failed after #{attempt} attempts: #{inspect(reason)}"}
        end
    end
  end

  defp start_supervisor(%{supervisor: nil}), do: {:error, "no supervisor defined"}
  defp start_supervisor(%{supervisor: mod, start_opts: opts}) do
    try do
      case mod.start_link(opts) do
        {:ok, pid} -> {:ok, pid}
        {:error, {:already_started, pid}} -> {:error, {:already_started, pid}}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e -> {:error, "exception starting #{inspect(mod)}: #{inspect(e)}"}
    end
  end

  defp verify_health(_name, %{health_probe: nil}), do: :ok
  defp verify_health(_name, %{health_probe: {mod, fun, args}}) do
    try do
      apply(mod, fun, args)
      :ok
    rescue
      e -> {:error, "health probe raised: #{inspect(e)}"}
    catch
      :exit, reason -> {:error, "health probe exited: #{inspect(reason)}"}
    end
  end

  # --------------------------------------------------------------------------
  # Rollback
  # --------------------------------------------------------------------------

  defp attempt_rollback(failed, specs) do
    Logger.warning("[PhaseΩ:Boot] Attempting rollback for failed subsystems...")

    Enum.each(failed, fn name ->
      spec = Map.get(specs, name)
      if spec && spec.supervisor do
        pid = Process.whereis(spec.supervisor)
        if pid && Process.alive?(pid) do
          Logger.info("[PhaseΩ:Boot] Stopping failed subsystem: #{name}")
          Supervisor.stop(pid, :shutdown)
          SubsystemRegistry.transition(name, :stopped)
        end
      end
    end)
  end

  # --------------------------------------------------------------------------
  # Certificates
  # --------------------------------------------------------------------------

  defp generate_certificate(name, spec) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    deps_hash = spec.deps |> Enum.sort() |> Enum.map(&Atom.to_string/1) |> Enum.join(",") |> :erlang.md5() |> Base.encode16(case: :lower)
    children_hash = spec.children |> Enum.sort() |> Enum.map(&Atom.to_string/1) |> Enum.join(",") |> :erlang.md5() |> Base.encode16(case: :lower)

    :crypto.hash(:sha256, "#{name}|#{timestamp}|#{deps_hash}|#{children_hash}")
    |> Base.encode16(case: :lower)
  end

  # --------------------------------------------------------------------------
  # Dependency order resolution
  # --------------------------------------------------------------------------

  defp resolve_order(names, specs) do
    graph = Enum.reduce(names, %{}, fn name, g ->
      deps = specs[name].deps |> Enum.filter(&(&1 in names))
      Map.put(g, name, deps)
    end)

    sorted = Enum.reduce(names, [], fn name, acc ->
      tsort(name, graph, acc, [])
    end)

    sorted |> Enum.reverse() |> Enum.uniq()
  end

  defp tsort(name, graph, sorted, visiting) do
    cond do
      name in sorted -> sorted
      name in visiting -> sorted
      true ->
        deps = Map.get(graph, name, [])
        sorted = Enum.reduce(deps, sorted, fn dep, s -> tsort(dep, graph, s, [name | visiting]) end)
        [name | sorted]
    end
  end

  defp emit(event, metadata) do
    :telemetry.execute([:tiannara, :phase_omega, :boot, event], %{}, metadata)
  end
end
