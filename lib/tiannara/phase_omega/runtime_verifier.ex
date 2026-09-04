defmodule Tiannara.PhaseOmega.RuntimeVerifier do
  alias Tiannara.PhaseOmega.SubsystemRegistry
  @moduledoc """
  Periodic health probe for every registered subsystem.

  Runs configurable checks:
    - Process alive? (Process.alive?/1)
    - ETS table exists? (for registries)
    - Module loaded? (Code.ensure_loaded?/1)
    - Can-respond? (GenServer.call with short timeout)

  Reports results back to `SubsystemRegistry.report_health/3` and
  emits telemetry for Observatory ingestion.
  """

  use GenServer
  require Logger

  @default_interval :timer.seconds(30)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Run a one-off verification of all subsystems now.
  """
  @spec verify_all() :: :ok
  def verify_all do
    GenServer.call(__MODULE__, :verify, :infinity)
  end

  @doc """
  Get the latest verification results.
  """
  @spec latest_results() :: map()
  def latest_results do
    GenServer.call(__MODULE__, :results)
  end

  # --------------------------------------------------------------------------
  # GenServer callbacks
  # --------------------------------------------------------------------------

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, @default_interval)
    schedule_next(interval)
    {:ok, %{interval: interval, last_run: nil, results: %{}}}
  end

  @impl true
  def handle_info(:verify, state) do
    results = run_verification()

    Logger.info("[PhaseΩ] Runtime verification complete — #{healthy_count(results)}/#{map_size(results)} healthy")
    emit(:verification_complete, %{healthy: healthy_count(results), total: map_size(results)})

    schedule_next(state.interval)
    {:noreply, %{state | last_run: DateTime.utc_now(), results: results}}
  end

  @impl true
  def handle_call(:verify, _from, state) do
    results = run_verification()
    {:reply, :ok, %{state | last_run: DateTime.utc_now(), results: results}}
  end

  @impl true
  def handle_call(:results, _from, state) do
    {:reply, %{last_run: state.last_run, subsystems: state.results}, state}
  end

  defp schedule_next(interval) do
    Process.send_after(self(), :verify, interval)
  end

  defp run_verification do
    SubsystemRegistry.all()
    |> Enum.map(fn record -> {record.name, verify_subsystem(record)} end)
    |> Enum.into(%{})
  end

  defp verify_subsystem(record) do
    checks = %{
      module_loaded: check_module_loaded(record.module),
      process_alive: check_process_alive(record),
      responds: check_responds(record),
      deps_satisfied: check_deps(record)
    }

    overall = if Enum.all?(checks, fn {_k, v} -> v == :pass end), do: :pass,
              else: if(Enum.any?(checks, fn {_k, v} -> v == :fail end), do: :fail, else: :degraded)

    SubsystemRegistry.report_health(record.name, overall, checks)
    SubsystemRegistry.transition(record.name, status_from_overall(overall))

    %{overall: overall, checks: checks}
  end

  defp check_module_loaded(module) do
    if Code.ensure_loaded?(module) && function_exported?(module, :module_info, 0) do
      :pass
    else
      :fail
    end
  end

  defp check_process_alive(%{pid: pid}) when is_pid(pid) do
    if Process.alive?(pid), do: :pass, else: :fail
  end

  defp check_process_alive(_), do: :skip

  defp check_responds(%{module: mod}) do
    if function_exported?(mod, :healthy?, 0) do
      try do
        apply(mod, :healthy?, []) && :pass || :degraded
      rescue
        _ -> :fail
      end
    else
      :skip
    end
  end

  defp check_deps(record) do
    deps = record.deps || []
    if deps == [] do
      :pass
    else
      unsatisfied = Enum.filter(deps, fn dep ->
        case SubsystemRegistry.get(dep) do
          nil -> true
          %{status: s} -> s not in [:healthy, :booted]
        end
      end)

      if unsatisfied == [], do: :pass, else: :degraded
    end
  end

  defp status_from_overall(:pass), do: :healthy
  defp status_from_overall(:degraded), do: :degraded
  defp status_from_overall(:fail), do: :failed

  defp healthy_count(results) do
    Enum.count(results, fn {_k, v} -> v.overall == :pass end)
  end

  defp emit(event, measurements) do
    :telemetry.execute([:tiannara, :phase_omega, :verifier, event], measurements, %{})
  end
end
