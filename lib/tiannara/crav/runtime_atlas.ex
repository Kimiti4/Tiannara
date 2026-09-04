defmodule Tiannara.CRAV.RuntimeAtlas do
  @moduledoc """
  Generates the Constitutional Runtime Atlas — a comprehensive map
  of the entire Tiannara system including subsystems, supervision
  tree, event streams, telemetry coverage, dependency graph,
  certification status, and alpha readiness.
  """

  require Logger

  @telemetry_event [:tiannara, :crav, :atlas, :generated]

  @known_subsystems [
    :rea, :sopl, :cis, :msg, :omce, :hsv, :grcc, :oed, :ctl, :a10, :ucc,
    :asc, :world_model, :sentinel, :planetary_twin, :discovery_pipeline,
    :engineering_pipeline, :simulation_runtime, :theory_ecology, :knowledge_graph,
    :civilization_runtime, :omcs, :olef, :opc, :nde, :twp, :ird, :acf, :ccr,
    :dfg, :osl, :rrg, :ros, :rel, :civilization_kernel, :telemetry, :phase_omega
  ]

  @subsystem_descriptions %{
    rea: "Reality Encoding Architecture — observation and evidence pipeline",
    sopl: "Self-Organizing Principle Layer — emergent behavior coordination",
    cis: "Constitutional Integrity System — constraint enforcement",
    msg: "Messaging Subsystem — inter-module communication",
    omce: "Objective Model Calibration Engine — model parameter optimization",
    hsv: "Hypothesis Selection Vector — hypothesis prioritization",
    grcc: "Global Resource Coordination Controller — resource allocation",
    oed: "Observation Event Dispatcher — sensor event routing",
    ctl: "Control Layer — regulatory feedback loops",
    a10: "A10 Cognitive Module — high-level reasoning",
    ucc: "Unified Context Coordinator — context management",
    asc: "Adaptive System Controller — self-modification engine",
    world_model: "World Model — planetary state representation",
    sentinel: "Sentinel — anomaly detection and health monitoring",
    planetary_twin: "Planetary Twin — Earth system simulation",
    discovery_pipeline: "Discovery Pipeline — hypothesis-to-evidence pipeline",
    engineering_pipeline: "Engineering Pipeline — theory-to-deployment pipeline",
    simulation_runtime: "Simulation Runtime — parallel simulation execution",
    theory_ecology: "Theory Ecology — competing theory management",
    knowledge_graph: "Knowledge Graph — semantic knowledge representation",
    civilization_runtime: "Civilization Runtime — multi-agent civilization simulation",
    omcs: "Observatory Model Checkpoint System — model versioning",
    olef: "Observatory Log Enrichment Framework — log enrichment",
    opc: "Observatory Policy Controller — policy enforcement",
    nde: "Null Detector Engine — null hypothesis testing",
    twp: "Theory Weighting Pipeline — theory confidence scoring",
    ird: "Intervention Response Dispatcher — intervention coordination",
    acf: "Adaptive Calibration Framework — parameter auto-tuning",
    ccr: "Constitutional Compliance Reporter — compliance tracking",
    dfg: "Data Flow Graph — data lineage tracking",
    osl: "Observation Signal Layer — signal processing",
    rrg: "Resource Reservation Graph — resource scheduling",
    ros: "Runtime Observability System — system observability",
    rel: "Relativity Module — relativistic computation",
    civilization_kernel: "Civilization Kernel — core civilization primitives",
    telemetry: "Telemetry — system metrics collection",
    phase_omega: "Phase Omega — constitutional runtime verification"
  }

  @subsystem_module_map %{
    rea: Tiannara.REA,
    sopl: Tiannara.SOPL,
    cis: Tiannara.CIS,
    msg: Tiannara.MSG,
    omce: Tiannara.OMCE,
    hsv: Tiannara.HSV,
    grcc: Tiannara.GRCC,
    oed: Tiannara.OED,
    ctl: Tiannara.CTL,
    a10: Tiannara.A10,
    asc: Tiannara.ASC,
    world_model: Tiannara.WorldModel,
    sentinel: Tiannara.Sentinel,
    planetary_twin: Tiannara.PlanetaryTwin,
    discovery_pipeline: Tiannara.DiscoveryPipeline,
    engineering_pipeline: Tiannara.EngineeringPipeline,
    simulation_runtime: Tiannara.SimulationRuntime,
    theory_ecology: Tiannara.TheoryEcology,
    knowledge_graph: Tiannara.KnowledgeGraph,
    civilization_runtime: Tiannara.CivilizationRuntime,
    telemetry: Tiannara.Telemetry,
    phase_omega: Tiannara.PhaseOmega
  }

  @spec generate() :: {:ok, map()} | {:error, term()}
  def generate do
    try do
      subsystems = build_subsystems()
      supervision_tree = build_supervision_tree()
      event_streams = build_event_streams()
      telemetry_coverage = compute_telemetry_coverage(subsystems)
      dependency_graph = build_dependency_graph(subsystems)
      certification_status = compute_certification_status()
      alpha_readiness = compute_alpha_readiness(subsystems)

      atlas = %{
        title: "Tiannara Constitutional Runtime Atlas",
        version: "1.0.0",
        generated_at: DateTime.utc_now(),
        subsystems: subsystems,
        supervision_tree: supervision_tree,
        event_streams: event_streams,
        telemetry_coverage: telemetry_coverage,
        dependency_graph: dependency_graph,
        certification_status: certification_status,
        alpha_readiness: alpha_readiness
      }

      measurements = %{
        subsystem_count: length(subsystems),
        running_count: Enum.count(subsystems, &(&1.state == :running)),
        overall_readiness: alpha_readiness.overall
      }

      metadata = %{timestamp: atlas.generated_at, version: atlas.version}
      :telemetry.execute(@telemetry_event, measurements, metadata)

      Logger.info("[RuntimeAtlas] Generated — #{length(subsystems)} subsystems mapped")

      {:ok, atlas}
    rescue
      err -> {:error, {:atlas_generation_failed, err}}
    catch
      kind, reason -> {:error, {:atlas_crashed, kind, reason}}
    end
  end

  @spec export() :: {:ok, String.t()} | {:error, term()}
  def export do
    case generate() do
      {:ok, atlas} ->
        File.mkdir_p!("data")
        path = "data/runtime_atlas.json"

        serializable = %{
          title: atlas.title,
          version: atlas.version,
          generated_at: DateTime.to_iso8601(atlas.generated_at),
          subsystem_count: length(atlas.subsystems),
          subsystems: Enum.map(atlas.subsystems, fn s ->
            %{
              name: Atom.to_string(s.name),
              module: module_to_string(s.module),
              description: s.description,
              state: Atom.to_string(s.state),
              dependencies: Enum.map(s.dependencies, &Atom.to_string/1),
              certification: s.certification
            }
          end),
          telemetry_coverage: atlas.telemetry_coverage,
          certification_status: serialize_certification(atlas.certification_status),
          alpha_readiness: serialize_readiness(atlas.alpha_readiness)
        }

        case Jason.encode(serializable, pretty: true) do
          {:ok, json} ->
            File.write!(path, json)
            Logger.info("[RuntimeAtlas] Exported to #{path}")
            {:ok, path}

          {:error, err} ->
            {:error, {:json_encode_failed, err}}
        end

      err ->
        err
    end
  end

  @spec print() :: {:ok, String.t()} | {:error, term()}
  def print do
    case generate() do
      {:ok, atlas} ->
        running = Enum.count(atlas.subsystems, &(&1.state == :running))
        dormant = Enum.count(atlas.subsystems, &(&1.state == :dormant))
        planned = Enum.count(atlas.subsystems, &(&1.state == :planned))

        lines =
          [
            "═══════════════════════════════════════════════════════════",
            "  TIANNARA CONSTITUTIONAL RUNTIME ATLAS v#{atlas.version}",
            "  Generated: #{DateTime.to_iso8601(atlas.generated_at)}",
            "═══════════════════════════════════════════════════════════",
            "  Subsystems: #{length(atlas.subsystems)}  |  Running: #{running}  |  Dormant: #{dormant}  |  Planned: #{planned}",
            "",
            "  Telemetry Coverage: #{atlas.telemetry_coverage.percentage}%",
            "  Overall Readiness: #{atlas.alpha_readiness.overall}%",
            "  Recommendation: #{Atom.to_string(atlas.alpha_readiness.recommendation) |> String.upcase()}",
            "───────────────────────────────────────────────────────────"
          ] ++
          Enum.map(atlas.subsystems, fn s ->
            name_str = s.name |> Atom.to_string() |> String.pad_trailing(24)
            state_str = s.state |> Atom.to_string() |> String.pad_trailing(10)
            mod_str = module_to_short_string(s.module)

            "  #{name_str} #{state_str} #{mod_str}"
          end) ++
          [
            "───────────────────────────────────────────────────────────",
            "  Certification Status:",
            format_cert_line("Boot", atlas.certification_status.boot_certificate),
            format_cert_line("Health", atlas.certification_status.health_certificate),
            format_cert_line("Observability", atlas.certification_status.observability_certificate),
            format_cert_line("Replay", atlas.certification_status.replay_certificate),
            format_cert_line("Security", atlas.certification_status.security_certificate),
            format_cert_line("Performance", atlas.certification_status.performance_certificate),
            format_cert_line("Scientific", atlas.certification_status.scientific_certificate),
            format_cert_line("Integration", atlas.certification_status.integration_certificate),
            format_cert_line("Overall", atlas.certification_status.overall_certificate),
            "═══════════════════════════════════════════════════════════"
          ]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
  end

  @spec verify() :: {:ok, map()} | {:error, term()}
  def verify do
    case generate() do
      {:ok, atlas} ->
        checks = Enum.map(atlas.subsystems, fn subsystem ->
          compliant = verify_subsystem(subsystem)

          %{
            name: subsystem.name,
            module: subsystem.module,
            expected_state: subsystem.state,
            compliant: compliant,
            issues: identify_issues(subsystem)
          }
        end)

        compliant_count = Enum.count(checks, & &1.compliant)
        total = length(checks)
        compliance_pct = if total > 0, do: Float.round(compliant_count / total * 100, 1), else: 0.0

        report = %{
          timestamp: DateTime.utc_now(),
          total_subsystems: total,
          compliant: compliant_count,
          non_compliant: total - compliant_count,
          compliance_percentage: compliance_pct,
          checks: checks
        }

        :telemetry.execute(
          [:tiannara, :crav, :atlas, :verified],
          %{compliance_pct: compliance_pct, non_compliant: total - compliant_count},
          %{timestamp: report.timestamp}
        )

        {:ok, report}

      err ->
        err
    end
  end

  defp build_subsystems do
    Enum.map(@known_subsystems, fn name ->
      mod = Map.get(@subsystem_module_map, name)
      description = Map.get(@subsystem_descriptions, name, "Undocumented subsystem")
      state = determine_state(name, mod)
      children = discover_children(mod)
      dependencies = discover_dependencies(name)
      telemetry_events = discover_telemetry_events(name)
      health_probes = build_health_probes(mod)
      certification = determine_certification(name, mod)

      %{
        name: name,
        module: mod,
        description: description,
        supervisor: find_supervisor(mod),
        children: children,
        dependencies: dependencies,
        state: state,
        telemetry_events: telemetry_events,
        health_probes: health_probes,
        certification: certification
      }
    end)
  end

  defp determine_state(name, nil) do
    registry_state(name) || :planned
  end

  defp determine_state(name, mod) do
    cond do
      Code.ensure_loaded?(mod) and has_live_process?(mod) -> :running
      Code.ensure_loaded?(mod) -> :dormant
      true -> registry_state(name) || :planned
    end
  end

  defp registry_state(name) do
    try do
      if Code.ensure_loaded?(Tiannara.PhaseOmega.SubsystemRegistry) and
           Process.whereis(Tiannara.PhaseOmega.SubsystemRegistry) do
        case Tiannara.PhaseOmega.SubsystemRegistry.get(name) do
          nil -> nil
          %{status: :alive} -> :running
          %{status: :booted} -> :dormant
          _ -> :dormant
        end
      else
        nil
      end
    rescue
      _ -> nil
    catch
      _, _ -> nil
    end
  end

  defp has_live_process?(mod) do
    pid = Process.whereis(mod)
    is_pid(pid) and Process.alive?(pid)
  rescue
    _ -> false
  end

  defp discover_children(nil), do: []

  defp discover_children(mod) do
    case Process.whereis(mod) do
      pid when is_pid(pid) ->
        try do
          Supervisor.which_children(pid)
          |> Enum.map(fn
            {id, _child_pid, _type, _mods} -> id
            other -> other
          end)
        rescue
          _ -> []
        catch
          _, _ -> []
        end

      _ ->
        []
    end
  end

  defp discover_dependencies(name) do
    try do
      if Code.ensure_loaded?(Tiannara.CRAV.RuntimeDependencyGraph) do
        case Tiannara.CRAV.RuntimeDependencyGraph.graph() do
          {:ok, entries} ->
            case Enum.find(entries, &(&1.name == name)) do
              nil -> []
              entry -> entry.depends_on
            end

          _ ->
            []
        end
      else
        []
      end
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp discover_telemetry_events(name) do
    try do
      prefix = [:tiannara, name]

      :telemetry.list_handlers(prefix)
      |> Enum.map(fn handler ->
        case Map.get(handler, :event_name) do
          event when is_list(event) -> event
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp build_health_probes(nil), do: []

  defp build_health_probes(mod) do
    probes = []

    probes =
      if function_exported?(mod, :status, 0) do
        probes ++ [{mod, :status, []}]
      else
        probes
      end

    probes =
      if function_exported?(mod, :health, 0) do
        probes ++ [{mod, :health, []}]
      else
        probes
      end

    probes
  rescue
    _ -> []
  end

  defp find_supervisor(nil), do: nil

  defp find_supervisor(mod) do
    supervisor_mod = Module.concat(mod, Supervisor)

    if Code.ensure_loaded?(supervisor_mod) do
      supervisor_mod
    else
      nil
    end
  end

  defp determine_certification(_name, nil), do: nil

  defp determine_certification(name, _mod) do
    cert_mod = Module.concat([Tiannara, Observatory, Certification])

    try do
      if Code.ensure_loaded?(cert_mod) and
           function_exported?(cert_mod, :status_for, 1) do
        case apply(cert_mod, :status_for, [name]) do
          {:ok, cert} -> cert
          _ -> nil
        end
      else
        nil
      end
    rescue
      _ -> nil
    catch
      _, _ -> nil
    end
  end

  defp build_supervision_tree do
    %{
      root: Tiannara.Application,
      children: build_tree_children()
    }
  end

  defp build_tree_children do
    core_supervisors = [
      Tiannara.REA.Supervisor,
      Tiannara.SOPL.Supervisor,
      Tiannara.CIS.Supervisor,
      Tiannara.MSG.Supervisor,
      Tiannara.OMCE.Supervisor,
      Tiannara.Sentinel.Supervisor,
      Tiannara.WorldModel.Supervisor,
      Tiannara.DiscoveryPipeline.Supervisor,
      Tiannara.KnowledgeGraph.Supervisor,
      Tiannara.CivilizationRuntime.Supervisor
    ]

    Enum.reduce(core_supervisors, %{}, fn sup, acc ->
      name = sup |> Atom.to_string() |> String.replace("Elixir.", "") |> String.to_atom()
      children = supervisor_children(sup)

      subtree = if children == [] do
        %{leaf: true}
      else
        %{leaf: false, children: children}
      end

      Map.put(acc, name, subtree)
    end)
  end

  defp supervisor_children(sup) do
    case Process.whereis(sup) do
      pid when is_pid(pid) ->
        try do
          Supervisor.which_children(pid)
          |> Enum.map(fn {id, _pid, _type, _mods} ->
            key = id |> to_string() |> String.to_atom()
            key
          end)
          |> Enum.into(%{}, fn k -> {k, %{leaf: true}} end)
        rescue
          _ -> %{}
        catch
          _, _ -> %{}
        end

      _ ->
        %{}
    end
  end

  defp build_event_streams do
    [
      %{name: :discovery_events, source: Tiannara.DiscoveryPipeline, consumers: [Tiannara.KnowledgeGraph, Tiannara.TheoryEcology], frequency: :continuous},
      %{name: :evidence_events, source: Tiannara.REA, consumers: [Tiannara.KnowledgeGraph, Tiannara.Sentinel], frequency: :continuous},
      %{name: :anomaly_events, source: Tiannara.Sentinel, consumers: [Tiannara.WorldModel, Tiannara.CivilizationRuntime], frequency: :on_detection},
      %{name: :health_events, source: Tiannara.Telemetry, consumers: [Tiannara.PhaseOmega], frequency: :periodic},
      %{name: :model_update_events, source: Tiannara.WorldModel, consumers: [Tiannara.PlanetaryTwin, Tiannara.TheoryEcology], frequency: :on_update},
      %{name: :certification_events, source: Module.concat([Tiannara, Observatory, Certification]), consumers: [Tiannara.PhaseOmega], frequency: :on_certify}
    ]
    |> Enum.reject(fn stream ->
      not Code.ensure_loaded?(stream.source)
    end)
  end

  defp compute_telemetry_coverage(subsystems) do
    total_events = count_total_telemetry_events()
    covered = Enum.count(subsystems, fn s -> s.telemetry_events != [] end)
    total = length(subsystems)

    percentage = if total > 0, do: Float.round(covered / total * 100, 1), else: 0.0

    %{
      total_events: total_events,
      covered: covered,
      percentage: percentage
    }
  end

  defp count_total_telemetry_events do
    try do
      length(:telemetry.list_handlers([]))
    rescue
      _ -> 0
    catch
      _, _ -> 0
    end
  end

  defp build_dependency_graph(subsystems) do
    nodes = Enum.map(subsystems, & &1.name)

    edges = Enum.flat_map(subsystems, fn s ->
      Enum.map(s.dependencies, fn dep -> {s.name, dep} end)
    end)

    roots = subsystems |> Enum.filter(&(&1.dependencies == [])) |> Enum.map(& &1.name)

    depended_on = Enum.flat_map(subsystems, & &1.dependencies) |> MapSet.new()
    leaves = nodes |> Enum.reject(&MapSet.member?(depended_on, &1))

    %{
      nodes: nodes,
      edges: edges,
      roots: roots,
      leaves: leaves
    }
  end

  defp compute_certification_status do
    checks = %{
      boot_certificate: check_boot(),
      health_certificate: check_health(),
      observability_certificate: check_observability(),
      replay_certificate: check_replay(),
      security_certificate: check_security(),
      performance_certificate: check_performance(),
      scientific_certificate: check_scientific(),
      integration_certificate: check_integration()
    }

    all_pass = Map.values(checks) |> Enum.all?(&(&1 == true))

    Map.put(checks, :overall_certificate, all_pass)
  end

  defp check_boot do
    Code.ensure_loaded?(Tiannara.Application) and
      (Process.whereis(Tiannara.Application) != nil or
         Process.whereis(TiannaraRuntime.StartupSupervisor) != nil)
  end

  defp check_health do
    try do
      if Code.ensure_loaded?(Tiannara.CRAV.RuntimeCensus) do
        case Tiannara.CRAV.RuntimeCensus.census() do
          {:ok, entries} ->
            total = length(entries)
            alive = Enum.count(entries, &(&1.status == :alive))
            total > 0 and alive / total >= 0.5

          _ ->
            false
        end
      else
        false
      end
    rescue
      _ -> false
    end
  end

  defp check_observability do
    try do
      if Code.ensure_loaded?(Tiannara.CRAV.ObservatoryCoverage) do
        case Tiannara.CRAV.ObservatoryCoverage.overall_coverage() do
          {:ok, coverage} -> coverage >= 0.5
          _ -> false
        end
      else
        false
      end
    rescue
      _ -> false
    end
  end

  defp check_replay do
    Code.ensure_loaded?(Tiannara.Observatory.Replay) or
      Code.ensure_loaded?(Tiannara.Observatory)
  end

  defp check_security do
    Code.ensure_loaded?(Tiannara.CIS) or Code.ensure_loaded?(Tiannara.CIS.Constraint)
  end

  defp check_performance do
    Code.ensure_loaded?(Tiannara.Profiling) or Code.ensure_loaded?(Tiannara.CRAV.RuntimeHeatmap)
  end

  defp check_scientific do
    try do
      if Code.ensure_loaded?(Tiannara.CRAV.DiscoveryChain) do
        case Tiannara.CRAV.DiscoveryChain.verify() do
          {:ok, results} ->
            reachable = Enum.count(results, & &1.reachable)
            reachable >= 6

          _ ->
            false
        end
      else
        false
      end
    rescue
      _ -> false
    end
  end

  defp check_integration do
    Code.ensure_loaded?(Tiannara.CRAV) and Code.ensure_loaded?(Tiannara.CRAV.LaunchReadiness)
  end

  defp compute_alpha_readiness(subsystems) do
    running = Enum.count(subsystems, &(&1.state == :running))
    total = length(subsystems)

    runtime_readiness = if total > 0, do: Float.round(running / total * 100, 1), else: 0.0

    scientific_readiness = compute_category_readiness(subsystems, [
      :rea, :discovery_pipeline, :knowledge_graph, :theory_ecology,
      :simulation_runtime, :nde, :twp, :ird, :opc, :dfg, :ros
    ])

    engineering_readiness = compute_category_readiness(subsystems, [
      :telemetry, :sentinel, :omce, :omcs, :oed, :asc, :ctl, :msg
    ])

    planetary_readiness = compute_category_readiness(subsystems, [
      :planetary_twin, :world_model, :theory_ecology, :knowledge_graph
    ])

    civilization_readiness = compute_category_readiness(subsystems, [
      :civilization_runtime, :simulation_runtime, :knowledge_graph
    ])

    overall = Float.round(
      runtime_readiness * 0.30 +
        scientific_readiness * 0.20 +
        engineering_readiness * 0.20 +
        planetary_readiness * 0.15 +
        civilization_readiness * 0.15,
      1
    )

    recommendation = cond do
      overall >= 80.0 -> :ready
      overall < 40.0 -> :blocked
      true -> :conditional
    end

    %{
      runtime_readiness: runtime_readiness,
      scientific_readiness: scientific_readiness,
      engineering_readiness: engineering_readiness,
      planetary_readiness: planetary_readiness,
      civilization_readiness: civilization_readiness,
      overall: overall,
      recommendation: recommendation
    }
  end

  defp compute_category_readiness(subsystems, category) do
    category_set = MapSet.new(category)
    total = MapSet.size(category_set)

    if total == 0 do
      0.0
    else
      running_names = subsystems
      |> Enum.filter(&(&1.state == :running))
      |> Enum.map(& &1.name)
      |> MapSet.new()

      alive_in_category = category_set |> MapSet.intersection(running_names) |> MapSet.size()
      Float.round(alive_in_category / total * 100, 1)
    end
  end

  defp verify_subsystem(subsystem) do
    case subsystem.state do
      :planned -> true
      :running -> has_live_process_for_subsystem?(subsystem)
      :dormant -> true
      _ -> false
    end
  end

  defp has_live_process_for_subsystem?(subsystem) do
    case subsystem.module do
      nil -> false
      mod -> Code.ensure_loaded?(mod) and has_live_process?(mod)
    end
  end

  defp identify_issues(subsystem) do
    issues = []

    issues =
      if subsystem.state == :planned and subsystem.module != nil and Code.ensure_loaded?(subsystem.module) do
        issues ++ ["Module loaded but subsystem not registered"]
      else
        issues
      end

    issues =
      if subsystem.module != nil and not Code.ensure_loaded?(subsystem.module) do
        issues ++ ["Module not loaded"]
      else
        issues
      end

    issues =
      if subsystem.telemetry_events == [] and subsystem.state == :running do
        issues ++ ["No telemetry events detected"]
      else
        issues
      end

    issues
  end

  defp format_cert_line(label, true), do: "    #{String.pad_trailing(label, 20)} PASS"
  defp format_cert_line(label, false), do: "    #{String.pad_trailing(label, 20)} FAIL"
  defp format_cert_line(label, _), do: "    #{String.pad_trailing(label, 20)} N/A"

  defp module_to_string(nil), do: "nil"
  defp module_to_string(mod) when is_atom(mod), do: Atom.to_string(mod)
  defp module_to_string(mod), do: to_string(mod)

  defp module_to_short_string(nil), do: "N/A"
  defp module_to_short_string(mod) when is_atom(mod) do
    mod
    |> Atom.to_string()
    |> String.replace("Elixir.", "")
    |> String.split(".")
    |> Enum.take(2)
    |> Enum.join(".")
  end
  defp module_to_short_string(mod), do: to_string(mod)

  defp serialize_certification(cert) do
    cert
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end

  defp serialize_readiness(readiness) do
    readiness
    |> Map.update!(:recommendation, &Atom.to_string/1)
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end
end
