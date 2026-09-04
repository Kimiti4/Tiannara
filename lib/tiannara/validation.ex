defmodule Tiannara.Validation do
  @moduledoc """
  Type-safe validation layer for Tiannara certification exercises.

  "Capability must never outpace verification" — typed interfaces verify before access.

  Provides declarative schema-based validation that eliminates
  ad-hoc pattern matching and prevents nil dereferences.

  All validation functions return {:ok, validated} | {:error, reasons}.
  """

  @type validation_result :: {:ok, map()} | {:error, [{atom(), atom()}]}
  @type schema :: keyword()

  @doc """
  Validates a consent record before boolean operations.
  Ensures all required fields are present and consent is boolean.
  """
  @spec consent_record(any()) :: {:ok, map()} | {:error, atom()}
  def consent_record(record) when is_map(record) do
    required = [:f, :ret, :sens, :consent]
    missing = Enum.filter(required, fn k -> not Map.has_key?(record, k) end)

    cond do
      missing != [] -> {:error, {:missing_fields, missing}}
      not is_boolean(record.consent) -> {:error, :consent_not_boolean}
      true -> {:ok, record}
    end
  end

  def consent_record(_), do: {:error, :not_a_map}

  @doc """
  Safe boolean conjunction — never raises "expected boolean".
  """
  @spec and_bool(any(), any()) :: {:ok, boolean()} | {:error, atom()}
  def and_bool(a, b) when is_boolean(a) and is_boolean(b), do: {:ok, a and b}
  def and_bool(a, _) when not is_boolean(a), do: {:error, {:left_not_boolean, a}}
  def and_bool(_, b) when not is_boolean(b), do: {:error, {:right_not_boolean, b}}

  @doc """
  Safe boolean disjunction — never raises "expected boolean".
  """
  @spec or_bool(any(), any()) :: {:ok, boolean()} | {:error, atom()}
  def or_bool(a, b) when is_boolean(a) and is_boolean(b), do: {:ok, a or b}
  def or_bool(a, _) when not is_boolean(a), do: {:error, {:left_not_boolean, a}}
  def or_bool(_, b) when not is_boolean(b), do: {:error, {:right_not_boolean, b}}

  @doc """
  Safe map access — never raises "key not found".
  """
  @spec safe_fetch(map(), atom()) :: {:ok, any()} | {:error, {:key_not_found, atom()}}
  def safe_fetch(map, key) when is_map(map) and is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:key_not_found, key}}
    end
  end

  def safe_fetch(_, key), do: {:error, {:key_not_found, key}}

  @doc """
  Safe map access with default — returns default if key not found.
  """
  @spec safe_fetch_with(map(), atom(), any()) :: {:ok, any()}
  def safe_fetch_with(map, key, default) when is_map(map) and is_atom(key) do
    {:ok, Map.get(map, key, default)}
  end

  @doc """
  Validates a utility record — fixes Exercise 2.6 "key :u not found".
  """
  @spec utility_record(any()) :: {:ok, map()} | {:error, atom()}
  def utility_record(%{u: u} = record) when is_number(u), do: {:ok, record}
  def utility_record(%{u: _}), do: {:error, :u_not_numeric}
  def utility_record(nil), do: {:error, :nil_utility}
  def utility_record(record) when is_map(record), do: {:error, :missing_u_field}
  def utility_record(_), do: {:error, :not_a_map}

  @doc """
  Generic schema-based validation.

  Schema format:
    [
      field_name: [{:required, true}, {:type, :number}, {:min, 0}],
      another_field: [{:type, :string}]
    ]

  Returns {:ok, validated_data} | {:error, [{field, reason}]}
  """
  @spec validate(map(), schema()) :: validation_result()
  def validate(data, schema) when is_map(data) and is_list(schema) do
    errors =
      Enum.reduce(schema, [], fn {field, rules}, acc ->
        value = Map.get(data, field)
        field_errors = validate_field(field, value, rules)
        acc ++ field_errors
      end)

    if errors == [] do
      {:ok, data}
    else
      {:error, errors}
    end
  end

  defp validate_field(field, value, rules) do
    Enum.reduce(rules, [], fn rule, acc ->
      case check_rule(field, value, rule) do
        :ok -> acc
        {:error, reason} -> [{field, reason} | acc]
      end
    end)
  end

  defp check_rule(_field, value, {:required, true}) do
    if value == nil, do: {:error, :required_but_nil}, else: :ok
  end

  defp check_rule(_field, value, {:type, :boolean}) do
    if is_boolean(value), do: :ok, else: {:error, :expected_boolean}
  end

  defp check_rule(_field, value, {:type, :number}) do
    if is_number(value), do: :ok, else: {:error, :expected_number}
  end

  defp check_rule(_field, value, {:type, :string}) do
    if is_binary(value), do: :ok, else: {:error, :expected_string}
  end

  defp check_rule(_field, value, {:type, :map}) do
    if is_map(value), do: :ok, else: {:error, :expected_map}
  end

  defp check_rule(_field, value, {:type, :list}) do
    if is_list(value), do: :ok, else: {:error, :expected_list}
  end

  defp check_rule(_field, value, {:min, min}) when is_number(value) do
    if value >= min, do: :ok, else: {:error, {:below_minimum, min}}
  end

  defp check_rule(_field, value, {:max, max}) when is_number(value) do
    if value <= max, do: :ok, else: {:error, {:above_maximum, max}}
  end

  defp check_rule(_field, value, {:in, allowed}) do
    if value in allowed, do: :ok, else: {:error, :not_in_allowed}
  end

  defp check_rule(_field, value, {:pattern, regex}) when is_binary(value) do
    if Regex.match?(regex, value), do: :ok, else: {:error, :pattern_mismatch}
  end

  defp check_rule(_field, _value, _), do: :ok

  @doc """
  Validates and extracts a number from a map field, with fallback.
  """
  @spec extract_number(map(), atom(), number()) :: {:ok, number()}
  def extract_number(map, field, default \\ 0.0) when is_map(map) and is_atom(field) do
    case Map.get(map, field) do
      value when is_number(value) -> {:ok, value}
      _ -> {:ok, default}
    end
  end

  @doc """
  Validates and extracts a boolean from a map field, with fallback.
  """
  @spec extract_boolean(map(), atom(), boolean()) :: {:ok, boolean()}
  def extract_boolean(map, field, default \\ false) when is_map(map) and is_atom(field) do
    case Map.get(map, field) do
      value when is_boolean(value) -> {:ok, value}
      _ -> {:ok, default}
    end
  end

  @doc """
  Validates that a map has all required fields and returns them as a tuple.
  """
  @spec require_fields(map(), [atom()]) ::
          {:ok, tuple()} | {:error, {:missing_fields, [atom()]}}
  def require_fields(map, fields) when is_map(map) and is_list(fields) do
    missing = Enum.filter(fields, fn f -> not Map.has_key?(map, f) end)

    if missing == [] do
      values = Enum.map(fields, fn f -> Map.get(map, f) end)
      {:ok, List.to_tuple(values)}
    else
      {:error, {:missing_fields, missing}}
    end
  end

  @doc """
  Validates a list of items against a schema, returning all errors.
  """
  @spec validate_list([map()], schema()) ::
          {:ok, [map()]} | {:error, [{integer(), [{atom(), atom()}]}]}
  def validate_list(items, schema) when is_list(items) do
    results =
      items
      |> Enum.with_index()
      |> Enum.map(fn {item, idx} -> {idx, validate(item, schema)} end)

    errors = Enum.filter(results, fn {_, result} -> match?({:error, _}, result) end)

    if errors == [] do
      {:ok, items}
    else
      error_details = Enum.map(errors, fn {idx, {:error, reasons}} -> {idx, reasons} end)
      {:error, error_details}
    end
  end

  @doc """
  Safely converts a value to a number, handling strings and nil.
  """
  @spec to_number(any(), number()) :: {:ok, number()}
  def to_number(value, default \\ 0.0) do
    cond do
      is_number(value) -> {:ok, value}
      is_binary(value) ->
        case Float.parse(value) do
          {num, _} -> {:ok, num}
          :error -> {:ok, default}
        end
      true -> {:ok, default}
    end
  end

  @doc """
  Validates that a probability value is in [0, 1].
  """
  @spec probability(any()) :: {:ok, float()} | {:error, atom()}
  def probability(value) when is_number(value) and value >= 0 and value <= 1 do
    {:ok, value}
  end

  def probability(value) when is_number(value), do: {:error, :out_of_range}
  def probability(_), do: {:error, :not_a_number}

  # ---- NEW: Typed Interface Accessors ----

  @doc """
  Safely accesses a nested map path, returning {:ok, value} or {:error, reason}.
  Never raises on missing keys — verifies before access.

  "Capability must never outpace verification" — typed interfaces verify before access.

  Examples:
      safe_access(%{a: %{b: 1}}, [:a, :b]) => {:ok, 1}
      safe_access(%{a: %{b: 1}}, [:a, :c]) => {:error, {:key_not_found, :c}}
  """
  @spec safe_access(map(), [atom()]) :: {:ok, any()} | {:error, atom()}
  def safe_access(data, path) when is_map(data) and is_list(path) do
    do_safe_access(data, path)
  end

  defp do_safe_access(data, []) when is_map(data), do: {:ok, data}
  defp do_safe_access(data, [key | rest]) when is_map(data) do
    case Map.fetch(data, key) do
      {:ok, value} when rest == [] -> {:ok, value}
      {:ok, value} when is_map(value) -> do_safe_access(value, rest)
      {:ok, _value} -> {:error, {:path_terminated_early, key}}
      :error -> {:error, {:key_not_found, key}}
    end
  end

  defp do_safe_access(_, _), do: {:error, :not_a_map}

  @doc """
  Validates that a value is a non-empty string.
  """
  @spec non_empty_string(any()) :: {:ok, String.t()} | {:error, atom()}
  def non_empty_string(value) when is_binary(value) and value != "", do: {:ok, value}
  def non_empty_string(value) when is_binary(value), do: {:error, :empty_string}
  def non_empty_string(_), do: {:error, :not_a_string}

  @doc """
  Validates that a value is a positive integer.
  """
  @spec positive_integer(any()) :: {:ok, integer()} | {:error, atom()}
  def positive_integer(value) when is_integer(value) and value > 0, do: {:ok, value}
  def positive_integer(value) when is_integer(value), do: {:error, :not_positive}
  def positive_integer(_), do: {:error, :not_an_integer}

  @doc """
  Validates that a value is a non-negative number.
  """
  @spec non_negative_number(any()) :: {:ok, number()} | {:error, atom()}
  def non_negative_number(value) when is_number(value) and value >= 0, do: {:ok, value}
  def non_negative_number(value) when is_number(value), do: {:error, :negative}
  def non_negative_number(_), do: {:error, :not_a_number}

  @doc """
  Validates that a value is a list of a specific type.
  """
  @spec list_of(any(), atom()) :: {:ok, [any()]} | {:error, atom()}
  def list_of(value, type) when is_list(value) do
    if Enum.all?(value, fn item -> type_check(item, type) end) do
      {:ok, value}
    else
      {:error, {:not_all_of_type, type}}
    end
  end

  def list_of(_, _), do: {:error, :not_a_list}

  defp type_check(value, :number), do: is_number(value)
  defp type_check(value, :string), do: is_binary(value)
  defp type_check(value, :boolean), do: is_boolean(value)
  defp type_check(value, :map), do: is_map(value)
  defp type_check(value, :list), do: is_list(value)
  defp type_check(value, :atom), do: is_atom(value)
  defp type_check(_, _), do: false

  @doc """
  Validates a map field with a specific type, returning the value or error.
  Combines safe_fetch with type checking in one operation.
  """
  @spec typed_field(map(), atom(), atom()) :: {:ok, any()} | {:error, atom()}
  def typed_field(data, field, type) when is_map(data) and is_atom(field) and is_atom(type) do
    with {:ok, value} <- safe_fetch(data, field) do
      if type_check(value, type) do
        {:ok, value}
      else
        {:error, {:field_wrong_type, field, type}}
      end
    end
  end

  @doc """
  Validates a complete record structure with typed fields.
  Returns {:ok, validated_record} or {:error, [field_errors]}.

  Schema format: [field_name: :type, ...]
  where type is :number, :string, :boolean, :map, :list, :atom
  """
  @spec typed_record(map(), keyword()) :: {:ok, map()} | {:error, [{atom(), atom()}]}
  def typed_record(data, field_types) when is_map(data) and is_list(field_types) do
    errors =
      Enum.reduce(field_types, [], fn {field, type}, acc ->
        case typed_field(data, field, type) do
          {:ok, _} -> acc
          {:error, reason} -> [{field, reason} | acc]
        end
      end)

    if errors == [] do
      {:ok, data}
    else
      {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Validates that a value is within a specific range.
  """
  @spec in_range(any(), number(), number()) :: {:ok, number()} | {:error, atom()}
  def in_range(value, min, max) when is_number(value) and value >= min and value <= max do
    {:ok, value}
  end

  def in_range(value, _min, _max) when is_number(value), do: {:error, :out_of_range}
  def in_range(_, _, _), do: {:error, :not_a_number}

  @doc """
  Validates that a value is one of the allowed atoms.
  """
  @spec one_of(any(), [atom()]) :: {:ok, atom()} | {:error, atom()}
  def one_of(value, allowed) when is_atom(value) do
    if Enum.member?(allowed, value), do: {:ok, value}, else: {:error, :not_allowed}
  end
  def one_of(_, _), do: {:error, :not_an_atom}

  @doc """
  Validates that a map has exactly the specified keys (no extra, no missing).
  """
  @spec exact_keys(map(), [atom()]) :: {:ok, map()} | {:error, atom()}
  def exact_keys(data, keys) when is_map(data) and is_list(keys) do
    data_keys = Map.keys(data) |> MapSet.new()
    required_keys = MapSet.new(keys)

    missing = MapSet.difference(required_keys, data_keys)
    extra = MapSet.difference(data_keys, required_keys)

    cond do
      MapSet.size(missing) > 0 -> {:error, {:missing_keys, MapSet.to_list(missing)}}
      MapSet.size(extra) > 0 -> {:error, {:extra_keys, MapSet.to_list(extra)}}
      true -> {:ok, data}
    end
  end

  @doc """
  Validates that a value is a valid UUID format string.
  """
  @spec uuid(any()) :: {:ok, String.t()} | {:error, atom()}
  def uuid(value) when is_binary(value) do
    uuid_regex = ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if Regex.match?(uuid_regex, value), do: {:ok, value}, else: {:error, :invalid_uuid}
  end

  def uuid(_), do: {:error, :not_a_string}

  @doc """
  Validates that a value is a valid ISO 8601 timestamp string.
  """
  @spec timestamp(any()) :: {:ok, String.t()} | {:error, atom()}
  def timestamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, _, _} -> {:ok, value}
      {:error, _} -> {:error, :invalid_timestamp}
    end
  end

  def timestamp(_), do: {:error, :not_a_string}
end