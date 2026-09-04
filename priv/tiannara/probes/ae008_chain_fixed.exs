Mix.Task.run("app.config")
Process.flag(:trap_exit, true)

[mode, out_dir] = System.argv()
File.mkdir_p!(out_dir)

attempt = fn f ->
  try do {:ok, f.()} rescue e -> {:error, "rescue: #{Exception.message(e)}"} catch kind, reason -> {:error, "exit #{inspect(kind)}: #{inspect(reason)}"} end
end

to_jsonable = fn to_jsonable, term ->
  case term do
    {:ok, v} -> %{"ok" => to_jsonable.(to_jsonable, v)}
    {:error, m} -> %{"error" => to_jsonable.(to_jsonable, m)}
    %{__struct__: _} = s -> to_jsonable.(to_jsonable, Map.from_struct(s))
    tuple when is_tuple(tuple) -> tuple |> Tuple.to_list() |> then(fn l -> to_jsonable.(to_jsonable, l) end)
    list when is_list(list) -> Enum.map(list, &to_jsonable.(to_jsonable, &1))
    map when is_map(map) -> Map.new(map, fn {k, v} -> {to_string(k), to_jsonable.(to_jsonable, v)} end)
    pid when is_pid(pid) -> inspect(pid)
    ref when is_reference(ref) -> inspect(ref)
    bool when is_boolean(bool) -> bool
    atom when is_atom(atom) -> Atom.to_string(atom)
    other -> other
  end
end

