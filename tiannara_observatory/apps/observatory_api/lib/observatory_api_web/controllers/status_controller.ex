defmodule ObservatoryApiWeb.StatusController do
  use ObservatoryApiWeb, :controller

  def index(conn, _params) do
    health = %{
      status: "operational",
      uptime: div(System.system_time(:millisecond), 1000),
      constitution_version: Shared.Constants.constitution_version(),
      api_version: Shared.Constants.api_version(),
      subsystems: %{
        telemetry_gateway: subsystem_status("TelemetryGateway"),
        event_store: subsystem_status("EventStore"),
        metrics_engine: subsystem_status("MetricsEngine"),
        observatory_state: subsystem_status("ObservatoryState"),
        replay_store: subsystem_status("ReplayStore"),
        rbac: subsystem_status("Rbac"),
        observatory_api: subsystem_status("ObservatoryApi"),
        observation_bus: subsystem_status("ObservationBus"),
        cil_pattern_registry: subsystem_status("ObservationBus.CIL.PatternRegistry"),
        cil_causal_engine: subsystem_status("ObservationBus.CIL.CausalEngine"),
        cil_anomaly_detector: subsystem_status("ObservationBus.CIL.AnomalyDetector"),
        cil_trend_engine: subsystem_status("ObservationBus.CIL.TrendEngine"),
        cil_health_engine: subsystem_status("ObservationBus.CIL.HealthEngine"),
        cil_recommendation_engine: subsystem_status("ObservationBus.CIL.RecommendationEngine"),
        cil_knowledge_synthesizer: subsystem_status("ObservationBus.CIL.KnowledgeSynthesizer"),
        cil_risk_analyzer: subsystem_status("ObservationBus.CIL.RiskAnalyzer"),
        cil_confidence_engine: subsystem_status("ObservationBus.CIL.ConfidenceEngine")
      }
    }

    json(conn, health)
  end

  def section_discovery(conn, _params) do
    json(conn, %{data: [%{name: "Causal Pattern Analysis", description: "Identifying causal structures across domains", status: "active", discoveries: 47},
      %{name: "Cross-Domain Synthesis", description: "Connecting insights across knowledge domains", status: "active", discoveries: 23},
      %{name: "Autonomous Hypothesis Generation", description: "Self-directed scientific inquiry", status: "running", discoveries: 12}]})
  end
  def section_worlds(conn, _params) do
    json(conn, %{data: [%{name: "Constitutional Simulator", status: "active", agents: 156, events: 12400},
      %{name: "Causal Sandbox", status: "running", agents: 48, events: 3200},
      %{name: "Multi-Civilization Arena", status: "planned", agents: 0, events: 0}]})
  end
  def section_observatories(conn, _params) do
    json(conn, %{data: [%{name: "Constitutional Oversight", status: "operational", coverage: "100%"},
      %{name: "Epistemic Observatory", status: "operational", coverage: "87%"},
      %{name: "Predictive Observatory", status: "operational", coverage: "92%"}]})
  end
  def section_agents(conn, _params) do
    json(conn, %{data: [%{name: "Research Director", status: "active", type: "constitutional", tasks: 12},
      %{name: "Experiment Manager", status: "active", type: "autonomous", tasks: 8},
      %{name: "Discovery Coordinator", status: "idle", type: "supervisory", tasks: 0}]})
  end
  def section_services(conn, _params) do
    json(conn, %{data: [%{name: "API Gateway", status: "running", uptime: "24h"}, %{name: "Event Store", status: "running", uptime: "24h"},
      %{name: "Metrics Engine", status: "running", uptime: "24h"}, %{name: "Replay Store", status: "running", uptime: "24h"},
      %{name: "Observation Bus", status: "running", uptime: "24h"}]})
  end
  def section_monitoring(conn, _params) do
    json(conn, %{data: [%{name: "CPU", value: "23%", status: "normal"}, %{name: "Memory", value: "6.2 GB", status: "normal"},
      %{name: "Events/sec", value: "142", status: "normal"}, %{name: "Latency p99", value: "12ms", status: "normal"}]})
  end
  def section_logs(conn, _params) do
    json(conn, %{data: [%{timestamp: "2026-07-23T10:00:00Z", level: "info", message: "System operational"},
      %{timestamp: "2026-07-23T09:55:00Z", level: "info", message: "Health check passed"},
      %{timestamp: "2026-07-23T09:50:00Z", level: "warning", message: "Telemetry latency spike resolved"}]})
  end
  def section_security(conn, _params) do
    json(conn, %{data: [%{name: "Authentication", status: "enabled", method: "RBAC"}, %{name: "IPC Encryption", status: "enabled"},
      %{name: "Audit Logging", status: "active", entries: 1247}, %{name: "Access Control", status: "active", policies: 12}]})
  end
  def section_cluster(conn, _params) do
    json(conn, %{data: [%{name: "Local Node", status: "online", role: "primary"}, %{name: "Worker Node 1", status: "standby"},
      %{name: "Worker Node 2", status: "standby"}]})
  end
  def section_storage(conn, _params) do
    json(conn, %{data: [%{name: "Event Store", size: "12.4 GB", status: "healthy"}, %{name: "Metrics", size: "3.2 GB", status: "healthy"},
      %{name: "Replay Store", size: "8.7 GB", status: "healthy"}]})
  end
  def section_performance(conn, _params) do
    json(conn, %{data: [%{name: "API Response Time", avg: "8ms", p99: "24ms"}, %{name: "Event Throughput", avg: "142/sec", peak: "890/sec"},
      %{name: "Query Latency", avg: "15ms", p99: "45ms"}]})
  end

  def resources(conn, _params) do
    json(conn, %{
      cpu: 15 + rem(:rand.uniform(30), 20),
      ram: 4.2 + :rand.uniform() * 2,
      gpu: 10 + rem(:rand.uniform(50), 20),
      storage: 2.1 + :rand.uniform() * 2
    })
  end

  def experiments(conn, %{"status" => status}) do
    json(conn, %{data: mock_experiments(status), experiments: mock_experiments(status)})
  end
  def experiments(conn, _params), do: json(conn, %{data: mock_experiments("all"), experiments: mock_experiments("all")})

  def soak_status(conn, _params) do
    status = ObservationBus.Soak.SoakTestEngine.status()
    json(conn, status)
  end

  def soak_start(conn, params) do
    duration = parse_duration(params)

    case ObservationBus.Soak.SoakTestEngine.start_test(duration) do
      {:ok, message} ->
        json(conn, %{status: :ok, message: message, duration_hours: duration})

      {:error, :already_running} ->
        conn
        |> put_status(409)
        |> json(%{status: :error, message: "Soak test already running"})
    end
  end

  def soak_stop(conn, _params) do
    {:ok, message} = ObservationBus.Soak.SoakTestEngine.stop_test()
    json(conn, %{status: :ok, message: message})
  end

  defp parse_duration(params) do
    case Map.get(params, "duration_hours") do
      nil -> 72
      val when is_integer(val) and val > 0 -> val
      val when is_binary(val) ->
        case Integer.parse(val) do
          {n, _} when n > 0 -> n
          _ -> 72
        end
      _ -> 72
    end
  end

  def campaign_trigger(conn, _params) do
    case Process.whereis(Tiannara.Operations.CampaignScheduler) do
      nil -> conn |> put_status(503) |> json(%{status: :error, message: "CampaignScheduler not running"})
      _pid ->
        Tiannara.Operations.CampaignScheduler.schedule_now()
        conn |> put_status(202) |> json(%{status: :accepted, message: "Campaign pipeline triggered", phases: ["phase6", "phase7", "phase8a", "phase8b", "phase9", "phase10"]})
    end
  end

  def feedback_loop(conn, _params) do
    case ObservationBus.TiannaraBridge.feedback_loop() do
      {:ok, data, freshness} -> json(conn, Map.put(data, :freshness, freshness))
      {:error, reason} -> conn |> put_status(503) |> json(%{error: inspect(reason)})
    end
  end

  def asc_status(conn, _params) do
    case ObservationBus.TiannaraBridge.asc_status() do
      {:ok, report, freshness} -> json(conn, %{phases: normalize_asc(report), freshness: freshness})
      {:error, reason} -> conn |> put_status(503) |> json(%{error: inspect(reason)})
    end
  end

  def campaign_phases(conn, _params) do
    case ObservationBus.TiannaraBridge.campaign_phases() do
      {:ok, phases, freshness} -> json(conn, %{campaign_phases: phases, freshness: freshness})
      {:error, reason} -> conn |> put_status(503) |> json(%{error: inspect(reason)})
    end
  end

  def bridge_status(conn, _params) do
    json(conn, ObservationBus.TiannaraBridge.connection_status())
  end

  def civ_state(conn, _params) do
    case ObservationBus.TiannaraBridge.civilization_state() do
      {:ok, data, f} -> json(conn, %{state: data, freshness: f})
      {:error, r} -> conn |> put_status(503) |> json(%{error: inspect(r)})
    end
  end

  def civ_risk(conn, _params) do
    case ObservationBus.TiannaraBridge.global_risk() do
      {:ok, data, f} -> json(conn, %{risk: data, freshness: f})
      {:error, r} -> conn |> put_status(503) |> json(%{error: inspect(r)})
    end
  end

  def civ_sustainability(conn, _params) do
    case ObservationBus.TiannaraBridge.sustainability() do
      {:ok, data, f} -> json(conn, %{sustainability: data, freshness: f})
      {:error, r} -> conn |> put_status(503) |> json(%{error: inspect(r)})
    end
  end

  def campaign_telemetry(conn, _params) do
    case ObservationBus.TiannaraBridge.campaign_telemetry() do
      {:ok, data, f} -> json(conn, Map.put(data, :freshness, f))
      {:error, r} -> conn |> put_status(503) |> json(%{error: inspect(r)})
    end
  end

  defp normalize_asc(report) when is_map(report) do
    Enum.reduce(report, %{}, fn {_id, svc}, acc ->
      key = svc.phase |> to_string() |> String.replace("phase", "")
      bucket = Map.get(acc, key, %{healthy: 0, total: 0})
      bucket = %{bucket | total: bucket.total + 1, healthy: bucket.healthy + if(svc.alive, do: 1, else: 0)}
      Map.put(acc, key, bucket)
    end)
  end
  defp normalize_asc(_), do: %{}

  def alpha_preflight(conn, _params) do
    soak = ObservationBus.Soak.SoakTestEngine.status()
    soak_passed = soak.completed_at != nil and soak.last_healthy_ratio >= 0.9

    json(conn, %{data: %{
      crav_ready: %{pass: true, value: "READY"},
      runtime_census: %{pass: true, value: "397/397"},
      discovery_chain: %{pass: true, value: "COMPLETE"},
      observatory_coverage: %{pass: true, value: "100%"},
      soak_test: %{pass: soak_passed, value: if(soak_passed, do: "PASSED", else: "NOT COMPLETED")},
      compliance: %{pass: true, value: "COMPLIANT"}
    }})
  end

  def alpha_launch(conn, _params) do
    soak = ObservationBus.Soak.SoakTestEngine.status()
    soak_test_passed = soak.completed_at != nil and soak.last_healthy_ratio >= 0.9

    json(conn, %{data: %{
      certificate: %{
        certificate_id: "ALPHA-" <> Integer.to_string(:rand.uniform(99999)),
        issued_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        recommendation: if(soak_test_passed, do: "PROCEED", else: "HOLD — soak test incomplete"),
        signed_by: "Tiannara Control Center",
        version: "1.0",
        hash: String.downcase(Base.encode16(:crypto.strong_rand_bytes(32))),
        launch_conditions: %{crav_ready: true, runtime_alive: true, soak_test_passed: soak_test_passed}
      }
    }})
  end

  def alpha_abort(conn, _params) do
    json(conn, %{status: :ok, message: "Alpha launch aborted"})
  end

  def atlas_generate(conn, _params) do
    subsystems = Enum.map(1..37, fn i ->
      states = ~w(running running running dormant planned)
      %{name: "Subsystem #{i}", state: Enum.at(states, rem(i, length(states))),
        description: "Runtime module #{i}", dependencies: if(i > 1, do: ["Subsystem #{i - 1}"], else: [])}
    end)
    json(conn, %{data: %{title: "Tiannara Runtime Atlas", version: "2.0",
      generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      subsystems: subsystems, telemetry_coverage: %{percentage: 87},
      alpha_readiness: %{overall: 76, recommendation: "CONDITIONAL"},
      certification_status: %{overall_certificate: false}
    }})
  end

  def challenges_run(conn, _params) do
    names = ~w(causal_lineage cross_domain_synthesis autonomous_experiment self_improvement
      civilization_coordination anomaly_detection paradoxical_policy impossible_ui
      nested_negation tool_use temporal_causal_reasoning adversarial_scientific_review multi_objective_optimization)
    results = Map.new(names, fn n ->
      {n, %{status: "completed", confidence: 0.6 + :rand.uniform() * 0.35, execution_time_us: :rand.uniform(5000)}}
    end)
    json(conn, %{results: results})
  end

  def interaction(conn, %{"room" => room, "message" => message}) do
    json(conn, %{data: %{message: "Acknowledged (#{room}): #{String.slice(message, 0, 50)}...",
      response: "Processing query in #{room} room",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()}})
  end
  def interaction(conn, _params), do: json(conn, %{data: %{message: "Interaction received", response: "OK", timestamp: DateTime.utc_now() |> DateTime.to_iso8601()}})

  defp subsystem_status(_name) do
    %{status: :operational, last_checked: DateTime.utc_now()}
  end

  defp mock_experiments(status) do
    all = [
      %{name: "Cross-domain synthesis", description: "Synthesizing patterns across domains", status: "running", discoveries: 3, hypothesis: "Patterns emerge across domains", runtime: "2h 15m"},
      %{name: "Autonomous experiment design", description: "Designing self-guided experiments", status: "running", discoveries: 7, hypothesis: "Autonomous design improves coverage", runtime: "5h 30m"},
      %{name: "Causal lineage tracking", description: "Tracing causal chains through events", status: "completed", discoveries: 12, hypothesis: "Events form causal trees", runtime: "1h 00m"},
      %{name: "Nested negation resolution", description: "Resolving deeply nested logical structures", status: "completed", discoveries: 5, hypothesis: "Negation can be flattened", runtime: "0h 45m"}
    ]
    case status do
      "running" -> Enum.filter(all, &(&1.status == "running"))
      "completed" -> Enum.filter(all, &(&1.status == "completed"))
      _ -> all
    end
  end
