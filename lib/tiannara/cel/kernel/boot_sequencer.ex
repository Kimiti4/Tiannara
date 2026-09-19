defmodule Tiannara.CEL.Kernel.BootSequencer do
  alias Tiannara.CEL.Kernel.{ConstitutionalScore, ServiceRegistry}

  @type gate_result :: :pass | {:fail, atom(), String.t()}
  @type boot_result :: %{
          status: :ready | :degraded | :failed,
          services: [{ServiceRegistry.service_id(), :ok | :degraded | :failed | :skipped}],
          gate_results: map(),
          failed_critical: [ServiceRegistry.service_id()],
          duration_ms: non_neg_integer()
        }

  @spec boot(
          starter :: (ServiceRegistry.service_spec() -> {:ok, pid()} | {:error, term()}),
          health_checker :: (ServiceRegistry.service_spec() -> :healthy | :unhealthy),
          score_checker :: (ServiceRegistry.service_spec() -> ConstitutionalScore.t()),
          resource_checker :: (ServiceRegistry.service_spec() -> :sufficient | :insufficient),
          services :: [ServiceRegistry.service_spec()] | nil
        ) :: boot_result()
  def boot(starter, health_checker, score_checker, resource_checker, services \\ nil) do
    start_time = System.monotonic_time(:millisecond)
    order = services || ServiceRegistry.boot_order()

    {results, failed_critical, gate_results} =
      Enum.reduce(order, {[], [], %{}}, fn spec, {acc, failed_crit, gates} ->
        deps_ok = not Enum.any?(spec.depends_on, &(&1 in failed_crit))

        if not deps_ok do
          {[{spec.id, :skipped} | acc], failed_crit, gates}
        else
          case run_gates(spec, starter, health_checker, score_checker, resource_checker) do
            {:ok, service_gates} ->
              :telemetry.execute([:tiannara, :cel, :kernel, :service_booted], %{}, %{service: spec.id})
              {[{spec.id, :ok} | acc], failed_crit, Map.put(gates, spec.id, service_gates)}

            {:degraded, reason, service_gates} ->
              handle_degraded(spec, reason, acc, failed_crit, gates, service_gates)

            {:failed, reason, service_gates} ->
              handle_failed(spec, reason, acc, failed_crit, gates, service_gates)
          end
        end
      end)

    duration = System.monotonic_time(:millisecond) - start_time

    status =
      cond do
        length(failed_critical) > 0 -> :failed
        Enum.any?(results, fn {_, s} -> s in [:degraded, :skipped] end) -> :degraded
        true -> :ready
      end

    %{
      status: status,
      services: Enum.reverse(results),
      gate_results: gate_results,
      failed_critical: failed_critical,
      duration_ms: duration
    }
  end

  defp run_gates(spec, starter, health_checker, score_checker, resource_checker) do
    gates = %{}
    with {:ok, gates} <- run_gate(:dependency, gates, fn -> :pass end),
         {:ok, _pid} <- starter.(spec),
         {:ok, gates} <- run_gate(:health, gates, fn -> check_health(spec, health_checker) end),
         {:ok, gates} <- run_gate(:constitution, gates, fn -> check_constitution(spec, score_checker) end),
         {:ok, gates} <- run_gate(:capability, gates, fn -> check_capability(spec) end),
         {:ok, gates} <- run_gate(:resource, gates, fn -> resource_checker.(spec) |> to_gate() end) do
      {:ok, gates}
    else
      {:gate_failed, gate, reason, gates} ->
        case spec.criticality do
          :critical -> {:failed, {gate, reason}, gates}
          _ -> {:degraded, {gate, reason}, gates}
        end
      {:error, reason} ->
        case spec.criticality do
          :critical -> {:failed, {:start, reason}, gates}
          _ -> {:degraded, {:start, reason}, gates}
        end
    end
  end

  defp run_gate(gate_name, gates, check_fn) do
    case check_fn.() do
      :pass -> {:ok, Map.put(gates, gate_name, :pass)}
      :healthy -> {:ok, Map.put(gates, gate_name, :pass)}
      :sufficient -> {:ok, Map.put(gates, gate_name, :pass)}
      {:fail, reason} -> {:gate_failed, gate_name, reason, Map.put(gates, gate_name, {:fail, reason})}
      :unhealthy -> {:gate_failed, gate_name, "Health check failed", Map.put(gates, gate_name, :fail)}
      :insufficient -> {:gate_failed, gate_name, "Insufficient resources", Map.put(gates, gate_name, :fail)}
      other -> {:gate_failed, gate_name, inspect(other), Map.put(gates, gate_name, :fail)}
    end
  end

  defp check_health(spec, checker) do
    try do
      checker.(spec)
    catch
      _, _ -> :unhealthy
    end
  end

  defp check_constitution(spec, score_checker) do
    try do
      score = score_checker.(spec)
      if ConstitutionalScore.boot_ready?(score), do: :pass, else: {:fail, "Constitutional score below threshold"}
    catch
      _, _ -> {:fail, "Constitutional score check raised or threw"}
    end
  end

  defp check_capability(spec) do
    mod = spec.module

    with true <- function_exported?(mod, :capabilities, 0),
         capabilities when is_list(capabilities) <- mod.capabilities() do
      missing = Enum.reject(spec.provides, &(&1 in capabilities))

      if missing == [],
        do: :pass,
        else: {:fail, "Declared capabilities not implemented: #{inspect(missing)}"}
    else
      false -> {:fail, "Service does not expose its declared capabilities"}
      _ -> {:fail, "Invalid capabilities/0 result"}
    end
  rescue
    _ -> {:fail, "Capability check raised"}
  end

  defp to_gate(:sufficient), do: :pass
  defp to_gate(:insufficient), do: :insufficient

  defp handle_degraded(spec, reason, acc, failed_crit, gates, service_gates) do
    :telemetry.execute([:tiannara, :cel, :kernel, :service_degraded], %{}, %{service: spec.id, reason: inspect(reason)})
    {[{spec.id, :degraded} | acc], failed_crit, Map.put(gates, spec.id, service_gates)}
  end

  defp handle_failed(spec, reason, acc, failed_crit, gates, service_gates) do
    :telemetry.execute([:tiannara, :cel, :kernel, :service_failed], %{}, %{service: spec.id, reason: inspect(reason)})
    {[{spec.id, :failed} | acc], [spec.id | failed_crit], Map.put(gates, spec.id, service_gates)}
  end
end
