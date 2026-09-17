defmodule TelemetryGateway.Handler.GovernanceHandler do
  def handle(event) do
    TelemetryGateway.MetricsEmitter.emit(event)
    TelemetryGateway.MetricsProxy.forward(event, :governance)
  end
end
