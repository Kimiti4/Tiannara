defmodule TelemetryGateway.Handler.DiscoveryHandler do
  def handle(event) do
    TelemetryGateway.MetricsEmitter.emit(event)
    TelemetryGateway.MetricsProxy.forward(event, :discovery)
  end
end
