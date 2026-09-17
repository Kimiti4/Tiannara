defmodule TelemetryGateway.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      TelemetryGateway.Receiver,
      TelemetryGateway.SchemaValidator,
      TelemetryGateway.EventNormalizer,
      TelemetryGateway.SignatureVerifier,
      TelemetryGateway.ReplayVerifier,
      TelemetryGateway.Deduplicator,
      TelemetryGateway.EventSequencer,
      TelemetryGateway.DomainRouter,
      TelemetryGateway.BackpressureManager,
      TelemetryGateway.DeadLetterQueue,
      TelemetryGateway.TelemetryAuditor,
      TelemetryGateway.MetricsEmitter,
      TelemetryGateway.Buffer,
      TelemetryGateway.NATSBridge
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
