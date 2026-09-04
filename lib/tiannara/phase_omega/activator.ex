defmodule Tiannara.PhaseOmega.Activator do

  @moduledoc """
  Post-boot activator that orchestrates the full Phase Ω activation.

  Called once after the main supervision tree is healthy. Runs in order:

    1. Register known running subsystems
    2. Auto-discover all BEAM processes
    3. Wire dark subsystems via WiringEngine
    4. Verify dependency graph
    5. Boot dark subsystems in dependency order (with retry + certs)
    6. Run health verification
    7. Run dependency verification report
  """

  require Logger

  def bootstrap do
    Logger.info("[PhaseΩ] Starting subsystem activation...")

    :ok = register_running()
    :ok = run_auto_discovery()
    :ok = Tiannara.PhaseOmega.WiringEngine.wire_all()
    :ok = check_dependency_graph()

    case Tiannara.PhaseOmega.BootSequencer.boot() do
      :ok ->
        Logger.info("[PhaseΩ] All dark subsystems booted successfully")
        Tiannara.PhaseOmega.RuntimeVerifier.verify_all()
        Tiannara.PhaseOmega.DependencyVerifier.report()

      {:error, reason} ->
        Logger.error("[PhaseΩ] Boot failed: #{reason}")
    end

    Tiannara.PhaseOmega.Scanner.print_report()
  end

  def register_running do
    running = [
      %{name: :telemetry, module: Tiannara.Telemetry, deps: [], app: :tiannara, description: "Telemetry event handlers"},
      %{name: :civilization_kernel, module: TiannaraOS.CivilizationKernel, deps: [], app: :tiannara, description: "Top-level state substrate"},
      %{name: :latent_vault, module: Tiannara.LEOC.LatentVault, deps: [], app: :tiannara, description: "Latent Epistemic Ontological Cache"},
      %{name: :ros, module: Tiannara.ROS.Registry, deps: [], app: :tiannara, description: "Reality Ontological Shard registry"},
      %{name: :rel, module: Tiannara.REL.EconomyEngine, deps: [:ros], app: :tiannara, description: "Reality Economics Layer"},
      %{name: :omcs, module: Tiannara.OMCS.Supervisor, deps: [], app: :tiannara, description: "Ontological Memory Continuity System"},
      %{name: :core, module: Tiannara.Core.Supervisor, deps: [:ros], app: :tiannara, description: "Core ontology and indexing"},
      %{name: :stabilization, module: Tiannara.Stabilization.Supervisor, deps: [:core], app: :tiannara, description: "HSV, OCM, OLEF stabilization layers"},
      %{name: :physics, module: Tiannara.Physics.Supervisor, deps: [:core], app: :tiannara, description: "OPC, NDE, TWP, IRD physics compilation"},
      %{name: :topology, module: Tiannara.Topology.Supervisor, deps: [:core], app: :tiannara, description: "RRG, ACF, CCR, DFG, OSL topology"},
      %{name: :sentinel, module: Tiannara.Sentinel.Supervisor, deps: [:stabilization, :physics], app: :tiannara, description: "Threat detection and immune coordination"},
      %{name: :sentinel_d2, module: Tiannara.Sentinel.D2.EpistemologyGraph, deps: [:sentinel], app: :tiannara, description: "Sentinel D2 — Science of Science"},
      %{name: :command_loom, module: Tiannara.AAL.CommandLoom, deps: [], app: :tiannara, description: "Jarvis Command Loom"},
      %{name: :hardware, module: Tiannara.Meta.Hardware.Supervisor, deps: [], app: :tiannara, description: "Event Horizon Tensor Cores"},
      %{name: :pubsub, module: Phoenix.PubSub, deps: [], app: :phoenix_pubsub, description: "Phoenix PubSub"},
      %{name: :endpoint, module: TiannaraWeb.Endpoint, deps: [:pubsub], app: :tiannara, description: "Phoenix HTTP endpoint"}
    ]

    asc = case Process.whereis(Tiannara.ASC.Supervisor) do
      nil -> []
      _ -> [%{name: :asc, module: Tiannara.ASC.Supervisor, deps: [:sentinel], app: :tiannara, description: "Autonomous Software Civilization"}]
    end

    (running ++ asc)
    |> Enum.each(fn spec ->
      Tiannara.PhaseOmega.SubsystemRegistry.register(spec.name, spec)
      Tiannara.PhaseOmega.SubsystemRegistry.transition(spec.name, :healthy)
    end)

    Logger.info("[PhaseΩ] Registered #{length(running) + length(asc)} running subsystems")
  end

  defp run_auto_discovery do
    Tiannara.PhaseOmega.RuntimeDiscoverer.run_full_discovery()
  end

  defp check_dependency_graph do
    cycles = Tiannara.PhaseOmega.SubsystemRegistry.detect_cycles()
    if cycles != [] do
      Logger.warning("[PhaseΩ] Circular dependencies: #{inspect(cycles)}")
    end

    missing = Tiannara.PhaseOmega.SubsystemRegistry.detect_missing_deps()
    if missing != [] do
      Logger.warning("[PhaseΩ] Missing dependencies: #{inspect(missing)}")
    end

    :ok
  end
end
