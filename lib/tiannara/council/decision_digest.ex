defmodule Tiannara.Council.DecisionDigest do
  @moduledoc """
  Canonical, versioned digest encoder for Council authority records (RL-565).

  Every authority-bearing digest in the Council receipt / machine-grant path is
  produced here. `:erlang.term_to_binary/1` over a caller-supplied struct is not
  sufficient (map ordering and struct layout are not a canonical authority
  encoding), so terms are first normalized:

    * structs become `{:struct, module_name, sorted_fields}`
    * maps become `{:map, sorted_key_value_pairs}`
    * tuples become `{:tuple, [canonical elements]}`
    * lists are canonicalized element-wise
    * atoms, binaries, numbers, booleans and nil are retained

  PIDs, ports, references and functions are not authority-representable and
  raise `ArgumentError`; callers must fail closed instead of hashing an
  unstable term. The encoder version is included in every digest so a future
  encoding change cannot silently reinterpret an old authority record.

  The same encoder produces the receipt MAC payload and the registry record
  payload. It is deliberately public: it is a canonicalization primitive, not a
  signing key and not an issuer.
  """

  @encoder_version 1

  @type scope :: %{
          required(:operation) => atom() | String.t(),
          required(:target) => map(),
          optional(:effect_id) => String.t() | nil
        }

  @doc "Encoder version pinned into every digest and receipt MAC payload."
  def encoder_version, do: @encoder_version

  @doc """
  Canonical SHA-256 digest, hex encoded, over `{encoder_version, domain, term}`.
  """
  @spec digest(atom(), term()) :: String.t()
  def digest(domain, term) when is_atom(domain) do
    payload = {:tiannara_digest, @encoder_version, domain, canonical(term)}

    :crypto.hash(:sha256, :erlang.term_to_binary(payload, [:deterministic]))
    |> Base.encode16(case: :lower)
  end

  @doc "Digest of the exact Council decision payload."
  @spec decision(term()) :: String.t()
  def decision(decision), do: digest(:council_decision, decision)

  @doc """
  Digest of an operation scope. The scope must be exact; a bare operation name
  is never a valid machine-authorizing scope.
  """
  @spec scope_digest(scope()) :: String.t()
  def scope_digest(scope) when is_map(scope) do
    digest(:council_scope, normalize_scope!(scope))
  end

  @doc """
  Normalizes a scope for comparison and canonical hashing.

  `operation` is rendered as a string because effect descriptors use string
  operation names. `target` is retained exactly: the decision scope and the
  effect descriptor must describe the same target, not two values that merely
  look similar after a lossy conversion. `effect_id`, when present, is carried
  through and pinned.
  """
  @spec normalize_scope!(scope()) :: map()
  def normalize_scope!(%{operation: operation, target: target} = scope)
      when (is_atom(operation) and not is_nil(operation)) or is_binary(operation) do
    unless is_map(target) and map_size(target) > 0 do
      raise ArgumentError, "scope target must be a non-empty map"
    end

    %{
      operation: to_string(operation),
      target: target,
      effect_id: Map.get(scope, :effect_id)
    }
  end

  def normalize_scope!(_scope), do: raise(ArgumentError, "invalid scope")

  @doc "True when `scope` can safely authorize a machine effect."
  @spec valid_scope?(term()) :: boolean()
  def valid_scope?(scope) do
    _ = normalize_scope!(scope)
    true
  rescue
    ArgumentError -> false
  end

  @doc "True when two scopes describe the same operation, target and effect."
  @spec same_scope?(scope(), scope()) :: boolean()
  def same_scope?(left, right) do
    normalize_scope!(left) == normalize_scope!(right)
  rescue
    ArgumentError -> false
  end

  @doc "Canonical identity for a machine grant (see `MachineAuthorization`)."
  @spec machine_grant(map()) :: String.t()
  def machine_grant(grant) when is_map(grant) do
    digest(:machine_grant, grant_identity(grant))
  end

  @doc """
  Digest of a receipt's authority fields (the MAC payload and the registry
  anchor). The `:mac` field is deliberately excluded.
  """
  @spec receipt(map()) :: String.t()
  def receipt(receipt) when is_map(receipt) do
    digest(:council_decision_receipt, receipt_identity(receipt))
  end

  @doc "Fields covered by the receipt MAC and receipt digest."
  @spec receipt_identity(map()) :: map()
  def receipt_identity(receipt) when is_map(receipt) do
    %{
      receipt_id: Map.fetch!(receipt, :receipt_id),
      decision_digest: Map.fetch!(receipt, :decision_digest),
      decision_type: Map.fetch!(receipt, :decision_type),
      scope_digest: Map.fetch!(receipt, :scope_digest),
      actor: Map.fetch!(receipt, :actor),
      issued_at: Map.fetch!(receipt, :issued_at),
      expires_at: Map.fetch!(receipt, :expires_at),
      nonce: Map.fetch!(receipt, :nonce),
      issuer: Map.fetch!(receipt, :issuer),
      policy_version: Map.fetch!(receipt, :policy_version),
      constitution_version: Map.fetch!(receipt, :constitution_version),
      encoder_version: @encoder_version
    }
  end

  @doc "Fields covered by the machine-grant digest."
  @spec grant_identity(map()) :: map()
  def grant_identity(grant) when is_map(grant) do
    %{
      authorization_id: Map.fetch!(grant, :authorization_id),
      authority_class: Map.get(grant, :authority_class, :machine),
      receipt_id: Map.fetch!(grant, :receipt_id),
      decision_digest: Map.fetch!(grant, :council_decision_ref),
      decision_type: Map.fetch!(grant, :decision_type),
      scope_digest: Map.fetch!(grant, :scope_digest),
      effect_id: Map.get(grant, :effect_id),
      granted_at_unix: unix!(Map.fetch!(grant, :granted_at)),
      ttl: Map.fetch!(grant, :ttl),
      encoder_version: @encoder_version
    }
  end

  # ------------------------------------------------------------- canonical --

  @doc "Canonical representation used by every digest."
  @spec canonical(term()) :: term()
  def canonical(term) when is_map(term) do
    if Map.has_key?(term, :__struct__) do
      module = Map.fetch!(term, :__struct__)

      fields =
        term
        |> Map.delete(:__struct__)
        |> map_pairs()

      {:struct, Atom.to_string(module), fields}
    else
      {:map, map_pairs(term)}
    end
  end

  def canonical(term) when is_list(term), do: Enum.map(term, &canonical/1)

  def canonical(term) when is_tuple(term) do
    {:tuple, term |> Tuple.to_list() |> Enum.map(&canonical/1)}
  end

  def canonical(term)
      when is_atom(term) or is_binary(term) or is_number(term) do
    term
  end

  def canonical(term) do
    raise ArgumentError, "unsupported canonical term: #{inspect(term)}"
  end

  defp map_pairs(map) do
    map
    |> Enum.map(fn {key, value} -> {canonical(key), canonical(value)} end)
    |> Enum.sort_by(fn {key, _value} ->
      :erlang.term_to_binary(key, [:deterministic])
    end)
  end

  defp unix!(%DateTime{} = value), do: DateTime.to_unix(value, :microsecond)
  defp unix!(value) when is_integer(value), do: value
  defp unix!(value), do: raise(ArgumentError, "invalid timestamp: #{inspect(value)}")
end
