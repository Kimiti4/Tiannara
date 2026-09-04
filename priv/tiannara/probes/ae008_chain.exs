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
        disc_state = if disc_pid, do: :alive, else: :dead
        disc_service_state = report.services[:discovery_supervisor]
        es_healthy = Tiannara.CEL.Services.EventStore.healthy?()
        em_health = Tiannara.CEL.Services.ExecutiveMemory.health()
        # capture boot report discovery line
        disc_line = %{service: :discovery_supervisor, state: disc_service_state, pid: disc_pid != nil}
        %{
          mode: "characterize",
          cis_present: cis_present,
          eos_status: report.status,
          failed_critical: report.failed_critical,
          discovery_supervisor: disc_line,
          discovery_whereis: disc_pid != nil,
          event_store_healthy: es_healthy,
          executive_memory_health: em_health,
          boot_report_services: report.services
        }
      end)

    "diagnose" ->
      attempt.(fn ->
        {:ok, _} = Application.ensure_all_started(:tiannara)
        Process.sleep(1200)
        report = Tiannara.CEL.Kernel.boot_report()

        # Step 1: Functionality probe - is Discovery actually functional?
        disc_pid = Process.whereis(Tiannara.Discovery.DiscoverySupervisor)
        engine_pid = Process.whereis(Tiannara.Discovery.DiscoveryEngine)
        scheduler_pid = Process.whereis(Tiannara.Discovery.DiscoveryScheduler)
        metrics_pid = Process.whereis(Tiannara.Discovery.DiscoveryMetrics)
        disc_health = try do Tiannara.Discovery.DiscoverySupervisor.health() catch _, e -> {:error, inspect(e)} end
        # Try to call a Discovery API - e.g., check if engine responds
        engine_alive = engine_pid != nil and Process.alive?(engine_pid)
        scheduler_alive = scheduler_pid != nil and Process.alive?(scheduler_pid)
        disc_functional = disc_pid != nil and engine_alive

        step1 = %{
          disc_pid_alive: disc_pid != nil,
          engine_alive: engine_alive,
          scheduler_alive: scheduler_alive,
          metrics_alive: metrics_pid != nil,
          disc_health: disc_health,
          functional: disc_functional,
          hypothesis: if(not disc_functional, do: "H5_real_failure", else: "proceed")
        }

        # Step 2: Ownership audit - how many supervisors claim Discovery?
        # Enumerate known supervisors from application + CEL + Discovery
        supervisors_to_check = [
          Tiannara.Application,
          Tiannara.CEL.Kernel,
          Tiannara.Discovery.DiscoverySupervisor
        ]
        # Also find all supervisors via Process.list
        all_supervisors = Process.list() |> Enum.filter(fn pid ->
          try do
            info = Process.info(pid, :dictionary)
            case info do
              {:dictionary, dict} ->
                # Check if process is a supervisor by looking at its initial call
                initial = dict[:"$initial_call"]
                initial != nil and String.contains?(inspect(initial), "Supervisor")
              _ -> false
            end
          catch _, _ -> false
          end
        end)
        # More reliable: check which supervisors have Discovery child
        # Try Supervisor.which_children for each known supervisor
        ownership = Enum.reduce(supervisors_to_check, [], fn sup, acc ->
          children = try do Supervisor.which_children(sup) catch _, _ -> [] end
          has_disc = Enum.any?(children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoverySupervisor or id == :discovery_supervisor end)
          has_engine = Enum.any?(children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoveryEngine end)
          if has_disc or has_engine, do: [{sup, has_disc, has_engine} | acc], else: acc
        end)
        # Also check if DiscoveryEngine is claimed by multiple parents (H1)
        # Check where DiscoveryEngine is supposed to be vs where it actually is
        engine_owners = Enum.filter(supervisors_to_check, fn sup ->
          children = try do Supervisor.which_children(sup) catch _, _ -> [] end
          Enum.any?(children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoveryEngine end)
        end)
        # Check via ServiceRegistry or directly: DiscoveryEngine should be child of DiscoverySupervisor only
        # But if it's also started elsewhere (e.g., as standalone), it will be owned elsewhere
        # We can check by trying to find all processes that have DiscoveryEngine as child
        # Simpler: check if DiscoveryEngine is already started before DiscoverySupervisor tries to start it
        # We can detect H1 by seeing if DiscoveryEngine whereis exists independent of DiscoverySupervisor
        # and if DiscoverySupervisor's start would fail with already_started

        # Try to simulate what happens if we try to start DiscoverySupervisor's child again
        already_started_test = try do
          case DynamicSupervisor.start_child(Tiannara.CEL.ServiceSupervisor, %{id: :discovery_engine_probe, start: {Tiannara.Discovery.DiscoveryEngine, :start_link, [[]]}, restart: :temporary}) do
            {:error, {:already_started, _pid}} -> :already_started
            {:ok, pid} ->
              # clean up probe
              DynamicSupervisor.terminate_child(Tiannara.CEL.ServiceSupervisor, pid)
              :started_fresh
            other -> inspect(other)
          end
        catch _, e -> inspect(e)
        end

        step2 = %{
          ownership_candidates: length(ownership),
          owners: Enum.map(ownership, fn {sup, _, _} -> inspect(sup) end),
          engine_owners: Enum.map(engine_owners, &inspect/1),
          already_started_probe: already_started_test,
          hypothesis: if(length(engine_owners) > 1 or already_started_test == :already_started, do: "H1_duplicate_ownership", else: "proceed")
        }

        # Step 3: Topology check - is Discovery under intended parent?
        # Intended parent per design: DiscoverySupervisor should be under Tiannara.Application (as we added for CIS, but Discovery is a CEL service)
        # Actual parent: Check ServiceRegistry boot order and actual supervisor
        # DiscoverySupervisor is a CEL service (discovery_supervisor) - its intended parent is CEL Kernel's DynamicSupervisor (Tiannara.CEL.ServiceSupervisor)
        # Let's check where it actually lives
        actual_parent = try do
          # Check if it's child of CEL ServiceSupervisor
          children = Supervisor.which_children(Tiannara.CEL.ServiceSupervisor)
          if Enum.any?(children, fn {id, _, _, _} -> id == :discovery_supervisor end) do
            "Tiannara.CEL.ServiceSupervisor"
          else
            # Check if it's child of Application
            app_children = Supervisor.which_children(Tiannara.Application)
            if Enum.any?(app_children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoverySupervisor end) do
              "Tiannara.Application"
            else
              "unknown_or_not_found"
            end
          end
        catch _, _ -> "error"
        end
        intended_parent = "Tiannara.CEL.ServiceSupervisor"
        step3 = %{
          actual_parent: actual_parent,
          intended_parent: intended_parent,
          match: actual_parent == intended_parent,
          hypothesis: if(actual_parent != intended_parent and actual_parent != "unknown_or_not_found", do: "H3_incorrect_topology", else: "proceed")
        }

        # Step 4: Contract check - does ServiceRegistry health_check match implementation?
        disc_spec = try do
          {:ok, spec} = Tiannara.CEL.Kernel.ServiceRegistry.get(:discovery_supervisor)
          %{health_check: spec.health_check, depends_on: spec.depends_on}
        catch _, e -> %{error: inspect(e)}
        end
        # Check implementation's health return shape
        health_shape = case disc_health do
          :healthy -> :healthy
          {:degraded, _} -> :degraded_tuple
          {:error, _} -> :error
          other -> inspect(other)
        end
        # EOS expects :healthy or :unhealthy via check_health normalization (from AE-004)
        # If health returns {:degraded, list}, the normalized check will treat it as :unhealthy (since not :healthy)
        expected_contract_match = health_shape in [:healthy, :degraded_tuple]
        step4 = %{
          spec: disc_spec,
          health_shape: health_shape,
          contract_match: expected_contract_match,
          hypothesis: if(not expected_contract_match, do: "H4_lifecycle_contract_mismatch", else: "proceed")
        }

        # Step 5: Nested startup check - is already_started expected?
        # Check if DiscoveryEngine is intentionally started elsewhere before DiscoverySupervisor
        # Look at application.ex core_children: Does it contain DiscoveryEngine separately?
        # And check if DiscoverySupervisor's children are already running before it starts
        # We can check the boot order: discovery_supervisor depends on executive_memory and executive_service_bus
        # If those dependencies are healthy, but DiscoveryEngine is already running, then already_started is due to nested startup
        # We can detect by checking if DiscoveryEngine was alive BEFORE DiscoverySupervisor was started
        # For now, we infer: If Step1 functional, Step2 shows already_started, Step3 topology correct, Step4 contract ok, then H2 is likely
        step5 = %{
          disc_functional: disc_functional,
          already_started: already_started_test == :already_started,
          engine_alive_before_supervisor: engine_alive,
          hypothesis: if(already_started_test == :already_started and disc_functional, do: "H2_expected_nested_startup", else: "proceed")
        }

        # Final verdict decision tree
        verdict = cond do
          not disc_functional -> %{hypothesis: "H5_real_failure", remedy: "escalate", patch: false}
          length(engine_owners) > 1 -> %{hypothesis: "H1_duplicate_ownership", remedy: "topology_fix", patch: true}
          already_started_test == :already_started and disc_functional and step3.match -> %{hypothesis: "H2_expected_nested_startup", remedy: "classification_fix", patch: true}
          not step3.match -> %{hypothesis: "H3_incorrect_topology", remedy: "topology_fix", patch: true}
          not expected_contract_match -> %{hypothesis: "H4_lifecycle_contract_mismatch", remedy: "contract_fix", patch: true}
          true -> %{hypothesis: "legitimately_degraded_or_new_finding", remedy: "no_change", patch: false}
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
          # Include raw evidence for verification
          raw_boot_report: report.services
        }
      end)
  end

IO.puts("AE008CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, %{status: "complete", mode: mode, phase: result})))
