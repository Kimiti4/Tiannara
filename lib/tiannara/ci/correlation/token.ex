defmodule Tiannara.CI.Correlation.Token do
  @moduledoc """
  Generates and validates cryptographically-strong correlation tokens.

  A token embeds a millisecond timestamp (for ordering) plus 16 bytes of
  strong randomness (for collision resistance), Base16-encoded. Tokens are
  collision-resistant and uniquely identify a CI dispatch.

  Constitutional basis: Security by design, "Support reproducibility",
  "Maintain audit trails."
  """

  @random_bytes 16
  @timestamp_bytes 8
  @total_bytes @random_bytes + @timestamp_bytes

  @doc "Generate a unique, collision-resistant correlation token."
  def generate do
    timestamp = System.system_time(:millisecond)
    random = :crypto.strong_rand_bytes(@random_bytes)
    Base.encode16(<<timestamp::64>> <> random, case: :lower)
  end

  @doc "Validate that a token is well-formed."
  def valid?(token) when is_binary(token) do
    case Base.decode16(token, case: :lower) do
      {:ok, decoded} -> byte_size(decoded) == @total_bytes
      :error -> false
    end
  end

  def valid?(_), do: false

  @doc "Extract the timestamp from a token (for ordering/auditing)."
  def timestamp(token) when is_binary(token) do
    case Base.decode16(token, case: :lower) do
      {:ok, <<timestamp::64, _rest::binary>>} -> {:ok, timestamp}
      _ -> {:error, :invalid_token}
    end
  end
end