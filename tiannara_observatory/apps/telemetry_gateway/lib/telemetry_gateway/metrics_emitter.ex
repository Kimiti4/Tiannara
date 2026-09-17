defmodule TelemetryGateway.MetricsEmitter do
  @doc """
  Emits canonical events to downstream consumers and the Constitutional Observation Bus.
  """
  def emit(event) do
    :telemetry.execute([:observatory, :event, :received], %{count: 1}, %{event: event})
    EventStore.Writer.write(event)
    EventStore.Publisher.broadcast(event)
    publish_to_cob(event)
  end

  defp publish_to_cob(event) do
    with {:module, adapter} <- Code.ensure_loaded(ObservationBus.Adapter.TelemetryGateway),
         {:module, router} <- Code.ensure_loaded(ObservationBus.Router) do
      cob_event = adapter.convert(event)
      router.publish(cob_event)
    else
      _ -> :ok
    end
  end
end

defmodule TelemetryGateway.MetricsProxy do
  def forward(event, domain) do
    :telemetry.execute([:observatory, :event, :routed], %{count: 1}, %{
      event: event,
      domain: domain
    })
  end
end
