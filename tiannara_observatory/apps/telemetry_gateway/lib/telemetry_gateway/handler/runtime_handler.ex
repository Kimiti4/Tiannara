defmodule TelemetryGateway.Handler.RuntimeHandler do
  def handle(event) do
    TelemetryGateway.MetricsEmitter.emit(event)
    TelemetryGateway.MetricsProxy.forward(event, :runtime)
  end
end
