defmodule Tiannara.Discovery.ConstitutionalValidation do
  @moduledoc """
  Deterministic, runtime-independent primitives used to validate Phase 15 artifacts.

  The module intentionally operates on plain maps and immutable lists so the same
  exported inputs can be checked by an independent executable.
  """

  @entity_types ~w(observation hypothesis experiment evidence theory discovery capital_delta)a
  @statistics ~w(sample_size variance effect_size confidence_interval power significance uncertainty)a

  @spec canonical_binary(term()) :: binary()
  def canonical_binary(term), do: :erlang.term_to_binary(term, [:deterministic])

  @spec fingerprint(term()) :: String.t()
  def fingerprint(term) do
    term
    |> canonical_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  @spec build_entity(atom(), map()) :: {:ok, map()} | {:error, term()}
  def build_entity(type, attributes) when type in @entity_types and is_map(attributes) do
    payload = %{schema_version: "15.0.0", type: type, attributes: attributes}
    entity = Map.put(payload, :id, fingerprint(payload))

    case validate_entity(entity) do
      :ok -> {:ok, entity}
      error -> error
    end
  end

  def build_entity(type, _attributes), do: {:error, {:unsupported_entity_type, type}}

  @spec validate_entity(map()) :: :ok | {:error, term()}
  def validate_entity(%{id: id, type: type, schema_version: "15.0.0", attributes: attrs} = entity)
      when type in @entity_types and is_map(attrs) do
    expected = entity |> Map.delete(:id) |> fingerprint()
    if secure_equal?(id, expected), do: :ok, else: {:error, :content_id_mismatch}
  end

  def validate_entity(_), do: {:error, :invalid_entity}

  @spec append([map()], map(), String.t()) :: {:ok, [map()]} | {:error, term()}
  def append(ledger, entity, owner) when is_list(ledger) and is_binary(owner) and owner != "" do
    with :ok <- validate_ledger(ledger),
         :ok <- validate_entity(entity) do
      sequence = length(ledger)

      previous_hash =
        if sequence == 0, do: String.duplicate("0", 64), else: List.last(ledger).entry_hash

      entry_payload = %{
        sequence: sequence,
        previous_hash: previous_hash,
        owner: owner,
        entity: entity
      }

      {:ok, ledger ++ [Map.put(entry_payload, :entry_hash, fingerprint(entry_payload))]}
    end
  end

  def append(_ledger, _entity, _owner), do: {:error, :invalid_append}

  @spec validate_ledger([map()]) :: :ok | {:error, term()}
  def validate_ledger(ledger) when is_list(ledger) do
    ledger
    |> Enum.with_index()
    |> Enum.reduce_while(String.duplicate("0", 64), fn {entry, index}, previous_hash ->
      case validate_entry(entry, index, previous_hash) do
        :ok -> {:cont, entry.entry_hash}
        error -> {:halt, error}
      end
    end)
    |> case do
      hash when is_binary(hash) -> :ok
      error -> error
    end
  end

  def validate_ledger(_), do: {:error, :invalid_ledger}

  @spec replay([map()]) :: {:ok, map()} | {:error, term()}
  def replay(ledger) do
    with :ok <- validate_ledger(ledger) do
      state =
        Enum.reduce(ledger, %{entities: %{}, owners: %{}, capital: %{}}, fn entry, acc ->
          entity = entry.entity

          acc
          |> put_in([:entities, entity.id], entity)
          |> put_in([:owners, entity.id], entry.owner)
          |> apply_capital(entity)
        end)

      {:ok, Map.put(state, :state_root, fingerprint(state))}
    end
  end

  @spec graph_hash([map()], [map()]) :: String.t()
  def graph_hash(nodes, edges) do
    fingerprint(%{
      nodes: Enum.sort_by(nodes, &map_sort_key/1),
      edges: Enum.sort_by(edges, &map_sort_key/1)
    })
  end

  @spec validate_statistical_claim(map()) :: :ok | {:error, {:missing_statistics, [atom()]}}
  def validate_statistical_claim(claim) when is_map(claim) do
    missing = Enum.reject(@statistics, &Map.has_key?(claim, &1))
    if missing == [], do: :ok, else: {:error, {:missing_statistics, missing}}
  end

  @spec sign_certificate(map(), binary()) :: map()
  def sign_certificate(certificate, key) when is_map(certificate) and is_binary(key) do
    unsigned = Map.drop(certificate, [:signature, "signature"])

    signature =
      :crypto.mac(:hmac, :sha256, key, canonical_binary(unsigned)) |> Base.encode16(case: :lower)

    Map.put(unsigned, :signature, signature)
  end

  @spec verify_certificate(map(), binary()) :: :ok | {:error, :invalid_signature}
  def verify_certificate(%{signature: signature} = certificate, key) when is_binary(key) do
    expected = sign_certificate(Map.delete(certificate, :signature), key).signature
    if secure_equal?(signature, expected), do: :ok, else: {:error, :invalid_signature}
  end

  def verify_certificate(_, _), do: {:error, :invalid_signature}

  defp validate_entry(entry, index, previous_hash) do
    with true <- entry.sequence == index || {:error, :sequence_mismatch},
         true <- entry.previous_hash == previous_hash || {:error, :hash_chain_mismatch},
         :ok <- validate_entity(entry.entity),
         expected <- entry |> Map.delete(:entry_hash) |> fingerprint(),
         true <- secure_equal?(entry.entry_hash, expected) || {:error, :entry_hash_mismatch} do
      :ok
    end
  end

  defp apply_capital(state, %{
         type: :capital_delta,
         attributes: %{account: account, amount: amount}
       })
       when is_number(amount) do
    update_in(state, [:capital, account], &((&1 || 0) + amount))
  end

  defp apply_capital(state, _entity), do: state

  defp map_sort_key(map), do: Map.get(map, :id) || Map.get(map, "id") || fingerprint(map)

  defp secure_equal?(left, right)
       when is_binary(left) and is_binary(right) and byte_size(left) == byte_size(right),
       do: :crypto.hash_equals(left, right)

  defp secure_equal?(_, _), do: false
end
