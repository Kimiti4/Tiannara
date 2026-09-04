defmodule Tiannara.Omega.Supervisor do
  @moduledoc """
  The Ω supervised process tree. Converts the validated Ω components into a
  continuously operating, self-healing agency.

  Supervision strategy is `:rest_for_one`: if a child crashes, every child
  started AFTER it is restarted in order. This enforces the dependency chain:

      EventBus (foundation)
        → TelemetryWindow (observation buffer)
          → Heartbeat (observe → emit)
            → AgencyOrchestrator (routes events)
              → ResearchDirector / CognitiveInterface / Sandbox
                → Certification
                  → GovernanceGate (terminal authority)

  CRITICAL INVARIANTS:
    * A child crash causes GRACEFUL DEGRADATION, never autonomous escalation.
    * Ordering enforces that the Sentinel observes before the Director
      investigates.
    * Each child remains independently replaceable.

  Constitutional basis: Safety and Reliability ("Recover gracefully", "Preserve
  previous stable states"), Architecture Philosophy (clear responsibilities,
  explicit interfaces, independent replacement), Fault tolerance.
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Stop the supervisor tree (test/teardown helper)."
  def stop(sup, reason \\ :normal) do
    Supervisor.stop(sup, reason)
  end

  @impl true
  def init(opts) do
    children = [
      # Foundation: event bus (no dependencies)
      {Tiannara.Runtime.EventBus, [name: bus_name(opts)]},

      # Observation layer
      {Tiannara.Omega.TelemetryWindow, telemetry_window_opts(opts)},

      # Sentinel heartbeat (depends on TelemetryWindow)
      {Tiannara.Sentinel.Heartbeat.Server, heartbeat_opts(opts)},

      # Agency orchestration (routes events)
      {Tiannara.Omega.AgencyOrchestrator, orchestrator_opts(opts)},

      # Investigation
      {Tiannara.Omega.ResearchDirectorServer, research_director_opts(opts)},

      # Communication decisions
      {Tiannara.Omega.CognitiveInterfaceServer, cognitive_interface_opts(opts)},

      # Validation
      {Tiannara.Omega.ImprovementSandboxServer, sandbox_opts(opts)},

      # Certification
      {Tiannara.Omega.CertificationServer, certification_opts(opts)},

      # Governance (terminal authority)
      {Tiannara.Omega.GovernanceGateServer, governance_opts(opts)}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  # --- child option builders ---------------------------------------------

  defp bus_name(opts), do: Keyword.get(opts, :bus_name, Tiannara.Runtime.EventBus)

  defp telemetry_window_opts(opts) do
    [
      name: Keyword.get(opts, :telemetry_window_name, Tiannara.Omega.TelemetryWindow),
      adapter: Keyword.get(opts, :telemetry_adapter, Tiannara.Telemetry.RuntimeAdapter),
      window_size: Keyword.get(opts, :window_size, 5),
      bus: bus_name(opts)
    ]
  end

  defp heartbeat_opts(opts) do
    base = Tiannara.Telemetry.SentinelBridge.build_heartbeat_opts(
      adapter: Keyword.get(opts, :telemetry_adapter, Tiannara.Telemetry.RuntimeAdapter),
      window_size: Keyword.get(opts, :window_size, 5)
    )

    base
    |> Keyword.put(:name, Keyword.get(opts, :heartbeat_name, Tiannara.Sentinel.Heartbeat.Server))
    |> Keyword.put(:interval, Keyword.get(opts, :heartbeat_interval, 1_000))
    |> Keyword.put(:bus, bus_name(opts))
  end

  defp orchestrator_opts(opts) do
    [
      name: Keyword.get(opts, :orchestrator_name, Tiannara.Omega.AgencyOrchestrator),
      bus: bus_name(opts),
      research_director:
        Keyword.get(opts, :research_director_name, Tiannara.Omega.ResearchDirectorServer),
      cognitive_interface:
        Keyword.get(opts, :cognitive_interface_name, Tiannara.Omega.CognitiveInterfaceServer),
      sandbox: Keyword.get(opts, :sandbox_name, Tiannara.Omega.ImprovementSandboxServer)
    ]
  end

  defp research_director_opts(opts) do
    [
      name: Keyword.get(opts, :research_director_name, Tiannara.Omega.ResearchDirectorServer),
      bus: bus_name(opts)
    ]
  end

  defp cognitive_interface_opts(opts) do
    [
      name: Keyword.get(opts, :cognitive_interface_name, Tiannara.Omega.CognitiveInterfaceServer),
      bus: bus_name(opts)
    ]
  end

  defp sandbox_opts(opts) do
    [
      name: Keyword.get(opts, :sandbox_name, Tiannara.Omega.ImprovementSandboxServer),
      bus: bus_name(opts)
    ]
  end

  defp certification_opts(opts) do
    [
      name: Keyword.get(opts, :certification_name, Tiannara.Omega.CertificationServer),
      bus: bus_name(opts)
    ]
  end

  defp governance_opts(opts) do
    [
      name: Keyword.get(opts, :governance_name, Tiannara.Omega.GovernanceGateServer),
      bus: bus_name(opts)
    ]
  end
end