result =
  case mode do
    "characterize" ->
      attempt.(fn ->
        {:ok, _} = Application.ensure_all_started(:tiannara)
        Process.sleep(1200)
        report = Tiannara.CEL.Kernel.boot_report()
        cis_present = Process.whereis(Tiannara.CIS.Supervisor) != nil
        disc_pid = Process.whereis(Tiannara.Discovery.DiscoverySupervisor)
        %{
          mode: "characterize",
          cis_present: cis_present,
          eos_status: report.status,
          failed_critical: report.failed_critical,
          discovery_supervisor: %{pid: disc_pid != nil, state: report.services[:discovery_supervisor]},
          discovery_whereis: disc_pid != nil,
          event_store_healthy: Tiannara.CEL.Services.EventStore.healthy?(),
          executive_memory_health: Tiannara.CEL.Services.ExecutiveMemory.health(),
          boot_report_services: report.services
        }
      end)

    "diagnose" ->
      attempt.(fn ->
        {:ok, _} = Application.ensure_all_started(:tiannara)
        Process.sleep(1200)
        report = Tiannara.CEL.Kernel.boot_report()

        # Step 1: Functionality probe
        disc_pid = Process.whereis(Tiannara.Discovery.DiscoverySupervisor)
        engine_pid = Process.whereis(Tiannara.Discovery.DiscoveryEngine)
        scheduler_pid = Process.whereis(Tiannara.Discovery.DiscoveryScheduler)
        metrics_pid = Process.whereis(Tiannara.Discovery.DiscoveryMetrics)
        disc_health = try do Tiannara.Discovery.DiscoverySupervisor.health() catch _, e -> {:error, inspect(e)} end
        # Check if DiscoveryEngine can actually handle a call (functional test)
        engine_functional = try do
          # Try a simple call - DiscoveryEngine should respond to something like :health or similar
          # Use Process.info to check if it's alive and not crashed
          engine_pid != nil and Process.alive?(engine_pid) and is_pid(engine_pid)
        catch _, _ -> false
        end
        # Also check if the supervisor's health indicates which children are missing
        missing_children = case disc_health do
          {:degraded, list} when is_list(list) -> list
          _ -> []
        end
        # Discovery is considered functional if at least engine and scheduler are alive, even if supervisor is degraded
        disc_functional = engine_functional and scheduler_pid != nil

        step1 = %{
          disc_pid_alive: disc_pid != nil,
          engine_alive: engine_pid != nil,
          scheduler_alive: scheduler_pid != nil,
          metrics_alive: metrics_pid != nil,
          disc_health: disc_health,
          missing_children: missing_children,
          functional: disc_functional,
          hypothesis: if(not disc_functional, do: "H5_real_failure", else: "proceed")
        }

        # Step 2: Ownership audit - check known supervisors
        known_supervisors = [
          Tiannara.Application,
          Tiannara.CEL.ServiceSupervisor
        ]
        # For DynamicSupervisor, use DynamicSupervisor.which_children
        ownership = Enum.reduce(known_supervisors, [], fn sup, acc ->
          children = try do
            # Try regular Supervisor first
            Supervisor.which_children(sup)
          catch _, _ ->
            try do
              DynamicSupervisor.which_children(sup)
            catch _, _ -> []
            end
          end
          has_disc = Enum.any?(children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoverySupervisor or id == :discovery_supervisor end)
          has_engine = Enum.any?(children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoveryEngine end)
          if has_disc or has_engine, do: [{sup, has_disc, has_engine, length(children)} | acc], else: acc
        end)
        # Check for duplicate ownership by seeing if DiscoveryEngine appears in multiple supervisors' children
        # Also check if trying to start DiscoveryEngine again would give already_started
        already_started_test = try do
          # Try to start DiscoveryEngine under CEL ServiceSupervisor as a probe
          spec = %{id: :discovery_engine_probe_test, start: {Tiannara.Discovery.DiscoveryEngine, :start_link, [[]]}, restart: :temporary}
          case DynamicSupervisor.start_child(Tiannara.CEL.ServiceSupervisor, spec) do
            {:error, {:already_started, _pid}} -> :already_started
            {:ok, pid} ->
              DynamicSupervisor.terminate_child(Tiannara.CEL.ServiceSupervisor, pid)
              :started_fresh
            other -> inspect(other)
          end
        catch _, e -> inspect(e)
        end

        step2 = %{
          ownership_candidates: length(ownership),
          owners: Enum.map(ownership, fn {sup, has_disc, has_engine, count} -> %{sup: inspect(sup), has_disc: has_disc, has_engine: has_engine, child_count: count} end),
          already_started_probe: already_started_test,
          hypothesis: if(already_started_test == :already_started, do: "H1_or_H2", else: "proceed")
        }

        # Step 3: Topology check
        actual_parent = try do
          # Check CEL ServiceSupervisor
          cel_children = try do DynamicSupervisor.which_children(Tiannara.CEL.ServiceSupervisor) catch _, _ -> [] end
          has_disc_in_cel = Enum.any?(cel_children, fn {id, _, _, _} -> id == :discovery_supervisor end)
          if has_disc_in_cel do
            "Tiannara.CEL.ServiceSupervisor"
          else
            app_children = try do Supervisor.which_children(Tiannara.Application) catch _, _ -> [] end
            has_disc_in_app = Enum.any?(app_children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoverySupervisor end)
            if has_disc_in_app do
              "Tiannara.Application"
            else
              "not_found_in_either"
            end
          end
        catch _, _ -> "error"
        end
        intended_parent = "Tiannara.CEL.ServiceSupervisor"
        step3 = %{
          actual_parent: actual_parent,
          intended_parent: intended_parent,
          match: actual_parent == intended_parent,
          hypothesis: if(actual_parent != intended_parent and actual_parent != "not_found_in_either", do: "H3_incorrect_topology", else: "proceed")
        }

        # Step 4: Contract check
        disc_spec = try do
          {:ok, spec} = Tiannara.CEL.Kernel.ServiceRegistry.get(:discovery_supervisor)
          %{health_check: spec.health_check, depends_on: spec.depends_on, criticality: spec.criticality}
        catch _, e -> %{error: inspect(e)}
        end
        health_shape = case disc_health do
          :healthy -> :healthy
          {:degraded, _} -> :degraded_tuple
          {:error, _} -> :error
          other -> inspect(other)
        end
        # The contract for discovery_supervisor is {Tiannara.Discovery.DiscoverySupervisor, :health, []}
        # The implementation returns :healthy or {:degraded, list}
        # EOS check_health normalizes :healthy -> :healthy, :unhealthy -> :unhealthy, true/false etc.
        # But {:degraded, list} is not :healthy, so it will be normalized to :unhealthy -> health gate fails -> degraded
        # This is actually correct: degraded tuple should be treated as not healthy, so EOS correctly classifies as degraded
        # So contract is actually matching: health returns degraded tuple, EOS treats as unhealthy, marks degraded
        contract_ok = health_shape == :degraded_tuple and disc_spec[:health_check] == {Tiannara.Discovery.DiscoverySupervisor, :health, []}
        step4 = %{
          spec: disc_spec,
          health_shape: health_shape,
          contract_match: contract_ok,
          hypothesis: if(not contract_ok, do: "H4_lifecycle_contract_mismatch", else: "proceed")
        }

        # Step 5: Nested startup check
        step5 = %{
          disc_functional: disc_functional,
          already_started: already_started_test == :already_started,
          engine_alive: engine_pid != nil,
          missing_metrics: :discovery_metrics in missing_children,
          hypothesis: if(already_started_test == :already_started and disc_functional, do: "H2_expected_nested_startup", else: "proceed")
        }

        # Final verdict - walk the decision tree in order, but ensure we discover the true cause
        # Based on actual evidence:
        # - Step1: disc_pid false but engine true -> not H5 (engine is functional)
        # - Step2: already_started indicates duplicate or nested
        # - Step3: topology is correct (should be in CEL ServiceSupervisor)
        # - Step4: contract is actually matching (degraded tuple is expected)
        # - Step5: nested startup check
        verdict = cond do
          not disc_functional and missing_children == [] -> %{hypothesis: "H5_real_failure", remedy: "escalate", patch: false, reason: "Discovery not functional at all"}
          :discovery_metrics in missing_children and engine_pid != nil ->
            # The real issue is discovery_metrics not starting, not the engine
            %{hypothesis: "H5_real_failure_metrics", remedy: "investigate_metrics", patch: false, reason: "DiscoveryMetrics failed to start, not duplicate ownership"}
          already_started_test == :already_started and disc_functional ->
            %{hypothesis: "H2_expected_nested_startup", remedy: "classification_fix", patch: true, reason: "DiscoveryEngine already running elsewhere, EOS misclassifies as degraded"}
          length(ownership) > 1 ->
            %{hypothesis: "H1_duplicate_ownership", remedy: "topology_fix", patch: true, reason: "Multiple supervisors claim Discovery"}
          not step3.match ->
            %{hypothesis: "H3_incorrect_topology", remedy: "topology_fix", patch: true, reason: "Discovery under wrong parent"}
          not contract_ok ->
            %{hypothesis: "H4_lifecycle_contract_mismatch", remedy: "contract_fix", patch: true, reason: "Health contract mismatch"}
          true ->
            %{hypothesis: "legitimately_degraded", remedy: "no_change", patch: false, reason: "Discovery is legitimately degraded due to missing metrics child"}
        end

        %{
          mode: "diagnose",
          step1_functionality: step1,
          step2_ownership: step2,
          step3_topology: step3,
          step4_contract: step4,
          step5_nested: step5,
          verdict: verdict,
          eos_report: %{status: report.status, failed_critical: report.failed_critical, discovery_service_state: report.services[:discovery_supervisor]},
          raw_boot_report: report.services
        }
      end)
  end

IO.puts("AE008CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, %{status: "complete", mode: mode, phase: result})))
