defmodule TiannaraRuntime.Governance.EffectIdentity do
  @moduledoc """
  UAG-2F — Universal semantic EffectID v1.

  Cross-runtime canonical identity only. This module does not authorize,
  bind, admit, deploy, mutate, or execute an effect.
  """

  @version "effect-v1"
  @domain "tiannara-effect-v1"
  @required ~w(effect_schema_version principal authority authorization_scope operation target parameters intent environment_scope authority_epoch policy_version)a

  def version, do: @version

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

  def canonical_bytes(descriptor) do
    with {:ok, normalized} <- normalize(descriptor) do
      {:ok, canonical_json(normalized)}
    end
  end

  def effect_id(descriptor) do
    with {:ok, bytes} <- canonical_bytes(descriptor) do
      {:ok, :crypto.hash(:sha256, @domain <> <<0>> <> bytes) |> Base.encode16(case: :lower)}
    end
  end

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
    if Enum.all?(required, &has_field?(value, &1)) do
      normalize_object(value, :target)
    else
      {:error, {:missing_target_fields, required}}
    end
  end
  defp normalize_target(_), do: {:error, :target_must_be_object}

  defp normalize_object(value, field) when is_map(value) do
    with :ok <- reserved_keys_ok(value, field) do
      Enum.reduce_while(value, {:ok, %{}}, fn {key, item}, {:ok, acc} ->
        with {:ok, key} <- object_key(key),
             {:ok, item} <- normalize_value(item, {field, key}) do
          {:cont, {:ok, Map.put(acc, key, item)}}
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end
  defp normalize_object(_, field), do: {:error, {:object_required, field}}

  # $-prefixed object keys are reserved for the declared semantic wrappers
  # ($number, $collection), which are consumed by their own normalize_value
  # clauses before ever reaching normalize_object. Any map that arrives here
  # carrying a $-key therefore has an unsupported shape/value and must
  # hard-fail, mirroring the independent renderers.
  defp reserved_keys_ok(map, field) do
    if Enum.any?(Map.keys(map), &is_binary(&1) and String.starts_with?(&1, "$")) do
      {:error, {:unsupported_special_key, field}}
    else
      :ok
    end
  end

  defp object_key(key) when is_binary(key) do
    if String.valid?(key), do: {:ok, key}, else: {:error, :invalid_utf8_key}
  end
  defp object_key(key) when is_atom(key), do: object_key(Atom.to_string(key))
  defp object_key(_), do: {:error, :invalid_object_key}

  defp has_field?(map, key) do
    Map.has_key?(map, key) or Enum.any?(Map.keys(map), fn k -> is_atom(k) and Atom.to_string(k) == key end)
  end

  # Cross-runtime semantic wrappers:
  # {"$number":"int:..."} / {"$number":"decimal:..."} preserve numeric type
  # across runtimes whose native numeric model collapses integer/float forms.
  # {"$collection":"set","items":[...]} and "multiset" provide explicit
  # collection semantics without relying on runtime-specific container types.
  defp normalize_value(%{"$number" => token} = wrapper, field)
       when is_binary(token) and map_size(wrapper) == 1 do
    case token do
      "int:" <> digits when digits != "" ->
        if Regex.match?(~r/^-?(0|[1-9][0-9]*)$/, digits), do: {:ok, %{"$number" => token}}, else: {:error, {:invalid_numeric_token, field}}
      "decimal:" <> digits when digits != "" ->
        if Regex.match?(~r/^-?(0|[1-9][0-9]*)\.[0-9]+$/, digits), do: {:ok, %{"$number" => token}}, else: {:error, {:invalid_numeric_token, field}}
      _ -> {:error, {:invalid_numeric_token, field}}
    end
  end

  defp normalize_value(%{"$collection" => kind, "items" => items} = wrapper, field)
       when kind in ["set", "multiset"] and is_list(items) and map_size(wrapper) == 2 do
    with {:ok, normalized} <- normalize_list(items, field) do
      canonical_items = Enum.map(normalized, &canonical_json/1) |> Enum.sort()
      items = if kind == "set", do: Enum.uniq(canonical_items), else: canonical_items
      {:ok, %{"$collection" => kind, "items" => Enum.map(items, &Jason.decode!/1)}}
    end
  end

  defp normalize_value(nil, _), do: {:ok, nil}
  defp normalize_value(value, _) when is_boolean(value), do: {:ok, value}
  defp normalize_value(value, _) when is_integer(value), do: {:ok, value}
  defp normalize_value(value, field) when is_float(value), do: {:error, {:native_float_forbidden, field}}
  defp normalize_value(value, field) when is_binary(value) do
    if String.valid?(value), do: {:ok, value}, else: {:error, {:invalid_utf8, field}}
  end
  defp normalize_value(value, field) when is_map(value), do: normalize_object(value, field)
  defp normalize_value(value, field) when is_list(value), do: normalize_list(value, field)
  defp normalize_value(_, field), do: {:error, {:unsupported_value, field}}

  defp normalize_list(value, field) do
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

  defp canonical_json(value) when is_map(value) do
    entries =
      value
      |> Enum.sort_by(fn {key, _} -> key end)
      |> Enum.map(fn {key, item} -> [Jason.encode!(key), ":", canonical_json(item)] end)

    ["{", Enum.intersperse(entries, ","), "}"] |> IO.iodata_to_binary()
  end
  defp canonical_json(value) when is_list(value) do
    ["[", Enum.intersperse(Enum.map(value, &canonical_json/1), ","), "]"] |> IO.iodata_to_binary()
  end
  defp canonical_json(value) when is_binary(value), do: Jason.encode!(value)
  defp canonical_json(value) when is_boolean(value), do: if(value, do: "true", else: "false")
  defp canonical_json(nil), do: "null"
  defp canonical_json(value) when is_integer(value), do: Integer.to_string(value)
end
