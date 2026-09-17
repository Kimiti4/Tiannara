defmodule ObservationBus.Adapter.TelemetryGateway do
  @moduledoc """
  Converts `%Shared.TelemetryEvent{}` from the telemetry gateway pipeline
  into `%ObservationBus.Event{}` for the constitutional observation bus.
  """

  alias ObservationBus.Event

  @doc """
  Converts a TelemetryEvent or raw map to a COB ConstitutionalEvent.
  """
  @spec convert(Shared.TelemetryEvent.t() | map(), keyword()) :: Event.t()
  def convert(event, opts \\ [])

  def convert(%Shared.TelemetryEvent{} = tg_event, opts) do
    provenance = tg_event.provenance || %{}

    Event.new(
      id: tg_event.id,
      domain: tg_event.domain,
      source: tg_event.source,
      timestamp: parse_timestamp(tg_event.timestamp),
      generation: provenance[:generation] || 0,
      constitution: provenance[:constitution] || Shared.Constants.constitution_version(),
      runtime: provenance[:producer] || "telemetry_gateway",
      payload: tg_event.payload,
      priority: derive_priority(tg_event),
      evidence: build_evidence(tg_event),
      parent_id: Keyword.get(opts, :parent_id),
      metadata: build_metadata(tg_event)
    )
  end

  def convert(raw_event, opts) when is_map(raw_event) and not is_struct(raw_event) do
    provenance = raw_event[:provenance] || raw_event["provenance"] || %{}

    Event.new(
      id: raw_event[:id] || raw_event["id"],
      domain: raw_event[:domain] || raw_event["domain"],
      source: raw_event[:source] || raw_event["source"],
      timestamp: parse_timestamp(raw_event[:timestamp] || raw_event["timestamp"]),
      generation: provenance[:generation] || 0,
      constitution: provenance[:constitution] || Shared.Constants.constitution_version(),
      runtime: provenance[:producer] || "telemetry_gateway",
      payload: raw_event[:payload] || raw_event["payload"] || %{},
      priority: derive_priority_from_map(raw_event),
      evidence: raw_event[:evidence] || raw_event["evidence"] || [],
      parent_id: Keyword.get(opts, :parent_id),
      metadata: build_metadata_from_map(raw_event)
    )
  end

  defp parse_timestamp(%DateTime{} = dt), do: dt
  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end
  defp parse_timestamp(nil), do: DateTime.utc_now()
  defp parse_timestamp(_), do: DateTime.utc_now()

  defp derive_priority(%Shared.TelemetryEvent{domain: domain, classification: class}) do
    cond do
      class[:level] == "constitutional" -> 100
      domain =~ "certification" -> 90
      domain =~ "security" -> 80
      domain =~ "discovery" -> 70
      domain =~ "runtime" -> 60
      domain =~ "experiment" -> 50
      true -> 20
    end
  end

  defp derive_priority_from_map(event) do
    domain = event[:domain] || event["domain"] || ""
    class = event[:classification] || event["classification"] || %{}
    level = if is_map(class), do: class[:level] || class["level"], else: "internal"

    cond do
      level == "constitutional" -> 100
      domain =~ "certification" -> 90
      domain =~ "security" -> 80
      domain =~ "discovery" -> 70
      domain =~ "runtime" -> 60
      domain =~ "experiment" -> 50
      true -> 20
    end
  end

  defp build_evidence(%Shared.TelemetryEvent{signature: sig, certification: cert}) do
    evidence = []
    evidence = if sig, do: ["signed:#{inspect(sig)}" | evidence], else: evidence
    evidence = if cert, do: ["certified:#{cert.status}" | evidence], else: evidence
    evidence
  end

  defp build_metadata(%Shared.TelemetryEvent{} = tg_event) do
    %{
      source_version: tg_event.version,
      schema: tg_event.schema,
      clock: tg_event.clock,
      compression: tg_event.compression,
      retention: tg_event.retention,
      classification: tg_event.classification,
      provenance: tg_event.provenance,
      telemetry_event_id: tg_event.id,
    }
  end

  defp build_metadata_from_map(event) do
    %{
      source_version: event[:version] || event["version"],
      schema: event[:schema] || event["schema"],
      clock: event[:clock] || event["clock"],
      compression: event[:compression] || event["compression"],
      retention: event[:retention] || event["retention"],
      classification: event[:classification] || event["classification"],
      provenance: event[:provenance] || event["provenance"],
      telemetry_event_id: event[:id] || event["id"],
    }
  end
end
