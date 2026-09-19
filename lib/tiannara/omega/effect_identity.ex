defmodule Tiannara.Omega.EffectIdentity do
  @moduledoc """
  Canonical semantic identity for consequential effects.

  This module is the first implementation boundary of the effect-identity
  remediation. An effect identity is derived only from the canonical semantic
  descriptor; authorization, workflow, transport, retry and runtime identities
  are deliberately excluded.

  Identity version is part of the descriptor so canonicalization semantics
  cannot silently change underneath an existing effect.
  """

  @identity_version "v1"
  @required_fields ~w(
    principal
    authority_scope
    operation
    target
    parameters
    environment
    intent
    semantic_version
    identity_version
  )

  @type descriptor :: %{String.t() => term()}
  @type effect_id :: String.t()

  @spec identity_version() :: String.t()
  def identity_version, do: @identity_version

  @spec new(map()) :: {:ok, descriptor()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    with {:ok, descriptor} <- normalize_descriptor(attrs),
         :ok <- validate_descriptor(descriptor),
         :ok <- validate_allowed_fields(descriptor) do
      {:ok, Map.take(descriptor, @required_fields)}
    end
  end

  def new(_), do: {:error, :descriptor_must_be_a_map}

  @spec canonical_descriptor(map() | descriptor()) :: {:ok, binary()} | {:error, term()}
  def canonical_descriptor(attrs) when is_map(attrs) do
    with {:ok, descriptor} <- new(attrs),
         {:ok, canonical} <- canonical_json(descriptor) do
      {:ok, canonical}
    end
  end

  @spec effect_id(map() | descriptor()) :: {:ok, effect_id()} | {:error, term()}
  def effect_id(attrs) when is_map(attrs) do
    with {:ok, canonical} <- canonical_descriptor(attrs),
         identity_version <- descriptor_identity_version(attrs),
         :ok <- validate_identity_version(identity_version) do
      digest =
        :crypto.hash(:sha256, canonical)
        |> Base.encode16(case: :lower)

      {:ok, "effect-#{identity_version}-#{digest}"}
    end
  end

  @spec verify(map() | descriptor(), effect_id()) ::
          :ok | {:error, :effect_id_mismatch | :invalid_effect_id | term()}
  def verify(attrs, claimed_effect_id) when is_map(attrs) and is_binary(claimed_effect_id) do
    with {:ok, expected} <- effect_id(attrs) do
      if expected == claimed_effect_id, do: :ok, else: {:error, :effect_id_mismatch}
    end
  end

  def verify(_, _), do: {:error, :invalid_effect_id}

  defp normalize_descriptor(attrs) do
    Enum.reduce_while(attrs, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
      with {:ok, key} <- normalize_key(key),
           {:ok, value} <- normalize_value(value) do
        if Map.has_key?(acc, key) do
          {:halt, {:error, {:duplicate_key, key}}}
        else
          {:cont, {:ok, Map.put(acc, key, value)}}
        end
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp normalize_key(key) when is_binary(key), do: {:ok, key}
  defp normalize_key(key) when is_atom(key), do: {:ok, Atom.to_string(key)}
  defp normalize_key(key), do: {:error, {:invalid_key, key}}

  defp normalize_value(value) when is_map(value) do
    normalize_descriptor(value)
  end

  defp normalize_value(value) when is_list(value) do
    value
    |> Enum.reduce_while({:ok, []}, fn item, {:ok, acc} ->
      case normalize_value(item) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      error -> error
    end
  end

  defp normalize_value(value) when is_binary(value), do: {:ok, value}
  defp normalize_value(value) when is_integer(value), do: {:ok, value}
  defp normalize_value(value) when is_float(value), do: {:ok, value}
  defp normalize_value(value) when is_boolean(value), do: {:ok, value}
  defp normalize_value(nil), do: {:ok, nil}
  defp normalize_value(value), do: {:error, {:unsupported_value, value}}

  defp validate_descriptor(descriptor) do
    missing =
      @required_fields
      |> Enum.reject(&Map.has_key?(descriptor, &1))

    if missing == [] do
      validate_versions(descriptor)
    else
      {:error, {:missing_fields, missing}}
    end
  end

  defp validate_allowed_fields(descriptor) do
    unknown =
      descriptor
      |> Map.keys()
      |> Enum.reject(&(&1 in @required_fields))

    if unknown == [], do: :ok, else: {:error, {:unknown_fields, unknown}}
  end

  defp validate_versions(descriptor) do
    with :ok <- validate_non_empty_binary(descriptor["semantic_version"], :semantic_version),
         :ok <- validate_identity_version(descriptor["identity_version"]) do
      :ok
    end
  end

  defp validate_identity_version(version) when is_binary(version) and byte_size(version) > 0,
    do: :ok

  defp validate_identity_version(version), do: {:error, {:invalid_identity_version, version}}

  defp validate_non_empty_binary(value, _field) when is_binary(value) and byte_size(value) > 0,
    do: :ok

  defp validate_non_empty_binary(value, field), do: {:error, {:invalid_field, field, value}}

  defp descriptor_identity_version(attrs) do
    Map.get(attrs, "identity_version", Map.get(attrs, :identity_version, @identity_version))
  end

  defp canonical_json(descriptor) do
    try do
      {:ok, descriptor |> canonical_term() |> encode_json() |> IO.iodata_to_binary()}
    rescue
      error in ArgumentError -> {:error, {:canonicalization_error, Exception.message(error)}}
    end
  end

  defp canonical_term(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {key, canonical_term(value)} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> then(&{:object, &1})
  end

  defp canonical_term(list) when is_list(list),
    do: {:array, Enum.map(list, &canonical_term/1)}

  defp canonical_term(value), do: value

  defp encode_json({:object, pairs}) do
    [
      ?{,
      Enum.map_intersperse(pairs, ?,, fn {key, value} ->
        [:json.encode(key), ?:, encode_json(value)]
      end),
      ?}
    ]
  end

  defp encode_json({:array, values}) do
    [?[, Enum.map_intersperse(values, ?,, &encode_json/1), ?]]
  end

  defp encode_json(value) when is_binary(value), do: :json.encode(value)
  defp encode_json(value) when is_integer(value), do: Integer.to_string(value)

  defp encode_json(value) when is_float(value) do
    :erlang.float_to_binary(value, [:short])
  end

  defp encode_json(true), do: "true"
  defp encode_json(false), do: "false"
  defp encode_json(nil), do: "null"
end
