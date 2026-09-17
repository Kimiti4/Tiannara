defmodule TelemetryGateway.SignatureVerifier do
  @doc """
  Verify HMAC signature on telemetry events.
  Expects event.signature to contain %{algorithm: "HMAC-SHA256", value: hex, key_id: string}.
  """
  def verify(event) do
    sig = event[:signature] || event.signature || %{}

    case sig[:algorithm] || sig["algorithm"] do
      nil -> {:ok, event}
      "HMAC-SHA256" -> verify_hmac(event, sig)
      algo -> {:error, :unsupported_algorithm, algo}
    end
  end

  defp verify_hmac(event, sig) do
    expected = sig[:value] || sig["value"]
    key_id = sig[:key_id] || sig["key_id"]

    secret =
      Application.get_env(:telemetry_gateway, :signing_secrets, %{})
      |> Map.get(key_id)

    case secret do
      nil ->
        {:error, :unknown_key_id, key_id}

      secret when is_binary(secret) ->
        payload = build_signing_payload(event)
        computed = :crypto.mac(:hmac, :sha256, secret, payload) |> Base.encode16(case: :lower)

        if computed == String.downcase(expected) do
          {:ok, event}
        else
          {:error, :signature_mismatch, %{expected: expected, computed: computed}}
        end
    end
  end

  defp build_signing_payload(event) do
    "#{event.id}:#{event.domain}:#{event.timestamp}:#{Jason.encode!(event.payload)}"
  end
end
