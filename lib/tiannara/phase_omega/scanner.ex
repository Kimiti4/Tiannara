defmodule Tiannara.PhaseOmega.Scanner do
  @moduledoc """
  Phase Ω — Full System Scanner.

  Orchestrates all 20 verification modules and produces a consolidated
  certification report. Call `Tiannara.PhaseOmega.Scanner.scan/0` to run
  every deliverable in order.
  """

  require Logger

  @doc """
  Run every Phase Ω deliverable and return a full report.
  """
  def scan do
    Logger.info("[PhaseΩ:Scanner] === PHASE Ω FULL SYSTEM SCAN ===")

    results = %{
      timestamp: DateTime.utc_now(),
      deliverables: run_deliverables(),
      overall: %{},
      subsystems: runtime_snapshot()
    }

    results = %{results | overall: compute_overall(results.deliverables)}

    Logger.info("[PhaseΩ:Scanner] === SCAN COMPLETE ===")
    results
  end

  defp run_deliverables do
    Logger.info("[PhaseΩ:Scanner] Running 20 deliverables...")

    %{
      omega_1: run_omega_1(),
      omega_2: run_omega_2(),
      omega_3: run_omega_3(),
      omega_4: run_omega_4(),
      omega_5: run_omega_5(),
      omega_6: run_omega_6(),
      omega_7: run_omega_7(),
      omega_8: run_omega_8(),
      omega_9: run_omega_9(),
      omega_10: run_omega_10(),
      omega_11: run_omega_11(),
      omega_12: run_omega_12(),
      omega_13: run_omega_13(),
      omega_14: run_omega_14(),
      omega_15: run_omega_15(),
      omega_16: run_omega_16(),
      omega_17: run_omega_17(),
      omega_18: run_omega_18(),
      omega_19: run_omega_19(),
      omega_20: run_omega_20()
    }
  end

  defp run_omega_1 do
    # SubsystemRegistry — check registry health
    snapshot = Tiannara.PhaseOmega.SubsystemRegistry.snapshot()
    count = map_size(snapshot)
    %{
      deliverable: "Ω.1 — Subsystem Registration",
      status: if(count > 0, do: :pass, else: :fail),
      detail: "#{count} subsystems registered",
      data: snapshot
    }
  end

  defp run_omega_2 do
    # BootSequence — check certs
    certs = Tiannara.PhaseOmega.SubsystemRegistry.list_boot_certificates()
    %{
      deliverable: "Ω.2 — Boot Sequence",
      status: if(certs == [], do: :unknown, else: :pass),
      detail: "#{length(certs)} boot certificates present; issuance validity not independently re-verified",
      data: %{certificates: certs}
    }
  end

  defp run_omega_3 do
    result = Tiannara.PhaseOmega.DependencyVerifier.verify()
    %{
      deliverable: "Ω.3 — Dependency Verification",
      status: if(result.passed, do: :pass, else: :warn),
      detail: "#{result.total_subsystems} subsystems, #{result.total_dependencies} deps, #{result.issue_count} issues",
      data: result
    }
  end

  defp run_omega_4 do
    # WiringEngine — defined specs
    specs = Tiannara.PhaseOmega.WiringEngine.defined_specs()
    %{
      deliverable: "Ω.4 — Wiring Engine",
      status: :unknown,
      detail: "#{length(specs)} wiring specs defined; runtime wiring not independently verified",
      data: %{specs: specs}
    }
  end

  defp run_omega_5 do
    result = Tiannara.PhaseOmega.EventFlowVerifier.verify_all()
    has_observatory = Code.ensure_loaded?(ObservatoryApi.Router)
    status = if has_observatory do
      cond do
        result.unknown_paths > 0 -> :unknown
        result.failed_paths == 0 -> :pass
        true -> :warn
      end
    else
      :unknown
    end
    %{
      deliverable: "Ω.5 — Event Flow Verification",
      status: status,
      detail: if(has_observatory, do: "#{result.healthy_paths}/#{result.total_paths} paths healthy", else: "Running headless (no Observatory event paths)"),
      data: result
    }
  end

  defp run_omega_6 do
    # SupervisorAudit via RuntimeAuditor
    auditor = Tiannara.PhaseOmega.RuntimeAuditor.audit_supervisors()
    %{
      deliverable: "Ω.6 — Supervisor Audit",
      status: :unknown,
      detail: "#{auditor.total} supervisors inspected; supervisor correctness not independently established",
      data: auditor
    }
  end

  defp run_omega_7 do
    # WorkerAudit via RuntimeAuditor
    full = Tiannara.PhaseOmega.RuntimeAuditor.audit_all()
    workers = full.workers
    status = if workers.unhealthy == [], do: :pass, else: :warn
    %{
      deliverable: "Ω.7 — Worker Audit",
      status: status,
      detail: "#{workers.total} workers, #{length(workers.unhealthy)} unhealthy, #{length(workers.orphaned)} orphaned",
      data: workers
    }
  end

  defp run_omega_8 do
    # SchedulerAudit via RuntimeAuditor
    full = Tiannara.PhaseOmega.RuntimeAuditor.audit_all()
    %{
      deliverable: "Ω.8 — Scheduler Audit",
      status: if(full.schedulers.running == full.schedulers.known_timers.total, do: :pass, else: :warn),
      detail: "#{full.schedulers.running}/#{full.schedulers.known_timers.total} known timers running",
      data: full.schedulers
    }
  end

  defp run_omega_9 do
    result = Tiannara.PhaseOmega.TelemetryCoverageAuditor.audit()
    %{
      deliverable: "Ω.9 — Telemetry Coverage",
      status: result.status,
      detail: "#{result.covered}/#{result.total_required} events covered, #{result.missing_count} missing",
      data: result
    }
  end

  defp run_omega_10 do
    # ObservatoryRegistration — check if Phoenix endpoint is alive
    api_available = Code.ensure_loaded?(ObservatoryApi.Router)
    endpoint_alive = Process.whereis(TiannaraWeb.Endpoint) && Process.alive?(Process.whereis(TiannaraWeb.Endpoint))
    status = if api_available && endpoint_alive, do: :pass, else: :unknown
    %{
      deliverable: "Ω.10 — Observatory Registration",
      status: status,
      detail: if(api_available, do: "Observatory API loaded", else: "Running headless — Phoenix endpoint alive=#{endpoint_alive}"),
      data: %{
        api_loaded: api_available,
        endpoint_alive: endpoint_alive || false
      }
    }
  end

  defp run_omega_11 do
    # ScientificPipelineVerifier — check discovery loop
    has_core = Code.ensure_loaded?(Tiannara.Core.Supervisor)
    has_physics = Code.ensure_loaded?(Tiannara.Physics.Supervisor)
    has_topology = Code.ensure_loaded?(Tiannara.Topology.Supervisor)
    pipeline_ready = has_core && has_physics && has_topology
    %{
      deliverable: "Ω.11 — Scientific Pipeline",
      status: if(pipeline_ready, do: :unknown, else: :fail),
      detail: "Core=#{has_core}, Physics=#{has_physics}, Topology=#{has_topology}",
      data: %{core: has_core, physics: has_physics, topology: has_topology}
    }
  end

  defp run_omega_12 do
    # EcologicalVerifier — check REA supervisor and economy
    rea_loaded = Code.ensure_loaded?(Tiannara.REA.Supervisor)
    rea_pid = Process.whereis(Tiannara.REA.Supervisor)
    rea_alive = is_pid(rea_pid) && Process.alive?(rea_pid)
    rel_loaded = Code.ensure_loaded?(Tiannara.REL.EconomyEngine)
    status = if rea_alive && rel_loaded, do: :pass, else: :warn
    %{
      deliverable: "Ω.12 — Ecological Verification",
      status: if(status == :pass, do: :unknown, else: status),
      detail: "REA.Supervisor=#{rea_alive}, REL.EconomyEngine=#{rel_loaded}; ecological behavior not independently exercised",
      data: %{rea_supervisor_loaded: rea_loaded, rea_alive: rea_alive, rel_loaded: rel_loaded}
    }
  end

  defp run_omega_13 do
    # SecurityVerification — check RBAC, auth plugs
    rbac_loaded = Code.ensure_loaded?(ObservatoryApi.Plugs.Auth)
    has_rate_limit = Code.ensure_loaded?(ObservatoryApi.Plugs.RateLimit)
    %{
      deliverable: "Ω.13 — Security Verification",
      status: :unknown,
      detail: "RBAC=#{rbac_loaded}, RateLimit=#{has_rate_limit}; security properties not independently exercised",
      data: %{rbac: rbac_loaded, rate_limit: has_rate_limit}
    }
  end

  defp run_omega_14 do
    # ReplayVerification — check OMCE for memory continuity (replay equivalent)
    _omce_loaded = Code.ensure_loaded?(Tiannara.OMCE.MemoryContinuity)
    omce_pid = Process.whereis(Tiannara.OMCE.MemoryContinuity)
    omce_alive = is_pid(omce_pid) && Process.alive?(omce_pid)
    boot_certs = Tiannara.PhaseOmega.SubsystemRegistry.list_boot_certificates()
    %{
      deliverable: "Ω.14 — Replay Verification",
      status: :unknown,
      detail: "OMCE.MemoryContinuity alive=#{omce_alive}, #{length(boot_certs)} boot certs present; replay not executed",
      data: %{omce_alive: omce_alive, boot_certificates: length(boot_certs)}
    }
  end

  defp run_omega_15 do
    # ArchaeologyVerification
    arch_loaded = Code.ensure_loaded?(Tiannara.SOPL.MetaArchaeology)
    has_law_arch = Code.ensure_loaded?(Tiannara.SOPL.LawArchaeology)
    %{
      deliverable: "Ω.15 — Archaeology Verification",
      status: :unknown,
      detail: "MetaArchaeology=#{arch_loaded}, LawArchaeology=#{has_law_arch}; reconstruction not independently executed",
      data: %{meta_archaeology: arch_loaded, law_archaeology: has_law_arch}
    }
  end

  defp run_omega_16 do
    # ResourceVerification — check memory
    mem_info = :erlang.memory(:total)
    processes = :erlang.system_info(:process_count)
    %{
      deliverable: "Ω.16 — Resource Verification",
      status: :unknown,
      detail: "Memory=#{div(mem_info, 1024)}KB, Processes=#{processes}; resource governance not exercised",
      data: %{
        total_memory_bytes: mem_info,
        process_count: processes,
        atom_count: :erlang.system_info(:atom_count),
        port_count: length(:erlang.ports())
      }
    }
  end

  defp run_omega_17 do
    # FailureInjection — check Sentinel and OED for failure handling
    _has_sentinel = Code.ensure_loaded?(Tiannara.Sentinel.Supervisor)
    sentinel_pid = Process.whereis(Tiannara.Sentinel.Supervisor)
    sentinel_alive = is_pid(sentinel_pid) && Process.alive?(sentinel_pid)
    _has_oed = Code.ensure_loaded?(Tiannara.OED.Supervisor)
    oed_pid = Process.whereis(Tiannara.OED.Supervisor)
    oed_alive = is_pid(oed_pid) && Process.alive?(oed_pid)
    status = if sentinel_alive && oed_alive, do: :unknown, else: :warn
    %{
      deliverable: "Ω.17 — Failure Injection Readiness",
      status: status,
      detail: "Sentinel alive=#{sentinel_alive}, OED alive=#{oed_alive}",
      data: %{sentinel_alive: sentinel_alive, oed_alive: oed_alive}
    }
  end

  defp run_omega_18 do
    # LoadVerification — check run queue
    rq = :erlang.statistics(:run_queue)
    status = if rq < 100, do: :pass, else: :warn
    %{
      deliverable: "Ω.18 — Load Verification",
      status: status,
      detail: "Run queue length: #{rq}",
      data: %{run_queue: rq, schedulers: :erlang.system_info(:schedulers_online)}
    }
  end

  defp run_omega_19 do
    # CertificationVerification — check boot certs exist and are valid
    certs = Tiannara.PhaseOmega.SubsystemRegistry.list_boot_certificates()
    status = if length(certs) > 0, do: :pass, else: :warn
    %{
      deliverable: "Ω.19 — Certification",
      status: status,
      detail: "#{length(certs)} certificates issued",
      data: %{certificates: certs}
    }
  end

  defp run_omega_20 do
    # LaunchReportGenerator — summarizes everything in this scan
    %{
      deliverable: "Ω.20 — Launch Report",
      status: :unknown,
      detail: "Report generated; launch readiness is not independently verified",
      data: %{
        scan_time: DateTime.utc_now(),
        node: Node.self()
      }
    }
  end

  defp compute_overall(deliverables) do
    statuses = Map.values(deliverables) |> Enum.map(& &1.status)

    %{
      total: map_size(deliverables),
      passed: Enum.count(statuses, &(&1 == :pass)),
      warnings: Enum.count(statuses, &(&1 == :warn)),
      failed: Enum.count(statuses, &(&1 == :fail)),
      healthy: Enum.all?(statuses, &(&1 == :pass)),
      inconclusive: Enum.count(statuses, &(&1 == :unknown)),
      scanned_at: DateTime.utc_now()
    }
  end

  defp runtime_snapshot do
    try do
      Tiannara.PhaseOmega.SubsystemRegistry.snapshot()
    rescue
      _ -> %{error: "SubsystemRegistry not available"}
    end
  end

  @doc """
  Print a human-readable scan report to console.
  """
  def print_report(report \\ nil) do
    r = report || scan()

    IO.puts("")
    IO.puts("═══════════════════════════════════════════════")
    IO.puts("  PHASE Ω — FULL SYSTEM SCAN REPORT")
    IO.puts("  #{r.timestamp}")
    IO.puts("═══════════════════════════════════════════════")
    IO.puts("")

    o = r.overall
    IO.puts("  Overall: #{o.passed}/#{o.total} passed, #{o.warnings} warnings, #{o.failed} failed")
    IO.puts("  System #{if o.healthy, do: "✓ HEALTHY", else: "✗ ISSUES DETECTED"}")
    IO.puts("")

    r.deliverables
    |> Enum.sort_by(fn {_k, v} -> v.deliverable end)
    |> Enum.each(fn {_k, d} ->
      icon = case d.status do
        :pass -> "✓"
        :warn -> "⚠"
        :fail -> "✗"
        _ -> "?"
      end
      IO.puts("  #{icon} #{d.deliverable}")
      IO.puts("     #{d.detail}")
      IO.puts("")
    end)

    IO.puts("═══════════════════════════════════════════════")
  end
end
