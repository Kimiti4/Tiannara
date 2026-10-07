defmodule Tiannara.CEL.Kernel do
  use GenServer
  require Logger

  alias Tiannara.CEL.Kernel.{BootSequencer, ConstitutionalScore, RuntimeStates, ServiceRegistry}
  alias Tiannara.Council
  alias Tiannara.Council.Authorization

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def boot, do: GenServer.call(__MODULE__, :boot, 120_000)
  def runtime_state, do: GenServer.call(__MODULE__, :runtime_state)
  def boot_report, do: GenServer.call(__MODULE__, :boot_report)
  def service_pid(id), do: GenServer.call(__MODULE__, {:service_pid, id})
  def transition(new_state), do: GenServer.call(__MODULE__, {:transition, new_state})
  def restart_service(id, actor), do: GenServer.call(__MODULE__, {:restart_service, id, actor})
  def halt(actor, reason), do: GenServer.call(__MODULE__, {:halt, actor, reason})

  @impl true
  def init(_opts) do
    {:ok, dyn_sup} = DynamicSupervisor.start_link(strategy: :one_for_one, name: Tiannara.CEL.ServiceSupervisor)

    state = %{
      runtime_state: :booting,
      dyn_sup: dyn_sup,
      service_pids: %{},
      boot_report: nil,
      last_boot_at: nil,
      transition_history: [{:booting, DateTime.utc_now()}]
    }

    Logger.info("Executive Kernel initialized. State: :booting")
    {:ok, state}
  end

  @impl true
  def handle_call(:boot, _from, state) do
    case Council.emergency_state() do
      %{active: true} ->
        Logger.error("Kernel: boot refused — Council emergency active")
        {:reply, {:error, :council_emergency}, transition_state(state, :emergency)}

      _ ->
        report =
          BootSequencer.boot(
            fn spec -> start_service(spec, state.dyn_sup) end,
            fn spec -> check_health(spec) end,
            fn spec -> check_constitutional_score(spec) end,
            fn spec -> check_resources(spec) end
          )

        new_state =
          state
          |> Map.put(:boot_report, report)
          |> Map.put(:last_boot_at, DateTime.utc_now())
          |> record_pids(report)
          |> transition_state(status_to_state(report.status))

        log_to_council(:eos_booted, %{status: report.status, duration_ms: report.duration_ms})
        Logger.info("Kernel: boot complete. EOS state: #{new_state.runtime_state}")
        {:reply, {:ok, report}, new_state}
    end
  end

  @impl true
  def handle_call(:runtime_state, _from, state), do: {:reply, state.runtime_state, state}

  @impl true
  def handle_call(:boot_report, _from, state), do: {:reply, state.boot_report, state}

  @impl true
  def handle_call({:service_pid, id}, _from, state) do
    {:reply, Map.get(state.service_pids, id, :error), state}
  end

  @impl true
  def handle_call({:transition, new_state}, _from, state) do
    if RuntimeStates.valid_transition?(state.runtime_state, new_state) do
      {:reply, :ok, transition_state(state, new_state)}
    else
      {:reply, {:error, {:invalid_transition, state.runtime_state, new_state}}, state}
    end
  end

  @impl true
  def handle_call({:restart_service, id, actor}, _from, state) do
    case Council.authorize(:architectural_change, %{action: :restart, service: id}, nil) do
      %Authorization{decision: :approved} ->
        do_restart(id, state)
      %Authorization{decision: :conditional} ->
        do_restart(id, state)
      auth ->
        {:reply, {:error, :council_denied, auth.explanation}, state}
    end
  end

  @impl true
  def handle_call({:halt, actor, reason}, _from, state) do
    case Council.authorize(:architectural_change, %{action: :halt_eos, actor: actor}, nil) do
      %Authorization{decision: :approved} ->
        Enum.each(state.service_pids, fn {_id, pid} ->
          DynamicSupervisor.terminate_child(state.dyn_sup, pid)
        end)
        log_to_council(:eos_halted, %{actor: actor, reason: reason})
        {:reply, :ok, transition_state(%{state | service_pids: %{}}, :shutdown)}

      auth ->
        {:reply, {:error, :council_denied, auth.explanation}, state}
    end
  end

  defp start_service(spec, dyn_sup) do
    child = %{id: spec.id, start: {spec.module, :start_link, [[]]}, restart: :temporary}
    case DynamicSupervisor.start_child(dyn_sup, child) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      other -> other
    end
  end

  defp check_health(spec) do
    {mod, fun, args} = spec.health_check
    try do
      case apply(mod, fun, args) do
        :healthy -> :healthy
        :unhealthy -> :unhealthy
        true -> :healthy
        false -> :unhealthy
        _ -> :unhealthy
      end
    catch
      _, _ -> :unhealthy
    end
  end

  defp check_resources(_spec), do: :sufficient

  defp check_constitutional_score(spec) do
    {mod, fun, args} = spec.constitutional_score_check
    try do
      apply(mod, fun, args)
    catch
      _, _ -> ConstitutionalScore.default(spec.id)
    end
  end

  defp record_pids(state, report) do
    new_pids =
      Enum.reduce(report.services, state.service_pids, fn
        {id, :ok}, acc ->
          case ServiceRegistry.get(id) do
            {:ok, s} ->
              case Process.whereis(s.module) do
                nil -> acc
                pid -> Map.put(acc, id, pid)
              end
            _ -> acc
          end
        _, acc -> acc
      end)
    %{state | service_pids: new_pids}
  end

  defp transition_state(state, new_rs) do
    %{state |
      runtime_state: new_rs,
      transition_history: [{new_rs, DateTime.utc_now()} | state.transition_history]
    }
  end

  defp status_to_state(:ready), do: :operational
  defp status_to_state(:degraded), do: :recovery
  defp status_to_state(:failed), do: :emergency

  defp do_restart(id, state) do
    with {:ok, spec} <- ServiceRegistry.get(id),
         old_pid when is_pid(old_pid) <- Map.get(state.service_pids, id),
         :ok <- DynamicSupervisor.terminate_child(state.dyn_sup, old_pid),
         {:ok, new_pid} <- start_service(spec, state.dyn_sup) do
      log_to_council(:service_restarted, %{service: id})
      {:reply, :ok, %{state | service_pids: Map.put(state.service_pids, id, new_pid)}}
    else
      err -> {:reply, {:error, err}, state}
    end
  end

  defp log_to_council(action, payload) do
    try do
      Tiannara.Council.AuditLog.append(action, :kernel, payload)
    catch
      _, _ -> :ok
    end
  end
end
