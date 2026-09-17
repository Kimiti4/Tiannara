defmodule TelemetryGateway.Handler.CertificationHandler do
  def handle(event) do
    TelemetryGateway.MetricsEmitter.emit(event)
    TelemetryGateway.MetricsProxy.forward(event, :certification)
  end
end
