defmodule TelemetryGateway.SchemaValidator do
  @required_fields [:id, :domain, :timestamp, :version, :source]
  @valid_domains MapSet.new(Shared.Constants.event_domains())
  @max_payload_bytes 2_000_000

  def validate(event) do
    missing =
      Enum.reject(@required_fields, fn f -> Map.has_key?(event, f) and not is_nil(event[f]) end)

    if missing != [] do
      {:error, :missing_fields, missing}
    else
      with :ok <- validate_uuid(event.id),
           :ok <- validate_domain(event.domain),
           :ok <- validate_timestamp(event.timestamp),
           :ok <- validate_payload(event),
           :ok <- validate_version(event.version),
           :ok <- validate_runtime_generation(event) do
        {:ok, event}
      end
    end
  end

  defp validate_uuid(id) do
    case Ecto.UUID.cast(id) do
      {:ok, _} -> :ok
      _ -> {:error, :invalid_uuid, id}
    end
  end

  defp validate_domain(domain) do
    if MapSet.member?(@valid_domains, domain) do
      :ok
    else
      {:error, :unknown_domain, domain}
    end
  end

  defp validate_timestamp(ts) when is_integer(ts), do: :ok
  defp validate_timestamp(%DateTime{}), do: :ok

  defp validate_timestamp(ts) when is_binary(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, _, _} -> :ok
      _ -> {:error, :invalid_timestamp, ts}
    end
  end

  defp validate_timestamp(ts), do: {:error, :invalid_timestamp, ts}

  defp validate_payload(event) do
    payload = Map.get(event, :payload, event["payload"])

    cond do
      is_nil(payload) ->
        {:error, :missing_payload, nil}

      not is_map(payload) ->
        {:error, :invalid_payload_type, payload}

      byte_size(:erlang.term_to_binary(payload)) > @max_payload_bytes ->
        {:error, :payload_too_large, byte_size(:erlang.term_to_binary(payload))}

      true ->
        :ok
    end
  end

  defp validate_version(version) when is_binary(version), do: :ok
  defp validate_version(_), do: {:error, :invalid_version}

  defp validate_runtime_generation(event) do
    case Map.get(event, :runtime_generation, event["runtime_generation"]) do
      nil -> :ok
      gen when is_integer(gen) and gen >= 0 -> :ok
      _ -> {:error, :invalid_runtime_generation}
    end
  end
end
