defmodule Tiannara.ExecutiveService do
  @moduledoc """
  Behaviour contract for all Executive Services in the EOS.

  Every service must implement these 14 callbacks to be eligible
  for registration in the ServiceRegistry and lifecycle management
  by the Executive Kernel.
  """

  @type service_id :: atom()
  @type version :: String.t()
  @type capability :: atom()
  @type capabilities :: [capability()]
  @type dependencies :: [service_id()]
  @type boot_result :: {:ok, pid()} | {:error, term()}
  @type health_status :: :healthy | :degraded | :unhealthy
  @type shutdown_reason :: :normal | :upgrade | :degradation | :emergency
  @type upgrade_result :: :ok | {:error, term()}

  @doc "Unique service identifier (atom, e.g. :executive_memory)"
  @callback id() :: service_id()

  @doc "Semantic version string"
  @callback version() :: version()

  @doc "List of capabilities this service provides"
  @callback capabilities() :: capabilities()

  @doc "List of service IDs this service depends on"
  @callback dependencies() :: dependencies()

  @doc "Boot the service; return {:ok, pid} or {:error, reason}"
  @callback boot(keyword()) :: boot_result()

  @doc "Gracefully shut down the service"
  @callback shutdown(shutdown_reason()) :: :ok

  @doc "Return current health status"
  @callback health() :: health_status()

  @doc "Return the service's constitutional score snapshot"
  @callback constitutional_score() :: Tiannara.CEL.Kernel.ConstitutionalScore.t()

  @doc "Attempt recovery from a degraded or unhealthy state"
  @callback recover(map()) :: :ok | {:error, term()}

  @doc "Upgrade the service to a new version"
  @callback upgrade(version(), map()) :: upgrade_result()

  @doc "Degrade the service gracefully (reduce functionality)"
  @callback degrade(map()) :: :ok

  @doc "Return service priority level for scheduling"
  @callback priority() :: :critical | :high | :medium | :low

  @doc "Return runtime metadata map"
  @callback metadata() :: map()

  @doc "Handle a telemetry event emitted by another service"
  @callback handle_event(atom(), map(), map()) :: :ok

  @doc "Validate that the service's internal state is consistent"
  @callback validate_state() :: :ok | {:error, [term()]}

  @optional_callbacks [
    capabilities: 0,
    dependencies: 0,
    priority: 0,
    recover: 1,
    upgrade: 2,
    degrade: 1,
    metadata: 0,
    handle_event: 3,
    validate_state: 0
  ]
end
