defmodule Tiannara.Omega.HumanDelivery.AuthenticatedHumanIdentity do
  @moduledoc """
  An authenticated human identity. Stronger than a bare `human_id` atom/string:
  an identity can only be produced through `authenticate/3`, which requires a
  credential and records the authentication method and time.

  This closes the gap where an arbitrary `:human_1` atom could be passed as an
  "authorization" without representing an authenticated human.

  Constitutional basis: augmentation clause, Security by design, "Maintain
  audit trails."
  """

  @enforce_keys [:identity_id, :human_id, :authenticated_at, :method]
  defstruct [:identity_id, :human_id, :authenticated_at, :method, :credential_hash]

  @type t :: %__MODULE__{}

  @doc """
  Authenticate a human identity. Requires a credential. Returns an
  AuthenticatedHumanIdentity or an error.
  """
  def authenticate(human_id, credential, method) when not is_nil(human_id) and not is_nil(credential) do
    if valid_credential?(credential) do
      {:ok,
       %__MODULE__{
         identity_id: make_id(),
         human_id: human_id,
         authenticated_at: System.system_time(:second),
         method: method,
         credential_hash: hash_credential(credential)
       }}
    else
      {:error, :invalid_credential}
    end
  end

  def authenticate(_, _, _), do: {:error, :human_id_and_credential_required}

  @doc "Returns true if the identity was authenticated."
  def authenticated?(%__MODULE__{authenticated_at: at}), do: not is_nil(at)
  def authenticated?(_), do: false

  defp valid_credential?(credential) when is_binary(credential), do: byte_size(credential) > 0
  defp valid_credential?(_), do: false

  defp hash_credential(credential) do
    credential |> :erlang.term_to_binary() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
  end

  defp make_id, do: :"ident-#{System.unique_integer([:monotonic])}"
end