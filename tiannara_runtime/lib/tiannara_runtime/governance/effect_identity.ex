defmodule TiannaraRuntime.Governance.EffectIdentity do
  @moduledoc """
  UAG-2F — Universal semantic EffectID v1.

  This module is deliberately narrower than the existing shared canonicalizer:
  lifecycle/correlation identifiers are excluded, semantic fields are validated,
  unsupported BEAM terms are rejected, and the digest uses an explicit domain
  separation prefix.

  This module does not authorize or execute an effect. It only constructs and
  verifies semantic identity.
  """

  @version "effect-v1"
  @domain "tiannara-effect-v1"
  @required ~w(effect_schema_version principal authority authorization_scope operation target parameters intent environment_scope authority_epoch policy_version)a

  @doc "Returns the frozen semantic schema version."
  def version, do: @version

  @doc "Normalizes and validates an EffectDescriptorV1."
  def normalize(descriptor) when is_map(descriptor) do
    with :ok <- required_fields(descriptor),
         :ok <- schema_version(descriptor),
         {:ok, principal} <- stable_text(fetch(descriptor, :principal), :principal),
         {:ok, authority} <- normalize_object(fetch(descriptor, :authority), :authority),
         {:ok, auth_scope} <- normalize_object(fetch(descriptor, :authorization_scope), :authorization_scope),
         {:ok, operation} <- operation(fetch(descriptor, :operation)),
         {:ok, target} <- normalize_target(fetch(descriptor, :target)),
         {:ok, parameters} <- normalize_value(fetch(descriptor, :parameters), :parameters),
         {:ok, intent} <- stable_text(fetch(descriptor, :intent), :intent),
         {:ok, environment} <- normalize_object(fetch(descriptor, :environment_scope), :environment_scope),
         {:ok, epoch} <- stable_text(fetch(descriptor, :authority_epoch), :authority_epoch),
         {:ok, policy} <- stable_text(fetch(descriptor, :policy_version), :policy_version) do
      {:ok, %{
        "effect_schema_version" => @version,
        "principal" => principal,
        "authority" => authority,
        "authorization_scope" => auth_scope,
        "operation" => operation,
        "target" => target,
        "parameters" => parameters,
        "intent" => intent,
        "environment_scope" => environment,
        "authority_epoch" => epoch,
        "policy_version" => policy
      }}
    end
  end

  def normalize(_), do: {:error, :descriptor_must_be_map}

  @doc "Returns canonical UTF-8 JSON bytes for a valid descriptor."
  def canonical_bytes(descriptor) do
    with {:ok, normalized} <- normalize(descriptor) do
      try do
        {:ok, Jason.encode!(normalized)}
      rescue
        error in [Protocol.UndefinedError, ArgumentError] ->
          {:error, {:serialization_error, Exception.message(error)}}
      end
    end
  end

  @doc "Computes the lowercase SHA-256 EffectID."
  def effect_id(descriptor) do
    with {:ok, bytes} <- canonical_bytes(descriptor) do
      {:ok, :crypto.hash(:sha256, @domain <> <<0>> <> bytes) |> Base.encode16(case: :lower)}
    end
  end

  @doc "Verifies that an EffectID belongs to a descriptor."
  def verify(descriptor, expected_id) when is_binary(expected_id) do
    case effect_id(descriptor) do
      {:ok, ^expected_id} -> :ok
      {:ok, actual} -> {:error, {:effect_id_mismatch, actual}}
      error -> error
    end
  end

  defp required_fields(descriptor) do
    missing = Enum.reject(@required, fn key ->
      Map.has_key?(descriptor, key) or Map.has_key?(descriptor, Atom.to_string(key))
    end)
    if missing == [], do: :ok, else: {:error, {:missing_fields, missing}}
  end

  defp fetch(descriptor, key), do: Map.get(descriptor, key, Map.get(descriptor, Atom.to_string(key)))

  defp schema_version(descriptor) do
    case fetch(descriptor, :effect_schema_version) do
      @version -> :ok
      other -> {:error, {:unsupported_schema_version, other}}
    end
  end

  defp stable_text(value, field) when is_binary(value) do
    if String.valid?(value), do: {:ok, value}, else: {:error, {:invalid_utf8, field}}
  end
  defp stable_text(_, field), do: {:error, {:invalid_text, field}}

  defp operation(value) do
    with {:ok, value} <- stable_text(value, :operation) do
      if String.trim(value) == value and value != "", do: {:ok, value}, else: {:error, :invalid_operation}
    end
  end

  defp normalize_target(value) when is_map(value) do
    required = ~w(namespace resource_type resource_id subresource)
    if Enum.all?(required, fn k -> Map.has_key?(value, k) or Map.has_key?(value, String.to_atom(k)) end) do
      normalize_object(value, :target)
    else
      {:error, {:missing_target_fields, required}}
    end
  end
  defp normalize_target(_), do: {:error, :target_must_be_object}

  defp normalize_object(value, field) when is_map(value) do
    Enum.reduce_while(value, {:ok, %{}}, fn {key, item}, {:ok, acc} ->
      with {:ok, key} <- object_key(key),
           {:ok, item} <- normalize_value(item, {field, key}) do
        {:cont, {:ok, Map.put(acc, key, item)}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
  defp normalize_object(_, field), do: {:error, {:object_required, field}}

  defp object_key(key) when is_binary(key) do
    if String.valid?(key), do: {:ok, key}, else: {:error, :invalid_utf8_key}
  end
  defp object_key(key) when is_atom(key) and key != nil, do: {:ok, Atom.to_string(key)}
  defp object_key(_), do: {:error, :invalid_object_key}

  defp normalize_value(nil, _), do: {:ok, nil}
  defp normalize_value(value, _) when is_boolean(value), do: {:ok, value}
  defp normalize_value(value, _) when is_integer(value), do: {:ok, value}
  defp normalize_value(value, field) when is_float(value) do
    cond do
      value != value -> {:error, {:non_finite_number, field}}
      value == 0.0 -> {:ok, 0.0}
      true -> {:ok, value}
    end
  end
  defp normalize_value(value, field) when is_binary(value) do
    if String.valid?(value), do: {:ok, value}, else: {:error, {:invalid_utf8, field}}
  end
  defp normalize_value(value, field) when is_map(value), do: normalize_object(value, field)
  defp normalize_value(value, field) when is_list(value) do
    Enum.reduce_while(value, {:ok, []}, fn item, {:ok, acc} ->
      case normalize_value(item, field) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, values} -> {:ok, Enum.reverse(values)}
      error -> error
    end
  end
  defp normalize_value(_, field), do: {:error, {:unsupported_value, field}}
end