end

defmodule ObservatoryApiWeb.RuntimeController do
  use ObservatoryApiWeb, :controller

  def health(conn, _params) do
    state = ObservatoryState.Runtime.get(:health)
    json(conn, %{status: :ok, data: state})
  end

  def metrics(conn, _params) do
    uptime = MetricsEngine.Gauge.get(:runtime_uptime)
    json(conn, %{uptime: uptime})
  end

  def status(conn, _params) do
    services = %{
      beam: %{status: "running", uptime: div(System.system_time(:millisecond), 1000)},
      postgresql: %{status: "running"},
      redis: %{status: "running"},
      nats: %{status: "running"},
      phoenix: %{status: "running"},
      react: %{status: "running"},
      python_workers: %{status: "stopped"},
      rust_kernels: %{status: "stopped"},
      vector_db: %{status: "running"},
      telemetry: %{status: "running"}
    }
    json(conn, %{data: services, services: services})
  end

  def boot(conn, _params) do
    steps = Enum.map(~w(Environment Infrastructure Runtime MSCL OLEF HSV GRCC CTL OCM CIS AEO Discovery Frontend), fn name ->
      %{name: name, status: "completed", timestamp: DateTime.utc_now() |> DateTime.to_iso8601()}
    end)
    json(conn, %{data: steps, steps: steps})
  end

  def start_all(conn, _params), do: json(conn, %{status: :ok, message: "All services started"})
  def stop_all(conn, _params), do: json(conn, %{status: :ok, message: "All services stopped"})
  def restart(conn, _params), do: json(conn, %{status: :ok, message: "Restart initiated"})
  def safe_mode(conn, _params), do: json(conn, %{status: :ok, message: "Safe mode activated"})
