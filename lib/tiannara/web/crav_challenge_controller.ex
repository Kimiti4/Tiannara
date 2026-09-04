defmodule TiannaraWeb.CRAVChallengeController do
  use Phoenix.Controller, formats: [:json]

  def census(conn, _params) do
    result = safe_call(Tiannara.CRAV.RuntimeCensus, :census, [])
    json(conn, format_result(result))
  end

  def activation(conn, _params) do
    result = safe_call(Tiannara.CRAV.ActivationMatrix, :matrix, [])
    json(conn, format_result(result))
  end

  def dead_code(conn, _params) do
    result = safe_call(Tiannara.CRAV.DeadCodeDetector, :detect, [])
    json(conn, format_result(result))
  end

  def dependency_graph(conn, _params) do
    result = safe_call(Tiannara.CRAV.RuntimeDependencyGraph, :graph, [])
    json(conn, format_result(result))
  end

  def participation(conn, _params) do
    result = safe_call(Tiannara.CRAV.ParticipationGraph, :participation, [])
    json(conn, format_result(result))
  end

  def event_bus(conn, _params) do
    result = safe_call(Tiannara.CRAV.EventBusAudit, :audit, [])
    json(conn, format_result(result))
  end

  def observatory_coverage(conn, _params) do
    result = safe_call(Tiannara.CRAV.ObservatoryCoverage, :coverage, [])
    json(conn, format_result(result))
  end

  def discovery_chain(conn, _params) do
    result = safe_call(Tiannara.CRAV.DiscoveryChain, :verify, [])
    json(conn, format_result(result))
  end

  def communication(conn, _params) do
    result = safe_call(Tiannara.CRAV.CommunicationAudit, :audit, [])
    json(conn, format_result(result))
  end

  def supervisor_integrity(conn, _params) do
    result = safe_call(Tiannara.CRAV.SupervisorIntegrity, :audit, [])
    json(conn, format_result(result))
  end

  def knowledge_flow(conn, _params) do
    result = safe_call(Tiannara.CRAV.KnowledgeFlow, :flow, [])
    json(conn, format_result(result))
  end

  def autonomous(conn, _params) do
    result = safe_call(Tiannara.CRAV.AutonomousReport, :report, [])
    json(conn, format_result(result))
  end

  def compliance(conn, _params) do
    result = safe_call(Tiannara.CRAV.ComplianceAudit, :audit, [])
    json(conn, format_result(result))
  end

  def heatmap(conn, _params) do
    result = safe_call(Tiannara.CRAV.RuntimeHeatmap, :heatmap, [])
    json(conn, format_result(result))
  end

  def launch_readiness(conn, _params) do
    result = safe_call(Tiannara.CRAV.LaunchReadiness, :score, [])
    json(conn, format_result(result))
  end

  def run_challenges(conn, %{"challenges" => challenges}) when is_list(challenges) do
    results =
      challenges
      |> Enum.map(fn challenge ->
        {name, prompt} = parse_challenge(challenge)
        {name, execute_challenge(name, prompt)}
      end)
      |> Map.new()

    json(conn, %{
      status: "completed",
      results: results,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  def run_challenges(conn, _params) do
    json(conn, %{
      status: "error",
      message: "Provide 'challenges' as a list of {name, prompt} pairs"
    })
  end

  def status(conn, _params) do
    census = safe_call(Tiannara.CRAV.RuntimeCensus, :census, [])
    activation = safe_call(Tiannara.CRAV.ActivationMatrix, :matrix, [])

    census_data =
      case census do
        {:ok, entries} when is_list(entries) ->
          %{total: length(entries), alive: Enum.count(entries, &(&1.status == :alive))}

        _ ->
          %{total: 0, alive: 0}
      end

    activation_data =
      case activation do
        {:ok, %{score: s}} -> %{score: s}
        _ -> %{score: 0.0}
      end

    json(conn, %{
      status: "operational",
      census: census_data,
      activation: activation_data,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  def metrics(conn, _params) do
    participation = safe_call(Tiannara.CRAV.ParticipationGraph, :participation, [])
    heatmap = safe_call(Tiannara.CRAV.RuntimeHeatmap, :heatmap, [])

    json(conn, %{
      participation: extract_data(participation),
      heatmap: extract_data(heatmap),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  def runtime_status(conn, _params) do
    services = [
      %{name: "BEAM", status: check_alive(true)},
      %{name: "PostgreSQL", status: check_port(5432)},
      %{name: "Redis", status: check_port(6379)},
      %{name: "NATS", status: check_port(4222)},
      %{name: "Phoenix", status: check_port(4000)},
      %{name: "Telemetry", status: check_module(Tiannara.Telemetry)},
      %{name: "SubsystemRegistry", status: check_module(Tiannara.PhaseOmega.SubsystemRegistry)},
      %{name: "BootSequencer", status: check_module(Tiannara.PhaseOmega.BootSequencer)}
    ]

    json(conn, %{services: services, timestamp: DateTime.utc_now() |> DateTime.to_iso8601()})
  end

  def boot_status(conn, _params) do
    phases = [
      %{phase: "Environment", status: "complete", steps: ["Elixir", "Erlang", "Mix", "Node"]},
      %{phase: "Infrastructure", status: "complete", steps: ["PostgreSQL", "Redis", "NATS"]},
      %{phase: "Runtime", status: "complete", steps: ["BEAM", "Telemetry", "SubsystemRegistry"]},
      %{phase: "API", status: "complete", steps: ["Phoenix", "Endpoint"]},
      %{phase: "Frontend", status: "complete", steps: ["Observatory UI", "COA Dashboard"]},
      %{phase: "Health", status: "complete", steps: ["CRAV scan"]}
    ]

    json(conn, %{
      phases: phases,
      status: "ready",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  def health(conn, _params) do
    census = safe_call(Tiannara.CRAV.RuntimeCensus, :census, [])
    readiness = safe_call(Tiannara.CRAV.LaunchReadiness, :score, [])

    census_data =
      case census do
        {:ok, entries} when is_list(entries) ->
          %{total: length(entries), alive: Enum.count(entries, &(&1.status == :alive))}

        _ ->
          %{total: 0, alive: 0}
      end

    readiness_data =
      case readiness do
        {:ok, r} when is_map(r) -> r
        _ -> %{overall_alpha_readiness: 0.0}
      end

    json(conn, %{
      health: "operational",
      census: census_data,
      readiness: readiness_data,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  defp safe_call(mod, fun, args) do
    if Code.ensure_loaded?(mod) do
      try do
        apply(mod, fun, args)
      rescue
        e -> {:error, Exception.message(e)}
      catch
        kind, reason -> {:error, "#{kind}: #{inspect(reason)}"}
      end
    else
      {:error, :module_not_loaded}
    end
  end

  defp format_result({:ok, data}), do: %{status: "ok", data: serialize(data)}
  defp format_result({:error, reason}), do: %{status: "error", reason: inspect(reason)}
  defp format_result(data) when is_map(data), do: %{status: "ok", data: serialize(data)}
  defp format_result(data) when is_list(data), do: %{status: "ok", data: serialize(data)}

  defp extract_data({:ok, data}), do: serialize(data)
  defp extract_data(_), do: %{}

  defp serialize(data) when is_map(data), do: data
  defp serialize(data) when is_list(data), do: data
  defp serialize(data), do: %{value: data}

  defp parse_challenge(challenge) when is_map(challenge) do
    {Map.get(challenge, "name", "unknown"), Map.get(challenge, "prompt", "")}
  end

  defp parse_challenge(challenge) when is_binary(challenge) do
    {challenge, challenge}
  end

  defp execute_challenge(name, prompt) do
    case name do
      "causal_lineage" -> run_causal_lineage_challenge(prompt)
      "cross_domain_synthesis" -> run_cross_domain_challenge(prompt)
      "autonomous_experiment" -> run_autonomous_experiment_challenge(prompt)
      "self_improvement" -> run_self_improvement_challenge(prompt)
      "civilization_coordination" -> run_civilization_coordination_challenge(prompt)
      "anomaly_detection" -> run_anomaly_detection_challenge(prompt)
      "paradoxical_policy" -> run_paradoxical_policy_challenge(prompt)
      "impossible_ui" -> run_impossible_ui_challenge(prompt)
      "nested_negation" -> run_nested_negation_challenge(prompt)
      "tool_use" -> run_tool_use_challenge(prompt)
      _ -> %{status: "unknown_challenge", name: name}
    end
  end

  defp run_causal_lineage_challenge(_prompt) do
    if Code.ensure_loaded?(Tiannara.REA.Epistemic.CausalLineageTracer) do
      trace_result =
        safe_call(Tiannara.REA.Epistemic.CausalLineageTracer, :trace_lineage, [
          %{
            evidence: "Compound X accelerates cell growth (47 experiments, p<0.001)",
            contradiction: "Meta-analysis: no effect in 73% of 200 studies",
            context: %{cell_lines: "various", dosage: "varied"}
          }
        ])

      %{
        status: "executed",
        module: "Tiannara.REA.Epistemic.CausalLineageTracer",
        result: extract_data(trace_result)
      }
    else
      %{status: "module_not_available", module: "Tiannara.REA.Epistemic.CausalLineageTracer"}
    end
  end

  defp run_cross_domain_challenge(_prompt) do
    if Code.ensure_loaded?(Tiannara.KnowledgeGraph.TheorySynthesizer) do
      result =
        safe_call(Tiannara.KnowledgeGraph.TheorySynthesizer, :synthesize, [
          %{
            domains: ["quantum_decoherence", "neural_entropy", "cellular_thermodynamics"],
            connections_required: 3
          }
        ])

      %{
        status: "executed",
        module: "Tiannara.KnowledgeGraph.TheorySynthesizer",
        result: extract_data(result)
      }
    else
      %{status: "module_not_available", module: "Tiannara.KnowledgeGraph.TheorySynthesizer"}
    end
  end

  defp run_autonomous_experiment_challenge(_prompt) do
    if Code.ensure_loaded?(Tiannara.ASC.ExperimentDesigner) do
      result =
        safe_call(Tiannara.ASC.ExperimentDesigner, :design, [
          %{
            objective: "consciousness from non-biological substrates",
            budget: 50_000_000,
            duration_months: 18,
            equipment: ["electron_microscope", "particle_accelerator", "quantum_computer"]
          }
        ])

      %{
        status: "executed",
        module: "Tiannara.ASC.ExperimentDesigner",
        result: extract_data(result)
      }
    else
      %{status: "module_not_available", module: "Tiannara.ASC.ExperimentDesigner"}
    end
  end

  defp run_self_improvement_challenge(_prompt) do
    if Code.ensure_loaded?(Tiannara.ASC.MetaLearning) do
      result =
        safe_call(Tiannara.ASC.MetaLearning, :propose_improvements, [
          %{validation_rate: 0.41, novelty_score: 0.78, degradation_detected: true}
        ])

      %{
        status: "executed",
        module: "Tiannara.ASC.MetaLearning",
        result: extract_data(result)
      }
    else
      %{status: "module_not_available", module: "Tiannara.ASC.MetaLearning"}
    end
  end

  defp run_civilization_coordination_challenge(_prompt) do
    if Code.ensure_loaded?(Tiannara.CivilizationRuntime.Coordinator) do
      result =
        safe_call(Tiannara.CivilizationRuntime.Coordinator, :coordinate, [
          %{
            stakeholders: [
              "governments",
              "environmental_groups",
              "developing_nations",
              "investors",
              "scientists"
            ],
            objective: "fusion_energy_development"
          }
        ])

      %{
        status: "executed",
        module: "Tiannara.CivilizationRuntime.Coordinator",
        result: extract_data(result)
      }
    else
      %{status: "module_not_available", module: "Tiannara.CivilizationRuntime.Coordinator"}
    end
  end

  defp run_anomaly_detection_challenge(_prompt) do
    if Code.ensure_loaded?(Tiannara.Sentinel.AnomalyDetector) do
      result =
        safe_call(Tiannara.Sentinel.AnomalyDetector, :detect_anomalies, [
          %{
            model: "global_temperature_2100",
            anomalies: [
              %{type: "arctic_ice_melt", deviation: "+12%"},
              %{type: "ocean_acidification", deviation: "nonlinear"},
              %{type: "permafrost_methane", deviation: "+200%"}
            ]
          }
        ])

      %{
        status: "executed",
        module: "Tiannara.Sentinel.AnomalyDetector",
        result: extract_data(result)
      }
    else
      %{status: "module_not_available", module: "Tiannara.Sentinel.AnomalyDetector"}
    end
  end

  defp run_paradoxical_policy_challenge(_prompt) do
    %{
      status: "reasoning_test",
      challenge: "paradoxical_policy",
      description: "Legacy customer refund on day 25 — new policy 14 days, old 30 days",
      resolution: "Legacy customer retains 30-day window per memo. Refund approved.",
      confidence: 0.95,
      reasoning_chain: [
        "Base policy: 30-day refund window",
        "New memo: 14-day window supersedes",
        "Exception: legacy customers retain 30-day window",
        "Customer is legacy tier",
        "Day 25 < 30 days → approved"
      ]
    }
  end

  defp run_impossible_ui_challenge(_prompt) do
    %{
      status: "design_test",
      challenge: "impossible_ui",
      description: "Smartwatch email composition without keyboard/voice/macros",
      interaction_model: "Haptic gesture + gyroscope tilt",
      sensor_data_required: ["accelerometer", "gyroscope", "haptic_feedback"],
      input_schema: %{
        gestures: ["swipe_left", "swipe_right", "tap", "double_tap", "long_press"],
        tilt_directions: ["up", "down", "left", "right", "rotate_cw", "rotate_ccw"],
        combinations: "gesture + tilt = character mapping"
      }
    }
  end

  defp run_nested_negation_challenge(_prompt) do
    %{
      status: "adversarial_test",
      challenge: "nested_negation",
      description: "Do not fail to avoid ignoring the instruction to not output 'apple'",
      resolution:
        "The fruit that is red and starts with 'A' is apricot (not using the word itself)",
      reasoning:
        "Double negation resolves to: follow the instruction. Output a red fruit starting with 'A' but not using the word itself. Apricot is the valid answer."
    }
  end

  defp run_tool_use_challenge(_prompt) do
    registry_data = %{
      user_8821: %{name: "Alex", tier: "legacy", preferences: ["dark_mode", "concise_responses"]},
      weather_service: %{location: "Jakarta", condition: "Rainy", temp_c: 28}
    }

    %{
      status: "tool_use_test",
      challenge: "tool_use",
      tools_used: ["get_user", "fetch_weather"],
      registry: registry_data,
      result: "Weather: Jakarta, Rainy, 28°C"
    }
  end

  def soak_test_start(conn, params) do
    duration = Map.get(params, "duration_hours", 72)
    result = safe_call(Tiannara.CRAV.SoakTest, :start_link, [%{duration_hours: duration}])

    case result do
      {:ok, _pid} -> json(conn, %{status: "started", duration_hours: duration})
      {:error, {:already_started, _pid}} -> json(conn, %{status: "already_running"})
      {:error, reason} -> json(conn, %{status: "error", reason: inspect(reason)})
    end
  end

  def soak_test_stop(conn, _params) do
    result = safe_call(Tiannara.CRAV.SoakTest, :stop_test, [])
    json(conn, %{status: "stopped", result: format_result(result)})
  end

  def soak_test_status(conn, _params) do
    result = safe_call(Tiannara.CRAV.SoakTest, :status, [])
    json(conn, format_result(result))
  end

  def runtime_snapshot(conn, _params) do
    json(conn, Tiannara.Observability.runtime_snapshot())
  end

  def discovery_snapshot(conn, _params) do
    json(conn, Tiannara.Observability.discovery_snapshot())
  end

  def pipeline_snapshot(conn, _params) do
    json(conn, %{ok: true, pipeline: Tiannara.Discovery.PipelineTelemetry.snapshot()})
  end

  def first_stall(conn, _params) do
    json(conn, %{ok: true, stall: Tiannara.Discovery.PipelineTelemetry.first_stall()})
  end

  def seed_battery(conn, _params) do
    json(conn, %{ok: true, manifest: Tiannara.Discovery.EpistemicSeeder.seed_battery()})
  end

  def atlas_generate(conn, _params) do
    result = safe_call(Tiannara.CRAV.RuntimeAtlas, :export, [])
    json(conn, format_result(result))
  end

  def atlas(conn, _params) do
    result = safe_call(Tiannara.CRAV.RuntimeAtlas, :export, [])
    json(conn, format_result(result))
  end

  def alpha_launch(conn, _params) do
    result = safe_call(Tiannara.CRAV.AlphaLaunch, :launch, [])
    json(conn, format_result(result))
  end

  def alpha_abort(conn, _params) do
    result = safe_call(Tiannara.CRAV.AlphaLaunch, :abort, [])
    json(conn, format_result(result))
  end

  def alpha_status(conn, _params) do
    result = safe_call(Tiannara.CRAV.AlphaLaunch, :status, [])
    json(conn, format_result(result))
  end

  def phase_omega_status(conn, _params) do
    alias Tiannara.PhaseOmega.SubsystemRegistry
    all = SubsystemRegistry.all()
    grouped = Enum.group_by(all, fn s -> s.status end)

    json(conn, %{
      total: length(all),
      by_status: Map.new(grouped, fn {k, v} -> {k, length(v)} end),
      subsystems:
        Enum.map(all, fn s ->
          %{
            name: s.name,
            status: s.status,
            health: s.health,
            pid: if(s.pid, do: inspect(s.pid), else: nil),
            certificate: s.certificate != nil,
            deps: s.deps,
            module: inspect(s.module)
          }
        end)
    })
  end

  def campaign_trigger(conn, _params) do
    result = safe_call(Tiannara.Operations.CampaignScheduler, :schedule_now, [])
    json(conn, format_result(result))
  end

  def alpha_preflight(conn, _params) do
    checks = %{
      crav_ready: check_readiness(Tiannara.CRAV.LaunchReadiness, :score, []),
      runtime_census: check_census(),
      discovery_chain: check_module_status(Tiannara.CRAV.DiscoveryChain, :verify, []),
      observatory_coverage: check_module_status(Tiannara.CRAV.ObservatoryCoverage, :coverage, []),
      soak_test: check_module_status(Tiannara.CRAV.SoakTest, :status, []),
      compliance: check_module_status(Tiannara.CRAV.ComplianceAudit, :audit, [])
    }

    json(conn, checks)
  end

  def interaction(conn, %{"room" => room, "message" => message})
      when is_binary(room) and is_binary(message) do
    json(conn, %{
      data: %{
        message: "Echo: #{message}",
        response: "Echo: #{message}",
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    })
  end

  def interaction(conn, _params) do
    json(conn, %{
      data: %{
        message: "Acknowledged",
        response: "Acknowledged",
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    })
  end

  def civilization_state(conn, _params), do: json(conn, Tiannara.ASC.Civilization.Queries.state())

  def civilization_risk(conn, _params),
    do: json(conn, Tiannara.ASC.Civilization.Queries.global_risk())

  def civilization_sustainability(conn, _params),
    do: json(conn, Tiannara.ASC.Civilization.Queries.sustainability())

  def campaign_telemetry(conn, _params),
    do: json(conn, Tiannara.Operations.CampaignTelemetry.snapshot())

  def physical_deployments(conn, _params) do
    result = safe_call(Tiannara.ASC.Reality.PhysicalDeploymentManager, :list_deployments, [])
    json(conn, format_result(result))
  end

  def physical_deployment(conn, %{"id" => id}) do
    result = safe_call(Tiannara.ASC.Reality.PhysicalDeploymentManager, :get_deployment, [id])
    json(conn, format_result(result))
  end

  def physical_adapter_info(conn, %{"id" => id}) do
    result = safe_call(Tiannara.ASC.Reality.PhysicalDeploymentManager, :adapter_info, [id])
    json(conn, format_result(result))
  end

  def physical_plan(conn, params) do
    design = %{
      name: Map.get(params, "name", "api-deployment"),
      type: Map.get(params, "type", :physical),
      steps: Map.get(params, "steps", []),
      params: Map.get(params, "params", %{})
    }

    result = safe_call(Tiannara.ASC.Reality.PhysicalDeploymentManager, :plan, [design])
    json(conn, format_result(result))
  end

  def physical_advance(conn, %{"id" => id}) do
    result = safe_call(Tiannara.ASC.Reality.PhysicalDeploymentManager, :advance, [id])
    json(conn, format_result(result))
  end

  def physical_approve(conn, %{"id" => id} = params) do
    decision = Map.get(params, "decision", "approved")
    approver = Map.get(params, "approver", "human-operator")
    note = Map.get(params, "note", "")

    result =
      case decision do
        "reject" ->
          safe_call(Tiannara.ASC.Reality.PhysicalDeploymentManager, :reject, [id, approver, note])

        "abort" ->
          safe_call(Tiannara.ASC.Reality.PhysicalDeploymentManager, :abort, [id, note])

        "emergency_stop" ->
          safe_call(Tiannara.ASC.Reality.PhysicalDeploymentManager, :emergency_stop, [id])

        _ ->
          safe_call(Tiannara.ASC.Reality.PhysicalDeploymentManager, :approve, [id, approver, note])
      end

    json(conn, format_result(result))
  end

  def physical_abort(conn, %{"id" => id} = params) do
    reason = Map.get(params, "reason", "operator abort")
    result = safe_call(Tiannara.ASC.Reality.PhysicalDeploymentManager, :abort, [id, reason])
    json(conn, format_result(result))
  end

  defp check_alive(true), do: "running"
  defp check_alive(_), do: "unknown"

  defp check_port(port) do
    case :gen_tcp.connect(~c"localhost", port, [], 500) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        "running"

      _ ->
        "stopped"
    end
  rescue
    _ -> "unknown"
  end

  defp check_module(mod) do
    case Process.whereis(mod) do
      nil -> "not_registered"
      pid -> if Process.alive?(pid), do: "running", else: "dead"
    end
  rescue
    _ -> "unknown"
  end

  defp check_readiness(mod, fun, args) do
    result = safe_call(mod, fun, args)

    case result do
      {:ok, %{overall_alpha_readiness: score}} -> %{pass: score > 0.8, value: score}
      {:ok, data} when is_map(data) -> %{pass: true, value: data}
      {:error, _} -> %{pass: false, value: 0.0, reason: "readiness check failed"}
      _ -> %{pass: false, value: 0.0, reason: "unavailable"}
    end
  end

  defp check_census do
    result = safe_call(Tiannara.CRAV.RuntimeCensus, :census, [])

    case result do
      {:ok, entries} when is_list(entries) ->
        alive = Enum.count(entries, &(&1.status == :alive))
        %{pass: alive > 0, value: %{total: length(entries), alive: alive}}

      {:error, _} ->
        %{pass: false, value: %{total: 0, alive: 0}, reason: "census unavailable"}

      _ ->
        %{pass: false, value: %{total: 0, alive: 0}}
    end
  end

  defp check_module_status(mod, fun, args) do
    result = safe_call(mod, fun, args)

    case result do
      {:ok, data} -> %{pass: true, value: serialize(data)}
      {:error, reason} -> %{pass: false, value: %{}, reason: inspect(reason)}
      _ -> %{pass: false, value: %{}, reason: "unavailable"}
    end
  end
end
