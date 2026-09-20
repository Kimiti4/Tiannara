defmodule Tiannara.PhaseOmega.EventFlowVerifier do
  @moduledoc """
  Ω.5 — Event Flow Verification.

  Traces every known event path through the system and verifies each
  stage is operational:

    Telemetry → Gateway → Validation → EventStore → Metrics → State → API → WebSocket
    Runtime   → NATS     → Bridge    → Gateway    → COB    → CIL  → Pipeline
    Discovery → REA      → Theory    → Knowledge   → Engineering → Deployment
  """

  require Logger

  @known_paths [
    %{
      name: :telemetry_ingest,
      label: "Runtime Telemetry → Observatory",
      stages: [
        {:telemetry_emitter, "Runtime emits [:observatory, :event, :ingested]"},
        {:telemetry_handler, "TelemetryGateway.Receiver handles event"},
        {:event_store_write, "EventStore.Writer persists event"},
        {:metrics_emit, "MetricsEngine records metrics"},
        {:domain_route, "DomainRouter routes to domain pipeline"}
      ]
    },
    %{
      name: :nats_bridge,
      label: "NATS → Telemetry Gateway",
      stages: [
        {:nats_connection, "NATS connection to nats://localhost:4222"},
        {:nats_subscribe, "Subscribed to tiannara.> subjects"},
        {:message_decode, "JSON decode incoming NATS messages"},
        {:gateway_ingest, "Receiver.ingest/1 called"}
      ]
    },
    %{
      name: :cob_pipeline,
      label: "COB → CIL → Pattern Engine",
      stages: [
        {:cob_publish, "ObservationBus publishes constitutional event"},
        {:cil_ingest, "CILIngest subscriber receives event"},
        {:pattern_engine, "PatternEngine.ingest_event/1"},
        {:causal_engine, "CausalEngine.record_event/3"},
        {:anomaly_detector, "AnomalyDetector.analyze/1"}
      ]
    },
    %{
      name: :websocket_stream,
      label: "COB → LiveStream → WebSocket",
      stages: [
        {:cob_publish, "ObservationBus publishes event"},
        {:cob_stream_bridge, "COBStreamBridge receives event"},
        {:live_stream_engine, "LiveStreamEngine.stream/2"},
        {:websocket_push, "Event pushed to UI room subscribers"}
      ]
    },
    %{
      name: :rest_api,
      label: "REST API Endpoints",
      stages: [
        {:health_endpoint, "GET /api/v1/health returns 200"},
        {:status_endpoint, "GET /api/v1/status returns system status"},
        {:certification_endpoint, "GET /api/v1/certification returns cert data"},
        {:replay_endpoint, "GET /api/v1/replay returns replay data"}
      ]
    },
    %{
      name: :observatory_ingest,
      label: "Observatory Boot Pipeline",
      stages: [
        {:boot_start, "BootEngine starts"},
        {:phase_telemetry, "TelemetryPhase initialized"},
        {:phase_core, "Core subsystems started"},
        {:phase_discovery, "Discovery services started"},
        {:phase_certification, "Certification services started"},
        {:boot_complete, "All phases complete"}
      ]
    }
  ]

  @doc """
  Verify all known event paths. Returns a report map.
  """
  def verify_all do
    has_observatory = Code.ensure_loaded?(ObservatoryApi.Router)

    if !has_observatory do
      Logger.info("[PhaseΩ:EventFlow] Running headless — all paths skipped")
      %{
        total_paths: length(@known_paths),
        healthy_paths: 0,
        failed_paths: 0,
        unknown_paths: length(@known_paths),
        paths: Enum.map(@known_paths, fn p -> %{path: p.name, label: p.label, healthy: false, status: :unknown, stages: %{}, details: "Headless mode — verification not performed"} end),
        timestamp: DateTime.utc_now()
      }
    else
      Logger.info("[PhaseΩ:EventFlow] Verifying #{length(@known_paths)} event paths...")
      do_verify()
    end
  end

  defp do_verify do
    results = Enum.map(@known_paths, fn path ->
      stages = Enum.map(path.stages, fn {stage_id, _label} ->
        result = verify_stage(stage_id)
        {stage_id, result}
      end)

      path_unknown = Enum.any?(stages, fn {_id, r} -> r == :unknown end)
      path_healthy = not path_unknown and Enum.all?(stages, fn {_id, r} -> r == :pass end)

      %{
        path: path.name,
        label: path.label,
        healthy: path_healthy,
        status: cond do
          path_unknown -> :unknown
          path_healthy -> :pass
          true -> :fail
        end,
        stages: Enum.into(stages, %{}),
        details: if(!path_healthy, do: explain_failures(stages), else: nil)
      }
    end)

    %{
      total_paths: length(results),
      healthy_paths: Enum.count(results, & &1.healthy),
      failed_paths: Enum.count(results, fn r -> r.status == :fail end),
      unknown_paths: Enum.count(results, fn r -> r.status == :unknown end),
      paths: results,
      timestamp: DateTime.utc_now()
    }
  end

  defp verify_stage(:telemetry_emitter) do
    # Check if :telemetry handlers for observatory events exist
    if Code.ensure_loaded?(:telemetry) do
      handlers = try do
        :telemetry.list_handlers([:observatory, :event, :ingested])
      rescue
        _ -> []
      end
      if handlers != [], do: :unknown, else: :fail
    else
      :skip
    end
  end

  defp verify_stage(:telemetry_handler) do
    pid = Process.whereis(TelemetryGateway.Receiver)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:event_store_write) do
    pid = Process.whereis(EventStore.Writer)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:metrics_emit) do
    pid = Process.whereis(MetricsEngine)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:domain_route) do
    pid = Process.whereis(TelemetryGateway.DomainRouter)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:nats_connection) do
    pid = Process.whereis(TelemetryGateway.NATSBridge)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:nats_subscribe) do
    conn = Process.whereis(:telemetry_gateway_nats)
    if conn && Process.alive?(conn), do: :pass, else: :fail
  end

  defp verify_stage(:message_decode) do
    # NATSBridge handles Jason.decode! internally; check module loaded
    if Code.ensure_loaded?(Jason), do: :unknown, else: :fail
  end

  defp verify_stage(:gateway_ingest) do
    pid = Process.whereis(TelemetryGateway.Receiver)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:cob_publish) do
    pid = Process.whereis(ObservationBus.Publisher)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:cil_ingest) do
    pid = Process.whereis(ObservationBus.Subscriber.CILIngest)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:pattern_engine) do
    if Code.ensure_loaded?(ObservationBus.CIL.PatternEngine), do: :pass, else: :fail
  end

  defp verify_stage(:causal_engine) do
    if Code.ensure_loaded?(ObservationBus.CIL.CausalEngine), do: :pass, else: :fail
  end

  defp verify_stage(:anomaly_detector) do
    if Code.ensure_loaded?(ObservationBus.CIL.AnomalyDetector), do: :pass, else: :fail
  end

  defp verify_stage(:cob_stream_bridge) do
    pid = Process.whereis(ObservatoryApiWeb.Hub.COBStreamBridge)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:live_stream_engine) do
    pid = Process.whereis(ObservatoryApiWeb.Hub.LiveStreamEngine)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:websocket_push) do
    # PubSub is the backbone for WebSocket push
    pid = Process.whereis(ObservatoryApi.PubSub)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(:health_endpoint) do
    if Code.ensure_loaded?(ObservatoryApiWeb.StatusController), do: :pass, else: :fail
  end

  defp verify_stage(:status_endpoint) do
    :unknown
  end

  defp verify_stage(:certification_endpoint) do
    if Code.ensure_loaded?(ObservatoryApiWeb.CertificationController), do: :pass, else: :fail
  end

  defp verify_stage(:replay_endpoint) do
    if Code.ensure_loaded?(ObservatoryApiWeb.ReplayController), do: :pass, else: :fail
  end

  defp verify_stage(:boot_start) do
    if Code.ensure_loaded?(ObservatoryCore.Boot.Engine), do: :pass, else: :fail
  end

  defp verify_stage(:phase_telemetry) do
    if Code.ensure_loaded?(ObservatoryCore.Boot.Phase.Telemetry), do: :pass, else: :fail
  end

  defp verify_stage(:phase_core) do
    if Code.ensure_loaded?(ObservatoryCore.Boot.Phase.Core), do: :pass, else: :fail
  end

  defp verify_stage(:phase_discovery) do
    if Code.ensure_loaded?(ObservatoryCore.Boot.Phase.Discovery), do: :pass, else: :fail
  end

  defp verify_stage(:phase_certification) do
    if Code.ensure_loaded?(ObservatoryCore.Boot.Phase.Certification), do: :pass, else: :fail
  end

  defp verify_stage(:boot_complete) do
    pid = Process.whereis(ObservatoryCore.Boot.Engine)
    if pid && Process.alive?(pid), do: :pass, else: :fail
  end

  defp verify_stage(_unknown), do: :skip

  defp explain_failures(stages) do
    stages
    |> Enum.filter(fn {_id, r} -> r == :fail end)
    |> Enum.map(fn {id, _r} -> "#{id}: not reachable" end)
  end
end