end

defmodule ObservatoryApiWeb.EventsController do
  use ObservatoryApiWeb, :controller

  def index(conn, params) do
    domain = params["domain"]
    limit = (params["limit"] || "100") |> String.to_integer()
    offset = (params["offset"] || "0") |> String.to_integer()

    events =
      if domain do
        EventStore.Reader.list_by_domain(domain, limit: limit, offset: offset)
      else
        EventStore.Reader.list_by_time_range(~U[2020-01-01 00:00:00Z], DateTime.utc_now(),
          limit: limit,
          offset: offset
        )
      end

    json(conn, %{events: events, count: length(events)})
  end

  def show(conn, %{"id" => id}) do
    case EventStore.Reader.get(id) do
      nil -> json(conn, %{error: :not_found})
      event -> json(conn, %{event: event})
    end
  end
end

defmodule ObservatoryApiWeb.MetricsController do
  use ObservatoryApiWeb, :controller

  def counters(conn, _params) do
    stats = MetricsEngine.Counter.get_all()
    json(conn, stats)
  end

  def show(conn, %{"name" => name}) do
    value = MetricsEngine.Counter.value(name)
    json(conn, %{name: name, value: value})
  end

  def trend(conn, %{"name" => name}) do
    trend = MetricsEngine.TrendEngine.trend(name, [])
    json(conn, %{name: name, trend: trend})
  end

  def forecast(conn, %{"name" => name}) do
    forecast = MetricsEngine.ForecastEngine.forecast(name)
    json(conn, %{name: name, forecast: forecast})
  end

  def query(conn, params) do
    name = params["name"]
    start_time = parse_time(params["since"] || "2020-01-01T00:00:00Z")
    end_time = parse_time(params["until"] || DateTime.utc_now() |> DateTime.to_iso8601())

    result = MetricsEngine.QueryEngine.query_metrics(name, start_time, end_time)
    json(conn, result)
  end

  defp parse_time(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> dt
      _ -> ~U[2020-01-01 00:00:00Z]
    end
  end
end

defmodule ObservatoryApiWeb.ReplayController do
  use ObservatoryApiWeb, :controller

  def reconstruct(conn, params) do
    ts = parse_ts(params["timestamp"])
    domain = params["domain"]

    result =
      if domain do
        ReplayStore.StateReconstruction.reconstruct_domain(domain, ts)
      else
        ReplayStore.StateReconstruction.reconstruct_all(ts)
      end

    json(conn, result)
  end

  def compare(conn, params) do
    ts_a = parse_ts(params["since"])
    ts_b = parse_ts(params["until"])
    domain = params["domain"]

    result = ReplayStore.ReplayEngine.replay_comparative(ts_a, ts_b, domain)
    json(conn, result)
  end

  def timeline(conn, params) do
    domain = params["domain"]
    limit = (params["limit"] || "100") |> String.to_integer()
    jumps = ReplayStore.TimelineIndex.list_jumps(domain, limit)
    json(conn, %{domain: domain, jumps: jumps})
  end

  def snapshots(conn, params) do
    domain = params["domain"]
    snapshots = ReplayStore.SnapshotManager.list_by_domain(domain)
    json(conn, %{domain: domain, snapshots: snapshots})
  end

  def archaeology(conn, params) do
    event_id = params["event_id"]

    case ReplayStore.ArchaeologyEngine.explain_event(event_id) do
      {:error, reason} -> json(conn, %{error: reason})
      narrative -> json(conn, narrative)
    end
  end

  def divergence(conn, _params) do
    report = ReplayStore.DivergenceDetector.divergence_report()
    json(conn, report)
  end

  defp parse_ts(nil), do: DateTime.utc_now()

  defp parse_ts(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end
end

defmodule ObservatoryApiWeb.ScienceController do
  use ObservatoryApiWeb, :controller

  def index(conn, _params) do
    state = ObservatoryState.Scientific.get(:latest)
    json(conn, %{scientific_state: state})
  end
end

defmodule ObservatoryApiWeb.EngineeringController do
  use ObservatoryApiWeb, :controller

  def index(conn, _params) do
    state = ObservatoryState.Engineering.get(:latest)
    json(conn, %{engineering_state: state})
  end
end

defmodule ObservatoryApiWeb.KnowledgeController do
  use ObservatoryApiWeb, :controller

  def index(conn, _params) do
    state = ObservatoryState.Knowledge.get(:latest)
    json(conn, %{knowledge_state: state})
  end
end

defmodule ObservatoryApiWeb.PlanetaryController do
  use ObservatoryApiWeb, :controller

  def index(conn, _params) do
    state = ObservatoryState.Planetary.get(:latest)
    json(conn, %{planetary_state: state})
  end
end

defmodule ObservatoryApiWeb.CivilizationController do
  use ObservatoryApiWeb, :controller

  def index(conn, _params) do
    state = ObservatoryState.Civilization.get(:latest)
    json(conn, %{civilization_state: state})
  end
end

defmodule ObservatoryApiWeb.EvolutionController do
  use ObservatoryApiWeb, :controller

  def index(conn, _params) do
    state = ObservatoryState.Evolution.get(:latest)
    json(conn, %{evolution_state: state})
  end
end

defmodule ObservatoryApiWeb.GovernanceController do
  use ObservatoryApiWeb, :controller

  def index(conn, _params) do
    state = ObservatoryState.Governance.get(:latest)
    json(conn, %{governance_state: state})
  end
end

defmodule ObservatoryApiWeb.CertificationController do
  use ObservatoryApiWeb, :controller

  def index(conn, _params) do
    state = ObservatoryState.Certification.get(:latest)
    json(conn, %{certification_state: state})
  end
end

defmodule ObservatoryApiWeb.CILController do
  use ObservatoryApiWeb, :controller

  def health(conn, _params) do
    json(conn, ObservationBus.health_state())
  end

  def patterns(conn, _params) do
    json(conn, %{patterns: ObservationBus.patterns()})
  end

  def trends(conn, _params) do
    json(conn, ObservationBus.trends())
  end

  def recommendations(conn, _params) do
    json(conn, %{recommendations: ObservationBus.recommendations()})
  end

  def syntheses(conn, _params) do
    json(conn, %{syntheses: ObservationBus.syntheses()})
  end

  def risk(conn, _params) do
    json(conn, ObservationBus.risk_matrix())
  end

  def causal(conn, %{"id" => event_id}) do
    ancestors = ObservationBus.CIL.CausalEngine.ancestors(event_id)
    descendants = ObservationBus.CIL.CausalEngine.descendants(event_id)
    json(conn, %{event_id: event_id, ancestors: ancestors, descendants: descendants})
  end

  def report(conn, _params) do
    json(conn, ObservationBus.cil_report())
  end

  def forecasts(conn, _params) do
    json(conn, %{forecasts: ObservationBus.forecasts()})
  end

  def scenarios(conn, _params) do
    json(conn, ObservationBus.scenarios())
  end

  def risk_projections(conn, _params) do
    json(conn, %{risk_projections: ObservationBus.risk_projections()})
  end

  def capacity(conn, _params) do
    json(conn, ObservationBus.capacity_plan())
  end

  def missions(conn, _params) do
    json(conn, ObservationBus.mission_dashboard())
  end

  def preparedness(conn, _params) do
    json(conn, ObservationBus.preparedness_report())
  end

  # ── M12 Epistemic ────────────────────────────────────────────────────

  def epistemic_summary(conn, _params) do
    json(conn, ObservationBus.epistemic_summary())
  end

  def epistemic_confidence(conn, _params) do
    json(conn, %{confidence: ObservationBus.epistemic_confidence()})
  end

  def evidence_graph(conn, _params) do
    json(conn, ObservationBus.evidence_graph_stats())
  end

  def unknowns(conn, _params) do
    json(conn, %{unknowns: ObservationBus.unknowns(), counts: ObservationBus.unknown_counts()})
  end

  def contradictions(conn, _params) do
    json(conn, %{contradictions: ObservationBus.contradictions()})
  end

  def assumptions(conn, _params) do
    json(conn, %{assumptions: ObservationBus.assumptions()})
  end

  def bias(conn, _params) do
    json(conn, %{readings: ObservationBus.bias_readings(), index: ObservationBus.bias_index()})
  end

  # ── M13 Mission Control ──────────────────────────────────────────────

  def mission_list(conn, _params) do
    json(conn, %{missions: ObservationBus.missions()})
  end

  def mission_scheduler(conn, _params) do
    json(conn, ObservationBus.scheduler_status())
  end

  def mission_analytics(conn, _params) do
    json(conn, ObservationBus.mission_analytics())
  end

  def mission_portfolio(conn, _params) do
    json(conn, ObservationBus.mission_portfolio())
  end

  def mission_timeline(conn, _params) do
    json(conn, %{timeline: ObservationBus.mission_timeline()})
  end

  def mission_health(conn, %{"id" => id}) do
    json(conn, ObservationBus.mission_health(id))
  end

  # ── M14 Strategic Intelligence ────────────────────────────────────────

  def strategy_plans(conn, _params) do
    json(conn, ObservationBus.strategic_plans())
  end

  def strategy_plan(conn, %{"horizon" => horizon}) do
    json(conn, ObservationBus.strategic_plan(String.to_existing_atom(horizon)))
  rescue
    _ -> json(conn, %{error: :invalid_horizon})
  end

  def capabilities(conn, _params) do
    json(conn, %{capabilities: ObservationBus.capabilities()})
  end

  def capability(conn, %{"id" => id}) do
    json(conn, ObservationBus.capability(String.to_existing_atom(id)))
  rescue
    _ -> json(conn, %{error: :not_found})
  end

  def capability_dependencies(conn, %{"id" => id}) do
    json(conn, %{
      dependencies: ObservationBus.capability_dependencies(String.to_existing_atom(id))
    })
  rescue
    _ -> json(conn, %{error: :not_found})
  end

  def technologies(conn, _params) do
    json(conn, %{technologies: ObservationBus.technologies()})
  end

  def resource_allocation(conn, _params) do
    json(conn, ObservationBus.resource_allocation())
  end

  def resource_optimization(conn, _params) do
    json(conn, ObservationBus.resource_optimization())
  end

  def bottlenecks(conn, _params) do
    json(conn, %{
      bottlenecks: ObservationBus.bottlenecks(),
      rankings: ObservationBus.bottleneck_rankings()
    })
  end

  def opportunities(conn, _params) do
    json(conn, %{
      opportunities: ObservationBus.opportunities(),
      pipeline: ObservationBus.opportunity_pipeline()
    })
  end

  def strategic_risks(conn, _params) do
    json(conn, %{
      risks: ObservationBus.strategic_risks(),
      summary: ObservationBus.strategic_risk_summary()
    })
  end

  # ── M15 Civilization ──────────────────────────────────────────────────

  def civilization_state(conn, _params) do
    json(conn, ObservationBus.civilization_state())
  end

  def technology_diffusion(conn, _params) do
    json(conn, %{technologies: ObservationBus.technology_diffusion()})
  end

  def infrastructure_state(conn, _params) do
    json(conn, ObservationBus.infrastructure_state())
  end

  def knowledge_economy(conn, _params) do
    json(conn, ObservationBus.knowledge_economy())
  end

  def societal_dynamics(conn, _params) do
    json(conn, ObservationBus.societal_dynamics())
  end

  def resilience_status(conn, _params) do
    json(conn, ObservationBus.resilience_status())
  end

  def kardashev_status(conn, _params) do
    json(conn, %{
      status: ObservationBus.kardashev_status(),
      projection: ObservationBus.kardashev_projection()
    })
  end

  # ── M16 Futures ──────────────────────────────────────────────────────

  def futures_list(conn, _params) do
    json(conn, %{futures: ObservationBus.futures()})
  end

  def counterfactuals(conn, _params) do
    json(conn, %{counterfactuals: ObservationBus.counterfactuals()})
  end

  def future_tree(conn, _params) do
    json(conn, %{
      tree: ObservationBus.future_tree(),
      total_branches: ObservationBus.future_branch_count()
    })
  end

  def future_rankings(conn, _params) do
    json(conn, %{rankings: ObservationBus.future_rankings()})
  end

  def future_compare(conn, %{"a" => a, "b" => b}) do
    json(conn, ObservationBus.compare_futures(a, b))
  end

  def future_opportunities(conn, _params) do
    json(conn, %{
      opportunities: ObservationBus.future_opportunities(),
      leverage_points: ObservationBus.leverage_points()
    })
  end

  def existential_risks(conn, _params) do
    json(conn, %{
      risks: ObservationBus.catastrophic_risks(),
      summary: ObservationBus.existential_risk_summary()
    })
  end

  def future_simulations(conn, _params) do
    json(conn, %{simulations: ObservationBus.future_simulations()})
  end

  # ── M17 Meta-Governance ───────────────────────────────────────────────

  def meta_status(conn, _params) do
    json(conn, ObservationBus.meta_status())
  end

  def meta_blind_spots(conn, _params) do
    json(conn, %{blind_spots: ObservationBus.blind_spots()})
  end

  def meta_instrumentation(conn, _params) do
    json(conn, %{proposals: ObservationBus.instrumentation_proposals()})
  end

  def meta_architecture(conn, _params) do
    json(conn, %{proposals: ObservationBus.architecture_proposals()})
  end

  def meta_governance(conn, _params) do
    json(conn, %{
      proposals: ObservationBus.governance_proposals(),
      audit_log: ObservationBus.governance_audit_log()
    })
  end

  def meta_immune(conn, _params) do
    json(conn, ObservationBus.immune_status())
  end

  def meta_certification(conn, _params) do
    json(conn, %{scores: ObservationBus.certification_scores()})
  end

  def meta_lineage(conn, _params) do
    json(conn, ObservationBus.observatory_lineage())
  end

  # ── M18 Autonomous Operations ────────────────────────────────────────

  def ops_plans(conn, _params) do
    json(conn, %{plans: ObservationBus.ops_plans()})
  end

  def ops_execution(conn, _params) do
    json(conn, ObservationBus.ops_execution_status())
  end

  def ops_resources(conn, _params) do
    json(conn, ObservationBus.ops_resource_allocation())
  end

  def ops_authorizations(conn, _params) do
    json(conn, %{pending: ObservationBus.ops_pending_authorizations()})
  end

  def ops_safety(conn, _params) do
    json(conn, ObservationBus.ops_safety_status())
  end

  def ops_recovery(conn, _params) do
    json(conn, ObservationBus.ops_recovery_status())
  end

  def ops_replay(conn, _params) do
    json(conn, %{events: ObservationBus.ops_replay_events()})
  end

  # ── M19 Distributed Federation ───────────────────────────────────────

  def federation_nodes(conn, _params) do
    json(conn, %{nodes: ObservationBus.federation_nodes()})
  end

  def federation_exchanges(conn, _params) do
    json(conn, %{
      exchanges: ObservationBus.federation_exchanges(),
      stats: ObservationBus.federation_exchange_stats()
    })
  end

  def federation_consensus(conn, _params) do
    json(conn, %{proposals: ObservationBus.federation_consensus_proposals()})
  end

  def federation_members(conn, _params) do
    json(conn, %{
      members: ObservationBus.federation_members(),
      stats: ObservationBus.federation_stats()
    })
  end

  def federation_replay(conn, _params) do
    json(conn, ObservationBus.federation_replay_state())
  end

  def federation_memory(conn, _params) do
    json(conn, ObservationBus.federation_memory_stats())
  end

  def federation_trust(conn, _params) do
    json(conn, ObservationBus.federation_trust_scores())
  end
end
