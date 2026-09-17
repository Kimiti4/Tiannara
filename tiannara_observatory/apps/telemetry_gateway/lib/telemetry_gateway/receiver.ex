defmodule TelemetryGateway.Receiver do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def ingest(event) do
    GenServer.cast(__MODULE__, {:ingest, event})
  end

  @impl true
  def init(_opts) do
    :telemetry.attach_many(
      "observatory_gateway",
      [
        [:observatory, :event, :ingested]
      ],
      &handle_telemetry/4,
      :no_config
    )

    {:ok, %{event_count: 0}}
  end

  @impl true
  def handle_cast({:ingest, raw_event}, state) do
    TelemetryGateway.TelemetryAuditor.record(:ingested)
    process_pipeline(raw_event)
    {:noreply, %{state | event_count: state.event_count + 1}}
  end

  defp process_pipeline(raw) do
    with {:ok, validated} <- TelemetryGateway.SchemaValidator.validate(raw),
         normalized = TelemetryGateway.EventNormalizer.normalize(validated),
         {:ok, verified} <- TelemetryGateway.SignatureVerifier.verify(normalized),
         {:ok, _replay_verified} <- TelemetryGateway.ReplayVerifier.verify(verified) do
      TelemetryGateway.TelemetryAuditor.record(:validated)

      if TelemetryGateway.Deduplicator.seen?(normalized) do
        TelemetryGateway.TelemetryAuditor.record(:duplicate)
        TelemetryGateway.DeadLetterQueue.enqueue(normalized, :duplicate_event)
      else
        TelemetryGateway.Deduplicator.mark_seen(normalized)
        ordered = TelemetryGateway.EventSequencer.assign(normalized)
        TelemetryGateway.DomainRouter.route(ordered)
        TelemetryGateway.Buffer.push(ordered)
        TelemetryGateway.TelemetryAuditor.record(:routed)
      end
    else
      {:error, reason, detail} ->
        TelemetryGateway.TelemetryAuditor.record(:malformed)
        TelemetryGateway.TelemetryAuditor.record(:validation_error, reason)
        TelemetryGateway.DeadLetterQueue.enqueue(raw, reason, detail)

      _ ->
        TelemetryGateway.TelemetryAuditor.record(:dropped)
        TelemetryGateway.DeadLetterQueue.enqueue(raw, :unknown_validation_error)
    end
  end

  defp handle_telemetry(_event, _measurements, _metadata, _config), do: :ok
end
