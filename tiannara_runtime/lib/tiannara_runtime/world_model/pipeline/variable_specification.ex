defmodule TiannaraRuntime.WorldModel.Pipeline.VariableSpecification do
  @moduledoc """
  Phase 17.2 — Variable Specification (Pipeline Stage 2).

  Takes an evidence set (Stage 1 output) and infers typed variable
  specifications from the observation payload schemas.

  ## Pipeline stage (from MODEL_PIPELINE.md):
    Stage 2 — Variable Specification:
      2a. Extract variable names from evidence payload keys
      2b. Infer type from observed values (continuous, categorical, ordinal)
      2c. Determine domain bounds from min/max or unique values
      2d. Classify each variable as endogenous or exogenous
      2e. Compute variable_root (SHA-256 of sorted variable specs)
  """

  @behaviour TiannaraRuntime.WorldModel.Behaviours.Pipeline

  alias TiannaraRuntime.WorldModel.Ontology.Variable

  @doc """
  Specify variables from an evidence set.

  ## Returns
    `{:ok, %{variables: [Variable.t()], variable_root: String.t()}}`
  """
  @impl true
  @spec specify_variables(map()) :: {:ok, map()} | {:error, String.t()}
  def specify_variables(evidence_set) when is_map(evidence_set) do
    observations = Map.get(evidence_set, "observations", Map.get(evidence_set, :observations, []))
    payload_keys = extract_all_payload_keys(observations)

    variables =
      payload_keys
      |> Enum.map(fn key ->
        values = collect_values_for_key(observations, key)
        infer_variable(key, values)
      end)
      |> Enum.map(fn {:ok, v} -> v end)

    variable_root = compute_variable_root(variables)

    {:ok, %{variables: variables, variable_root: variable_root}}
  end

  @doc """
  Extract all unique payload keys across a list of observations.
  """
  @spec extract_all_payload_keys([map()]) :: [String.t()]
  def extract_all_payload_keys(observations) do
    observations
    |> Enum.flat_map(fn obs ->
      payload = Map.get(obs, "payload", Map.get(obs, :payload, %{}))
      Map.keys(payload)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Collect all values for a given payload key across observations.
  """
  @spec collect_values_for_key([map()], String.t()) :: [term()]
  def collect_values_for_key(observations, key) do
    observations
    |> Enum.map(fn obs ->
      payload = Map.get(obs, "payload", Map.get(obs, :payload, %{}))
      Map.get(payload, key)
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Infer a Variable struct from a key and its observed values.

  Type inference rules:
    - All values are numbers → :continuous
    - All values are booleans → :categorical (domain: [true, false])
    - All values are strings → :categorical
    - Mixed types → :categorical (string-cast)
    - Empty values → :continuous (assumed)
  """
  @spec infer_variable(String.t(), [term()]) :: {:ok, Variable.t()} | {:error, String.t()}
  def infer_variable(key, values) do
    var_type = infer_type(values)
    domain = infer_domain(var_type, values)

    var_id = compute_variable_id(key, var_type, domain)

    Variable.new(
      variable_id: var_id,
      name: key,
      type: var_type,
      domain: domain,
      is_endogenous: true,
      description: "Inferred from evidence: #{key}"
    )
  end

  @doc """
  Infer variable type from observed values.
  """
  @spec infer_type([term()]) :: Variable.var_type()
  def infer_type([]), do: :continuous
  def infer_type(values) do
    types = values |> Enum.map(&value_type/1) |> Enum.uniq()

    cond do
      types == [:boolean] -> :categorical
      types == [:number] -> :continuous
      Enum.all?(types, &(&1 == :string)) -> :categorical
      true -> :categorical
    end
  end

  @doc """
  Infer domain bounds from variable type and observed values.

  For :continuous → {min, max}
  For :categorical → unique sorted values list
  """
  @spec infer_domain(Variable.var_type(), [term()]) :: term()
  def infer_domain(:continuous, []), do: nil
  def infer_domain(:continuous, values) do
    nums = Enum.filter(values, &is_number/1)
    case nums do
      [] -> nil
      _ -> {Enum.min(nums), Enum.max(nums)}
    end
  end
  def infer_domain(:categorical, values) do
    values |> Enum.uniq() |> Enum.sort()
  end
  def infer_domain(_, _values), do: nil

  @doc """
  Compute a deterministic root hash from sorted variable specifications.
  """
  @spec compute_variable_root([Variable.t()]) :: String.t()
  def compute_variable_root(variables) do
    canonical =
      variables
      |> Enum.map(&canonical_variable/1)
      |> Enum.sort_by(fn v -> v["name"] end)
      |> Jason.encode!()

    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  defp value_type(v) when is_number(v), do: :number
  defp value_type(v) when is_boolean(v), do: :boolean
  defp value_type(v) when is_binary(v), do: :string
  defp value_type(_), do: :other

  defp compute_variable_id(name, type, domain) do
    canonical =
      %{
        "name" => name,
        "type" => type,
        "domain" => encode_domain(domain)
      }
      |> Jason.encode!()

    "var_" <> (:crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower) |> String.slice(0, 32))
  end

  defp canonical_variable(%Variable{} = v) do
    %{
      "variable_id" => v.variable_id,
      "name" => v.name,
      "type" => v.type,
      "domain" => encode_domain(v.domain),
      "unit" => v.unit,
      "is_endogenous" => v.is_endogenous
    }
  end

  defp encode_domain({l, u}), do: [l, u]
  defp encode_domain(other), do: other
end
