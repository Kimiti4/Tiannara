defmodule TelemetryGateway.Handler.EngineeringHandler do
  def handle(event) do
    TelemetryGateway.MetricsEmitter.emit(event)
    TelemetryGateway.MetricsProxy.forward(event, :engineering)
  end
end
