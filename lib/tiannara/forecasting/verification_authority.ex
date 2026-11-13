defmodule Tiannara.Forecasting.VerificationAuthority do
  use Agent

  @moduledoc """
  The verification authority.

  A verification record's `record_digest` is an HMAC-SHA256 over the record's
  canonical fields, keyed by a secret held inside this process.

  ## What this does and does not establish

  The HMAC raises the bar from "construct a map" to "obtain the key". It does
  **not** provide a security boundary against code running inside the same
  BEAM: the signing operation is a normal function call and the key lives in
  process state. Anyone who can call this module, or read this process's
  state, can sign an arbitrary record. The HMAC is therefore **integrity and
  provenance-within-a-process**, not cryptographic authentication against
  untrusted code.

  The key is also **ephemeral**: every restart generates a new one, so
  previously signed records will not authenticate against the replacement
  key. Historical records are authenticated by **re-execution** against the
  immutable evidence store, not by the key. The key is a tampering detector
  within a single process lifetime; re-execution is the recovery authority.

  These are the same standing limitations as TCP-B-058 and TCP-B-061, and
  they are stated here rather than hidden. A protected, persistent signing
  key with explicit key identity, rotation and recovery rules is registered
  as TCP-B-067 for TCP-002.7.

  This authority is always supervised. When it is unreachable, verification
  cannot be performed and resolution cannot be acknowledged.
  """

  @doc "The registered name of the verification authority."
  @spec server() :: atom()
  def server, do: Application.get_env(:tiannara, :verification_authority_name) || __MODULE__

  @spec start_link(keyword()) :: Agent.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, server())
    key = :crypto.strong_rand_bytes(32)
    Agent.start_link(fn -> %{key: key} end, name: name)
  end

  @doc false
  @spec sign(map(), atom()) :: binary() | nil
  def sign(record, name \\ server()) when is_map(record) do
    key = Agent.get(name, & &1.key)
    :crypto.mac(:hmac, :sha256, key, :erlang.term_to_binary(canonical(record)))
  rescue
    _error -> nil
  catch
    :exit, _reason -> nil
  end

  @doc """
  Verifies a verification record's signature.
  """
  @spec verify(map(), atom()) :: :ok | {:error, atom()}
  def verify(record, name \\ server()) when is_map(record) do
    case sign(record, name) do
      nil ->
        {:error, :verification_authority_unavailable}

      mac ->
        if mac == Map.get(record, :record_digest) do
          :ok
        else
          {:error, :verification_record_unauthentic}
        end
    end
  end

  defp canonical(record) do
    {:tiannara_verification_v1, Map.get(record, :forecast_id),
     Map.get(record, :forecast_digest), Map.get(record, :outcome_definition_digest),
     Map.get(record, :horizon_digest), Map.get(record, :observation_id),
     Map.get(record, :observation_digest), Map.get(record, :evidence_digest),
     Map.get(record, :source_identity),
     Map.get(record, :verification_policy_version), Map.get(record, :status),
     Map.get(record, :reason), Map.get(record, :verified_at),
     Map.get(record, :assurance)}
  end
end
