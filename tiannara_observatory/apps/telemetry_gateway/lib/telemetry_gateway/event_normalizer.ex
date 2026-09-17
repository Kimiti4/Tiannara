defmodule TelemetryGateway.EventNormalizer do
  @doc """
  Convert any source event into canonical TelemetryEvent format.
  Accepts maps (from NATS, OTel, etc.) and %Shared.TelemetryEvent{} structs.
  """
  def normalize(event) when is_struct(event, Shared.TelemetryEvent) do
    event
    |> Map.from_struct()
    |> normalize()
  end

  def normalize(event) when is_map(event) do
    now = DateTime.utc_now()

    %Shared.TelemetryEvent{
      id: event[:id] || event["id"] || Ecto.UUID.generate(),
      source: event[:source] || event["source"] || "unknown",
      version: event[:version] || event["version"] || Shared.Constants.schema_version(),
      timestamp: normalize_timestamp(event[:timestamp] || event["timestamp"] || now),
      clock:
        event[:clock] || event["clock"] ||
          %{wall_time: System.system_time(:millisecond), logical: 0},
      provenance:
        event[:provenance] || event["provenance"] ||
          %{
            producer: "observatory",
            pipeline: [],
            generation: 0,
            constitution: Shared.Constants.constitution_version(),
            operator: nil
          },
      signature: event[:signature] || event["signature"],
      schema: event[:schema] || event["schema"] || Shared.Constants.schema_version(),
      domain: event[:domain] || event["domain"],
      classification:
        event[:classification] || event["classification"] ||
          %{level: "internal", compartments: [], need_to_know: false},
      replay_id: event[:replay_id] || event["replay_id"],
      lineage: event[:lineage] || event["lineage"],
      compression: event[:compression] || event["compression"] || "none",
      retention: event[:retention] || event["retention"] || Shared.Constants.default_retention(),
      certification: event[:certification] || event["certification"],
      payload: event[:payload] || event["payload"] || %{}
    }
  end

  defp normalize_timestamp(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp normalize_timestamp(ts) when is_integer(ts),
    do: DateTime.to_iso8601(DateTime.from_unix!(ts, :millisecond))

  defp normalize_timestamp(ts) when is_binary(ts), do: ts
  defp normalize_timestamp(_), do: DateTime.to_iso8601(DateTime.utc_now())
end
