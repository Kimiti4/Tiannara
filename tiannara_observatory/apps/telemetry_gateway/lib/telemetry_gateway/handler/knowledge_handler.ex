defmodule TelemetryGateway.Handler.KnowledgeHandler do
  def handle(event) do
    TelemetryGateway.MetricsEmitter.emit(event)
    TelemetryGateway.MetricsProxy.forward(event, :knowledge)
  end
end
