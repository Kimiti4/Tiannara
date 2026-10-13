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
          resource_checker :: (ServiceRegistry.service_spec() -> :sufficient | :insufficient)
        ) :: boot_result()
  def boot(starter, health_checker, score_checker, resource_checker) do
    start_time = System.monotonic_time(:millisecond)
    order = ServiceRegistry.boot_order()

    {results, failed_critical, gate_results} =
      Enum.reduce(order, {[], [], %{}}, fn spec, {acc, failed_crit, gates} ->
        deps_ok = not Enum.any?(spec.depends_on, &(&1 in failed_crit))

        if not deps_ok do
          {[{spec.id, :skipped} | acc], failed_crit, gates}
        else
          case run_gates(spec, starter, health_checker, score_checker, resource_checker) do
            {:ok, service_gates} ->
              :telemetry.execute([:tiannara, :cel, :kernel, :service_booted], %{}, %{
                service: spec.id
              })

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

  @spec capability_gate(module()) :: :pass | {:fail, String.t()}
  def capability_gate(module) do
    Code.ensure_loaded(module)

    if function_exported?(module, :__tiannara_stub__, 0) and module.__tiannara_stub__() do
      {:fail, "Service module is an explicit stub"}
    else
      :pass
    end
  end

  defp run_gates(spec, starter, health_checker, score_checker, resource_checker) do
    gates = %{}

    with {:ok, gates} <- run_gate(:dependency, gates, fn -> :pass end),
         {:ok, _pid} <- starter.(spec),
         {:ok, gates} <- run_gate(:health, gates, fn -> check_health(spec, health_checker) end),
         {:ok, gates} <-
           run_gate(:constitution, gates, fn -> check_constitution(spec, score_checker) end),
         {:ok, gates} <- run_gate(:capability, gates, fn -> capability_gate(spec.module) end),
         {:ok, gates} <-
           run_gate(:resource, gates, fn -> resource_checker.(spec) |> to_gate() end) do
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
      :pass ->
        {:ok, Map.put(gates, gate_name, :pass)}

      :healthy ->
        {:ok, Map.put(gates, gate_name, :pass)}

      :sufficient ->
        {:ok, Map.put(gates, gate_name, :pass)}

      {:fail, reason} ->
        {:gate_failed, gate_name, reason, Map.put(gates, gate_name, {:fail, reason})}

      :unhealthy ->
        {:gate_failed, gate_name, "Health check failed", Map.put(gates, gate_name, :fail)}

      :insufficient ->
        {:gate_failed, gate_name, "Insufficient resources", Map.put(gates, gate_name, :fail)}

      other ->
        {:gate_failed, gate_name, inspect(other), Map.put(gates, gate_name, :fail)}
    end
  end

  defp check_health(spec, checker) do
    try do
      checker.(spec)
    catch
      _, _ -> :unhealthy
    end
  end

  @max_evidence_age_seconds 300

  @doc """
  Constitution gate.

  Fails closed and never self-certifies:

    * explicit stub modules are refused here (detection reused from
      `capability_gate/1` — the single stub-detection source);
    * a score checker that raises or returns a non-score yields a named
      failure instead of the former silent `:pass`;
    * a below-threshold score reports the aggregate and health actually
      observed;
    * a boot-ready claim is credited only after independent corroboration
      (B12/D-C): process liveness, health observation outside the score
      path, advertised-capability executability, and evidence freshness.
      Missing, malformed, stale, or contradictory evidence fails closed —
      `ConstitutionalScore.default/1` is never substituted for a failed
      corroboration.

  Public for direct gate-honesty testing (see
  `boot_sequencer_gate_honesty_test.exs` and
  `boot_sequencer_value_gate_test.exs`); the boot path calls it with the
  default evidence collector.
  """
  @spec check_constitution(
          map(),
          (map() -> ConstitutionalScore.t()),
          (map() -> map())
        ) :: :pass | {:fail, String.t()}
  def check_constitution(spec, score_checker, evidence_fun \\ &independent_evidence/1) do
    case capability_gate(spec.module) do
      {:fail, reason} ->
        {:fail, reason}

      :pass ->
        try do
          score = score_checker.(spec)

          if ConstitutionalScore.boot_ready?(score) do
            corroborate_claim(spec, score, evidence_fun)
          else
            {:fail,
             "Constitutional score not boot-ready (aggregate=#{ConstitutionalScore.aggregate(score)}, health=#{score.health})"}
          end
        catch
          kind, reason ->
            {:fail,
             "constitutional score check failed (#{kind}: #{inspect(reason)}) — fail closed"}
        end
    end
  end

  @doc """
  Independent corroboration evidence for a claimed constitutional score (B12/D-C).

  Collected without consulting `constitutional_score/0`:

    * `process_alive` — `Process.whereis/1` on the registered service module;
    * `health_observed` — `healthy?/0` when exported (state-querying),
      else the registry `health_check` MFA, else `health/0`; raising or
      absent yields `:unknown` (never silently `:healthy`);
    * `capability_probes` — executability probes for advertised
      `provides:`/`capabilities/0` atoms where a probe exists;
      unprobed atoms are `:unverified` (not a pass signal, not a failure
      by themselves);
    * `collected_at` — freshness stamp for the evidence itself.
  """
  @spec independent_evidence(map()) :: map()
  def independent_evidence(spec) do
    %{
      collected_at: DateTime.utc_now(),
      process_alive: process_alive?(spec),
      health_observed: observe_health(spec),
      capability_probes: probe_provides(spec)
    }
  end

  defp corroborate_claim(spec, score, evidence_fun) do
    evidence = evidence_fun.(spec)
    decide_corroboration(score, evidence)
  rescue
    e ->
      {:fail, "constitutional corroboration failed (rescue: #{inspect(e)}) — fail closed"}
  catch
    kind, reason ->
      {:fail, "constitutional corroboration failed (#{kind}: #{inspect(reason)}) — fail closed"}
  end

  defp decide_corroboration(score, evidence) when is_map(evidence) do
    required = [:collected_at, :process_alive, :health_observed, :capability_probes]
    missing = required -- Map.keys(evidence)

    cond do
      missing != [] ->
        {:fail,
         "corroboration evidence malformed (missing keys #{inspect(missing)}) — fail closed"}

      not match?(%DateTime{}, evidence.collected_at) ->
        {:fail, "corroboration evidence malformed (collected_at not a DateTime) — fail closed"}

      not is_boolean(evidence.process_alive) ->
        {:fail, "corroboration evidence malformed (process_alive not a boolean) — fail closed"}

      not is_map(evidence.capability_probes) ->
        {:fail, "corroboration evidence malformed (capability_probes not a map) — fail closed"}

      stale?(score.computed_at) ->
        {:fail,
         "constitutional score stale (computed_at=#{inspect(score.computed_at)}) — fail closed"}

      stale?(evidence.collected_at) ->
        {:fail,
         "corroboration evidence stale (collected_at=#{inspect(evidence.collected_at)}) — fail closed"}

      not evidence.process_alive ->
        {:fail, "service process not independently observed as alive — fail closed"}

      evidence.health_observed == :unhealthy and score.health >= 0.5 ->
        {:fail,
         "claimed health contradicted by observation (score.health=#{score.health}, observed=unhealthy) — fail closed"}

      evidence.health_observed != :healthy and score.health >= 0.5 ->
        {:fail,
         "claimed health not independently corroborated (observed=#{inspect(evidence.health_observed)}) — fail closed"}

      (unavailable =
         Enum.find(evidence.capability_probes, fn {_cap, result} -> result == :unavailable end)) !=
          nil ->
        {:fail,
         "advertised capability not independently executable: #{elem(unavailable, 0)} — fail closed"}

      true ->
        :pass
    end
  end

  defp decide_corroboration(_score, _evidence) do
    {:fail, "corroboration evidence malformed (not a map) — fail closed"}
  end

  defp stale?(%DateTime{} = at) do
    age = DateTime.diff(DateTime.utc_now(), at, :second)
    age > @max_evidence_age_seconds or age < -60
  end

  defp stale?(_), do: true

  defp process_alive?(spec) do
    is_pid(Process.whereis(spec.module))
  end

  defp observe_health(spec) do
    mod = spec.module
    Code.ensure_loaded(mod)

    cond do
      function_exported?(mod, :healthy?, 0) ->
        apply(mod, :healthy?, []) |> normalize_health()

      Map.has_key?(spec, :health_check) ->
        {m, f, args} = spec.health_check
        apply(m, f, args) |> normalize_health()

      function_exported?(mod, :health, 0) ->
        apply(mod, :health, []) |> normalize_health()

      true ->
        :unknown
    end
  rescue
    _ -> :unknown
  catch
    _, _ -> :unknown
  end

  defp normalize_health(true), do: :healthy
  defp normalize_health(false), do: :unhealthy
  defp normalize_health(:healthy), do: :healthy
  defp normalize_health(:unhealthy), do: :unhealthy
  defp normalize_health({:degraded, _}), do: :unhealthy
  defp normalize_health(_), do: :unknown

  defp probe_provides(spec) do
    spec
    |> advertised_capabilities()
    |> Map.new(fn cap -> {cap, probe_capability(spec, cap)} end)
  end

  defp advertised_capabilities(spec) do
    cond do
      is_list(Map.get(spec, :provides)) ->
        spec.provides

      true ->
        mod = spec.module
        Code.ensure_loaded(mod)

        if function_exported?(mod, :capabilities, 0) do
          mod.capabilities()
        else
          []
        end
    end
  rescue
    _ -> []
  end

  # Executability probe for the calibration capability (B12). Calls the
  # service's own replay handler with a bounded timeout — never the
  # public replay/2 default of one hour — so a wedged mailbox cannot
  # hang boot. Other advertised atoms remain :unverified (no probe).
  defp probe_capability(spec, :deterministic_replay) do
    mod = spec.module

    if is_pid(Process.whereis(mod)) and function_exported?(mod, :replay, 2) do
      try do
        case GenServer.call(mod, {:replay, :b12_probe, :b12_probe, []}, 5_000) do
          {:error, _} -> :unavailable
          {:ok, _} -> :available
          _ -> :unverified
        end
      catch
        :exit, _ -> :unavailable
        _, _ -> :unverified
      end
    else
      :unverified
    end
  end

  defp probe_capability(_spec, _cap), do: :unverified

  defp to_gate(:sufficient), do: :pass
  defp to_gate(:insufficient), do: :insufficient

  defp handle_degraded(spec, reason, acc, failed_crit, gates, service_gates) do
    :telemetry.execute([:tiannara, :cel, :kernel, :service_degraded], %{}, %{
      service: spec.id,
      reason: inspect(reason)
    })

    {[{spec.id, :degraded} | acc], failed_crit, Map.put(gates, spec.id, service_gates)}
  end

  defp handle_failed(spec, reason, acc, failed_crit, gates, service_gates) do
    :telemetry.execute([:tiannara, :cel, :kernel, :service_failed], %{}, %{
      service: spec.id,
      reason: inspect(reason)
    })

    {[{spec.id, :failed} | acc], [spec.id | failed_crit], Map.put(gates, spec.id, service_gates)}
  end
end
