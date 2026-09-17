defmodule TelemetryGateway.Handler.EvolutionHandler do
  def handle(event) do
    TelemetryGateway.MetricsEmitter.emit(event)
    TelemetryGateway.MetricsProxy.forward(event, :evolution)
  end
end
