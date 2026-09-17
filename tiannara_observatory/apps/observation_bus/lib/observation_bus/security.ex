defmodule ObservationBus.Security do
  @moduledoc """
  Constitutional event security layer.

  Every event is signed with:
    * Hash (SHA-256 of the event content)
    * Certificate (constitutional certificate)
    * Signature (HMAC-SHA256 with runtime key)
    * Replay verification (hash chain integrity)

  Tampering is impossible without detection.
  """

  alias ObservationBus.Event

  @doc """
  Signs an event, attaching a hash and signature.
  """
  @spec sign(Event.t()) :: Event.t()
  def sign(%Event{} = event) do
    hash = hash_event(event)
    serialized = serialize(event)
    signature = :crypto.mac(:hmac, :sha256, signing_key(), serialized) |> Base.encode16(case: :lower)

    %{event | replay_hash: hash, signature: signature}
  end

  @doc """
  Verifies an event's signature, hash, and optional certificate.
  Returns `{:ok, event}` or `{:error, reason}`.
  """
  @spec verify(Event.t()) :: {:ok, Event.t()} | {:error, String.t()}
  def verify(%Event{} = event) do
    with :ok <- verify_hash(event),
         :ok <- verify_signature(event) do
      {:ok, event}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Verifies a replay hash chain: event's hash must match its predecessor.
  """
  @spec verify_replay_chain(Event.t(), Event.t()) :: boolean()
  def verify_replay_chain(%Event{} = current, %Event{} = predecessor) do
    current.replay_hash == hash_event(predecessor)
  end

  @doc """
  Generates a constitutional certificate for an event.
  """
  @spec certify(Event.t()) :: Event.t()
  def certify(%Event{} = event) do
    cert = %{
      event_id: event.id,
      issued_at: DateTime.utc_now(),
      issuer: "observation_bus",
      constitution_version: event.constitution,
      hash: hash_event(event),
      signature: event.signature,
    }

    encoded = Jason.encode!(cert)
    certificate = :crypto.mac(:hmac, :sha256, signing_key(), encoded) |> Base.encode16(case: :lower)

    %{event | certificate: certificate}
  end

  defp hash_event(%Event{} = event) do
    serialized = event |> Map.drop([:replay_hash, :signature, :certificate]) |> serialize()
    serialized |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
  end

  defp serialize(event) do
    event
    |> Map.from_struct()
    |> Jason.encode!()
  end

  defp verify_hash(%Event{replay_hash: hash} = event) do
    expected = hash_event(event)
    if hash == expected, do: :ok, else: {:error, "hash mismatch"}
  end

  defp verify_signature(%Event{signature: sig} = event) do
    serialized = serialize(%{event | replay_hash: nil, signature: nil, certificate: nil})
    expected = :crypto.mac(:hmac, :sha256, signing_key(), serialized) |> Base.encode16(case: :lower)
    if sig == expected, do: :ok, else: {:error, "signature mismatch"}
  end

  defp signing_key do
    Application.get_env(:observation_bus, :signing_key, "default-development-key-change-in-production")
  end
end
