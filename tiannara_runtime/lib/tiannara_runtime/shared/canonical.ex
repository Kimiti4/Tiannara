defmodule TiannaraRuntime.Shared.Canonical do
  @moduledoc """
  Phase 17.8.1 — Canonical serialization and content-addressed ID utilities.

  Single source of truth for:
  - deep struct-to-map conversion (stable key ordering)
  - canonical JSON encoding
  - content-addressed ID generation (SHA-256 over canonical JSON)

  Constitutional rules enforced here:
  - Stable key ordering: map keys are sorted lexicographically before encoding
  - No NaN, no Infinity (Jason raises on these by default)
  - Null fields are serialized as null; absent fields remain absent
  - Arrays are encoded in the order provided (callers are responsible for stable ordering)

  No hardcoded values. No mock data. No fallback logic.
  """

  @doc """
  Converts any struct or nested map/list to a plain map with sorted keys,
  suitable for canonical JSON encoding.

  Structs are converted via Map.from_struct/1 then recursed.
  Atom keys are converted to strings for canonical ordering.
  """
  @spec to_canonical_map(term()) :: term()
  def to_canonical_map(value) when is_struct(value) do
    value
    |> Map.from_struct()
    |> to_canonical_map()
  end

  def to_canonical_map(value) when is_map(value) do
    value
    |> Enum.map(fn {k, v} -> {to_string(k), to_canonical_map(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Map.new()
  end

  def to_canonical_map(value) when is_list(value) do
    Enum.map(value, &to_canonical_map/1)
  end

  def to_canonical_map(value) when is_tuple(value) do
    value |> Tuple.to_list() |> to_canonical_map()
  end

  def to_canonical_map(value) when is_atom(value) and value != nil do
    Atom.to_string(value)
  end

  def to_canonical_map(value), do: value

  @doc """
  Encodes a canonical map to JSON. Raises if the value contains non-encodable
  terms (NaN, Infinity, pids, references). This is intentional — non-encodable
  values are a schema violation, not a recoverable error.
  """
  @spec encode!(term()) :: String.t()
  def encode!(canonical_map) do
    Jason.encode!(canonical_map)
  end

  @doc """
  Computes a content-addressed ID from a struct or map, excluding the ID field itself.

  The ID field name is passed as an atom so each schema can declare which field
  is the canonical ID. The prefix is prepended to the hex digest.

  Returns a string of the form "<prefix>_<sha256hex>".

  Constitutional guarantee: identical input → identical output, always.
  """
  @spec generate_id(map() | struct(), id_field :: atom(), prefix :: String.t()) :: String.t()
  def generate_id(value, id_field, prefix) when is_struct(value) do
    value
    |> Map.from_struct()
    |> Map.delete(id_field)
    |> to_canonical_map()
    |> encode!()
    |> sha256_hex()
    |> then(fn hex -> prefix <> "_" <> hex end)
  end

  def generate_id(value, id_field, prefix) when is_map(value) do
    value
    |> Map.delete(id_field)
    |> Map.delete(Atom.to_string(id_field))
    |> to_canonical_map()
    |> encode!()
    |> sha256_hex()
    |> then(fn hex -> prefix <> "_" <> hex end)
  end

  @doc """
  Validates that a content-addressed ID on a struct matches what would be computed
  from its current field values. Returns :ok or {:error, reason}.
  """
  @spec verify_id(struct(), id_field :: atom(), prefix :: String.t()) ::
          :ok | {:error, String.t()}
  def verify_id(value, id_field, prefix) when is_struct(value) do
    recorded = Map.get(value, id_field)
    expected = generate_id(value, id_field, prefix)

    if recorded == expected do
      :ok
    else
      {:error,
       "content-addressed ID mismatch on #{inspect(value.__struct__)}: " <>
         "recorded=#{inspect(recorded)}, expected=#{inspect(expected)}"}
    end
  end

  # Private

  defp sha256_hex(data) when is_binary(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end
end
