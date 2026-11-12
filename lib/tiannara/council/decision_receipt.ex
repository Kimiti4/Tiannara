defmodule Tiannara.Council.DecisionReceipt do
  @moduledoc """
  Council-issued, MAC-protected, scoped, expiring, one-time decision receipt
  (RL-565 / CP19.20).

  A receipt is **evidence that Council evaluated and issued this exact
  decision**. It is not a decision and it grants no permission by itself. The
  struct is constructible by any caller; only a holder of the Council receipt
  key can produce a valid `:mac`, and only the registered Council process may
  sign one during normal operation. Test code may sign fixtures only when
  `config :tiannara, :allow_test_receipt_signing, true` (set exclusively in
  `config/test.exs`).

  The MAC covers every authority-bearing field through
  `Tiannara.Council.DecisionDigest.receipt_identity/1`, including the canonical
  encoder version. The `:mac` field is excluded from the payload.

  Key management: the receipt key is read from
  `config :tiannara, :council_receipt_key`. It must be provisioned outside the
  repository, rotated deliberately, and never logged. A missing or short key
  fails closed (`:council_receipt_unavailable`), never open.
  """

  @enforce_keys [
    :receipt_id,
    :decision_digest,
    :decision_type,
    :scope_digest,
    :actor,
    :issued_at,
    :expires_at,
    :nonce,
    :issuer,
    :policy_version,
    :constitution_version,
    :mac
  ]

  defstruct [
    :receipt_id,
    :decision_digest,
    :decision_type,
    :scope_digest,
    :actor,
    :issued_at,
    :expires_at,
    :nonce,
    :issuer,
    :policy_version,
    :constitution_version,
    :mac
  ]

  @type t :: %__MODULE__{
          receipt_id: String.t(),
          decision_digest: String.t(),
          decision_type: atom(),
          scope_digest: String.t(),
          actor: atom() | String.t(),
          issued_at: DateTime.t(),
          expires_at: DateTime.t(),
          nonce: String.t(),
          issuer: String.t(),
          policy_version: String.t(),
          constitution_version: String.t(),
          mac: String.t()
        }

  alias Tiannara.Council.DecisionDigest

  @issuer "tiannara.council"
  @issuer_version 1
  @min_key_bytes 32

  @doc "Stable issuer identity accepted by the verifier."
  @spec issuer() :: String.t()
  def issuer, do: "#{@issuer}/v#{@issuer_version}"

  @doc "True when `issuer` is the currently accepted Council issuer identity."
  @spec accepted_issuer?(term()) :: boolean()
  def accepted_issuer?(issuer), do: issuer == issuer()

  @doc """
  Signs a receipt from the registered Council process. Any other process is
  refused, so ordinary callers cannot mint receipt authority even though they
  can construct the struct.
  """
  @spec sign(t()) :: {:ok, t()} | {:error, :receipt_unavailable | :receipt_signer_invalid}
  def sign(%__MODULE__{} = receipt) do
    if Process.whereis(Tiannara.Council) == self() do
      do_sign(receipt)
    else
      {:error, :receipt_signer_invalid}
    end
  end

  @doc false
  @spec sign_test(t()) :: {:ok, t()} | {:error, term()}
  def sign_test(%__MODULE__{} = receipt) do
    if Application.get_env(:tiannara, :allow_test_receipt_signing, false) == true do
      do_sign(receipt)
    else
      {:error, :receipt_signing_not_allowed}
    end
  end

  @doc """
  Verifies MAC structure and issuer identity. Expiry, policy version and
  emergency are checked by the mint/registry boundary because they are
  time/current-state dependent.
  """
  @spec verify(term()) ::
          :ok
          | {:error,
             :council_decision_receipt_invalid
             | :council_receipt_issuer_invalid
             | :council_receipt_unavailable}
  def verify(%__MODULE__{} = receipt) do
    cond do
      not is_binary(receipt.mac) or byte_size(receipt.mac) == 0 ->
        {:error, :council_decision_receipt_invalid}

      not accepted_issuer?(receipt.issuer) ->
        {:error, :council_receipt_issuer_invalid}

      true ->
        with {:ok, key} <- key() do
          expected = mac(key, receipt)

          if secure_compare(expected, receipt.mac) do
            :ok
          else
            {:error, :council_decision_receipt_invalid}
          end
        end
    end
  rescue
    _ -> {:error, :council_decision_receipt_invalid}
  end

  def verify(_receipt), do: {:error, :council_decision_receipt_invalid}

  @doc "Canonical digest of the receipt's authority fields (MAC excluded)."
  @spec receipt_digest(t()) :: String.t()
  def receipt_digest(%__MODULE__{} = receipt), do: DecisionDigest.receipt(receipt)

  @doc "True when the receipt's expiry has passed at the given instant."
  @spec expired?(t(), DateTime.t()) :: boolean()
  def expired?(%__MODULE__{expires_at: %DateTime{} = expires_at}, now \\ DateTime.utc_now()) do
    DateTime.compare(expires_at, now) != :gt
  end

  def expired?(_receipt, _now), do: true

  @doc "True when the receipt key is available and usable."
  @spec key_available?() :: boolean()
  def key_available?, do: match?({:ok, _}, key())

  defp do_sign(receipt) do
    with {:ok, key} <- key() do
      {:ok, %__MODULE__{receipt | mac: mac(key, receipt)}}
    end
  rescue
    _ -> {:error, :receipt_unavailable}
  end

  defp mac(key, receipt) do
    payload =
      {:tiannara_decision_receipt_mac, @issuer_version,
       DecisionDigest.receipt_identity(receipt)}

    :crypto.mac(:hmac, :sha256, key, :erlang.term_to_binary(payload, [:deterministic]))
    |> Base.encode16(case: :lower)
  end

  defp key do
    case Application.get_env(:tiannara, :council_receipt_key) do
      key when is_binary(key) and byte_size(key) >= @min_key_bytes -> {:ok, key}
      _ -> {:error, :council_receipt_unavailable}
    end
  end

  # Constant-time comparison without pulling in an external dependency.
  defp secure_compare(left, right) when is_binary(left) and is_binary(right) do
    byte_size(left) == byte_size(right) and :crypto.hash_equals(left, right)
  end

  defp secure_compare(_left, _right), do: false
end
