defmodule TelemetryGateway.Handler.ScienceHandler do
  def handle(event) do
    TelemetryGateway.MetricsEmitter.emit(event)
    TelemetryGateway.MetricsProxy.forward(event, :scientific)
  end
end
