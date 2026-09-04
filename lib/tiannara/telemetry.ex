defmodule Tiannara.Telemetry do
  @moduledoc """
  Telemetry configuration for Tiannara.

  Defines events, metrics, and monitoring for the cosmological runtime system.
  """

  use Supervisor
  require Logger

  @doc """
  Starts the Telemetry supervisor.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Tiannara.Telemetry.CompilationHandler, []},
      {Tiannara.Telemetry.PhysicsHandler, []},
      {Tiannara.Telemetry.TopologyHandler, []},
      {Tiannara.Telemetry.PhaseOmegaHandler, []}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end

defmodule Tiannara.Telemetry.CompilationHandler do
  @moduledoc """
  Telemetry handler for compilation events.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Subscribe to compilation events
    :telemetry.attach_many("compilation-handler", [
      [:tiannara, :compilation, :start],
      [:tiannara, :compilation, :stop],
      [:tiannara, :compilation, :exception]
    ], &handle_event/4, [])

    {:ok, %{}}
  end

  defp handle_event([:tiannara, :compilation, :start], _measurements, metadata, _config) do
    Logger.debug("Compilation started: #{metadata.compilation_type}")
    :ok
  end

  defp handle_event([:tiannara, :compilation, :stop], measurements, metadata, _config) do
    duration = measurements.duration || 0
    Logger.debug("Compilation completed in #{duration}ms: #{metadata.compilation_type}")
    :ok
  end

  defp handle_event([:tiannara, :compilation, :exception], _measurements, metadata, _config) do
    Logger.error("Compilation failed: #{metadata.compilation_type}, reason: #{metadata.exception}")
    :ok
  end
end

defmodule Tiannara.Telemetry.PhysicsHandler do
  @moduledoc """
  Telemetry handler for physics events.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Subscribe to physics events
    :telemetry.attach_many("physics-handler", [
      [:tiannara, :physics, :compilation, :start],
      [:tiannara, :physics, :compilation, :stop],
      [:tiannara, :physics, :observation, :recorded]
    ], &handle_event/4, [])

    {:ok, %{}}
  end

  defp handle_event([:tiannara, :physics, :compilation, :start], _measurements, metadata, _config) do
    Logger.debug("Physics compilation started: #{metadata.physics_type}")
    :ok
  end

  defp handle_event([:tiannara, :physics, :compilation, :stop], measurements, _metadata, _config) do
    duration = measurements.duration || 0
    Logger.debug("Physics compilation completed in #{duration}ms")
    :ok
  end

  defp handle_event([:tiannara, :physics, :observation, :recorded], _measurements, metadata, _config) do
    Logger.debug("Physics observation recorded: #{metadata.observer_id}")
    :ok
  end
end

defmodule Tiannara.Telemetry.TopologyHandler do
  @moduledoc """
  Telemetry handler for topology events.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Subscribe to topology events
    :telemetry.attach_many("topology-handler", [
      [:tiannara, :topology, :state, :changed],
      [:tiannara, :topology, :node, :added],
      [:tiannara, :topology, :node, :removed]
    ], &handle_event/4, [])

    {:ok, %{}}
  end

  defp handle_event([:tiannara, :topology, :state, :changed], _measurements, metadata, _config) do
    Logger.debug("Topology state changed: #{metadata.topology_type}")
    :ok
  end

  defp handle_event([:tiannara, :topology, :node, :added], _measurements, metadata, _config) do
    Logger.debug("Topology node added: #{metadata.node_id}")
    :ok
  end

  defp handle_event([:tiannara, :topology, :node, :removed], _measurements, metadata, _config) do
    Logger.debug("Topology node removed: #{metadata.node_id}")
    :ok
  end
end

defmodule Tiannara.Telemetry.PhaseOmegaHandler do
  @moduledoc """
  Telemetry handler for Phase Ω subsystem lifecycle events.

  Attaches to the events required by Ω.9 Telemetry Coverage Audit.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :telemetry.attach_many("phase-omega-handler", [
      [:tiannara, :subsystem, :registered],
      [:tiannara, :subsystem, :booted],
      [:tiannara, :subsystem, :failed],
      [:tiannara, :subsystem, :heartbeat],
      [:tiannara, :event, :emitted],
      [:tiannara, :event, :processed],
      [:tiannara, :metric, :recorded],
      [:observatory, :event, :ingested],
      [:observatory, :boot, :phase_start],
      [:observatory, :boot, :phase_complete],
      [:observatory, :error, :unhandled]
    ], &handle_event/4, [])

    {:ok, %{}}
  end

  defp handle_event([:tiannara, :subsystem, :registered], _measurements, metadata, _config) do
    Logger.debug("[PhaseΩ:Telemetry] Subsystem registered: #{metadata.name}")
    :ok
  end

  defp handle_event([:tiannara, :subsystem, :booted], _measurements, metadata, _config) do
    Logger.info("[PhaseΩ:Telemetry] Subsystem booted: #{metadata.name}")
    :ok
  end

  defp handle_event([:tiannara, :subsystem, :failed], _measurements, metadata, _config) do
    Logger.warning("[PhaseΩ:Telemetry] Subsystem failed: #{metadata.name}")
    :ok
  end

  defp handle_event([:tiannara, :subsystem, :heartbeat], _measurements, metadata, _config) do
    Logger.debug("[PhaseΩ:Telemetry] Subsystem heartbeat: #{metadata.name}")
    :ok
  end

  defp handle_event([:tiannara, :event, :emitted], _measurements, metadata, _config) do
    Logger.debug("[PhaseΩ:Telemetry] Event emitted: #{inspect(metadata.event)}")
    :ok
  end

  defp handle_event([:tiannara, :event, :processed], _measurements, metadata, _config) do
    Logger.debug("[PhaseΩ:Telemetry] Event processed: #{inspect(metadata.event)}")
    :ok
  end

  defp handle_event([:tiannara, :metric, :recorded], measurements, metadata, _config) do
    Logger.debug("[PhaseΩ:Telemetry] Metric recorded: #{inspect(metadata.metric)} = #{inspect(measurements)}")
    :ok
  end

  defp handle_event([:observatory, :event, :ingested], _measurements, metadata, _config) do
    Logger.debug("[PhaseΩ:Telemetry] Observatory event ingested: #{inspect(metadata)}")
    :ok
  end

  defp handle_event([:observatory, :boot, :phase_start], _measurements, metadata, _config) do
    Logger.info("[PhaseΩ:Telemetry] Observatory boot phase start: #{inspect(metadata)}")
    :ok
  end

  defp handle_event([:observatory, :boot, :phase_complete], _measurements, metadata, _config) do
    Logger.info("[PhaseΩ:Telemetry] Observatory boot phase complete: #{inspect(metadata)}")
    :ok
  end

  defp handle_event([:observatory, :error, :unhandled], _measurements, metadata, _config) do
    Logger.warning("[PhaseΩ:Telemetry] Observatory unhandled error: #{inspect(metadata)}")
    :ok
  end
end