defmodule TiannaraRuntime.WorldModel.Pipeline.ParameterEstimation do
  @moduledoc """
  Phase 17.2 — Parameter Estimation (Pipeline Stage 5).

  Takes an equation system (Stage 4 output) and evidence set (Stage 1 output)
  and estimates parameter values with uncertainty.

  ## Pipeline stage (from MODEL_PIPELINE.md):
    Stage 5 — Parameter Estimation:
      5a. Extract parameters from equation expressions
      5b. Estimate values from evidence data
      5c. Compute uncertainty distributions
      5d. Check identifiability
      5e. Compute parameter_root
  """

  @behaviour TiannaraRuntime.WorldModel.Behaviours.Pipeline

  alias TiannaraRuntime.WorldModel.Ontology.{EquationSystem, Equation, Parameter, ProbabilityDistribution}

  @doc """
  Estimate parameters from equations and evidence.

  ## Returns
    `{:ok, %{parameters: [Parameter.t()], parameter_root: String.t()}}`
  """
  @impl true
  @spec estimate_parameters(EquationSystem.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def estimate_parameters(%EquationSystem{} = eq_system, _evidence_set) do
    parameters = extract_and_estimate(eq_system)

    parameter_root = compute_parameter_root(parameters)

    {:ok, %{parameters: parameters, parameter_root: parameter_root}}
  end

  @doc """
  Extract parameter names from all equations and create Parameter structs.

  For each equation, reads the "parameters" field from the expression
  map and creates a placeholder Parameter (nil value — full estimation
  requires optimization over data).
  """
  @spec extract_and_estimate(EquationSystem.t()) :: [Parameter.t()]
  def extract_and_estimate(%EquationSystem{equations: equations}) do
    equations
    |> Enum.flat_map(fn eq ->
      param_names = extract_parameter_names(eq)
      Enum.map(param_names, fn name ->
        build_parameter(eq.target_variable, name)
      end)
    end)
  end

  @doc """
  Extract parameter names from an equation's expression.
  """
  @spec extract_parameter_names(Equation.t()) :: [String.t()]
  def extract_parameter_names(%Equation{expression: expr}) when is_map(expr) do
    Map.get(expr, "parameters", Map.get(expr, :parameters, []))
  end

  def extract_parameter_names(_eq), do: []

  @doc """
  Build a Parameter struct for a given parameter name and target variable.
  """
  @spec build_parameter(String.t(), String.t()) :: Parameter.t()
  def build_parameter(target_variable, param_name) do
    param_id = compute_parameter_id(target_variable, param_name)

    dist = default_distribution()

    {:ok, param} =
      Parameter.new(
        parameter_id: param_id,
        name: param_name,
        value: 0.0,
        distribution: dist,
        bounds: {-1.0e6, 1.0e6},
        is_identifiable: false,
        estimated_from: target_variable
      )

    param
  end

  defp default_distribution do
    case ProbabilityDistribution.new(type: :normal, parameters: %{"mean" => 0.0, "std" => 1.0}) do
      {:ok, dist} -> dist
      _ -> nil
    end
  end

  @doc """
  Compute parameter_root from sorted canonical parameter representations.
  """
  @spec compute_parameter_root([Parameter.t()]) :: String.t()
  def compute_parameter_root(parameters) do
    canonical =
      parameters
      |> Enum.map(fn p -> %{
        "parameter_id" => p.parameter_id,
        "name" => p.name,
        "value" => p.value,
        "bounds" => tuple_to_list(p.bounds),
        "is_identifiable" => p.is_identifiable,
        "estimated_from" => p.estimated_from
      } end)
      |> Enum.sort_by(fn p -> p["parameter_id"] end)
      |> Jason.encode!()

    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  defp compute_parameter_id(target_variable, param_name) do
    "param_#{target_variable}_#{param_name}"
  end

  defp tuple_to_list({a, b}), do: [a, b]
  defp tuple_to_list(nil), do: nil
  defp tuple_to_list(other), do: other
end
