defmodule TelemetryGateway.Handler.PlanetaryHandler do
  def handle(event) do
    TelemetryGateway.MetricsEmitter.emit(event)
    TelemetryGateway.MetricsProxy.forward(event, :planetary)
  end
end
