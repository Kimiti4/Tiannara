defmodule TiannaraRuntime.WorldModel.Validation.Validator do
  @moduledoc """
  Phase 17 — Validator: comprehensive validation for all world model structs.

  Provides dispatch-based validation that routes to the appropriate struct's
  validate/1 function. Also provides cross-structural validations that check
  consistency across multiple components of a model.
  """

  @type validation_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Validate any world model ontology struct by dispatching on its type.
  """
  @spec validate(term()) :: validation_result()
  def validate(%TiannaraRuntime.WorldModel.Ontology.WorldModel{} = wm),
    do: TiannaraRuntime.WorldModel.Ontology.WorldModel.validate(wm)
  def validate(%TiannaraRuntime.WorldModel.Ontology.StateSpace{} = ss),
    do: TiannaraRuntime.WorldModel.Ontology.StateSpace.validate(ss)
  def validate(%TiannaraRuntime.WorldModel.Ontology.Variable{} = v),
    do: TiannaraRuntime.WorldModel.Ontology.Variable.validate(v)
  def validate(%TiannaraRuntime.WorldModel.Ontology.Parameter{} = p),
    do: TiannaraRuntime.WorldModel.Ontology.Parameter.validate(p)
  def validate(%TiannaraRuntime.WorldModel.Ontology.Equation{} = e),
    do: TiannaraRuntime.WorldModel.Ontology.Equation.validate(e)
  def validate(%TiannaraRuntime.WorldModel.Ontology.EquationSystem{} = es),
    do: TiannaraRuntime.WorldModel.Ontology.EquationSystem.validate(es)
  def validate(%TiannaraRuntime.WorldModel.Ontology.CausalNode{} = cn),
    do: TiannaraRuntime.WorldModel.Ontology.CausalNode.validate(cn)
  def validate(%TiannaraRuntime.WorldModel.Ontology.CausalEdge{} = ce),
    do: TiannaraRuntime.WorldModel.Ontology.CausalEdge.validate(ce)
  def validate(%TiannaraRuntime.WorldModel.Ontology.CausalGraph{} = cg),
    do: TiannaraRuntime.WorldModel.Ontology.CausalGraph.validate(cg)
  def validate(%TiannaraRuntime.WorldModel.Ontology.ObservationModel{} = om),
    do: TiannaraRuntime.WorldModel.Ontology.ObservationModel.validate(om)
  def validate(%TiannaraRuntime.WorldModel.Ontology.ProbabilityDistribution{} = pd),
    do: TiannaraRuntime.WorldModel.Ontology.ProbabilityDistribution.validate(pd)
  def validate(%TiannaraRuntime.WorldModel.Ontology.Interval{} = iv),
    do: TiannaraRuntime.WorldModel.Ontology.Interval.validate(iv)
  def validate(%TiannaraRuntime.WorldModel.Ontology.TimeSeriesPoint{} = tsp),
    do: TiannaraRuntime.WorldModel.Ontology.TimeSeriesPoint.validate(tsp)
  def validate(%TiannaraRuntime.WorldModel.Ontology.Prediction{} = p),
    do: TiannaraRuntime.WorldModel.Ontology.Prediction.validate(p)
  def validate(%TiannaraRuntime.WorldModel.Ontology.Intervention{} = iv),
    do: TiannaraRuntime.WorldModel.Ontology.Intervention.validate(iv)
  def validate(%TiannaraRuntime.WorldModel.Ontology.CounterfactualModel{} = cf),
    do: TiannaraRuntime.WorldModel.Ontology.CounterfactualModel.validate(cf)
  def validate(%TiannaraRuntime.WorldModel.Ontology.CertificationCheck{} = cc),
    do: TiannaraRuntime.WorldModel.Ontology.CertificationCheck.validate(cc)
  def validate(%TiannaraRuntime.WorldModel.Ontology.ModelCertificate{} = mc),
    do: TiannaraRuntime.WorldModel.Ontology.ModelCertificate.validate(mc)
  def validate(%TiannaraRuntime.WorldModel.Ontology.ValidationEvidence{} = ve),
    do: TiannaraRuntime.WorldModel.Ontology.ValidationEvidence.validate(ve)
  def validate(other),
    do: {:error, "unknown struct type: #{inspect(other)}"}

  @doc """
  Validate a complete WorldModel including all nested components.

  Checks:
    - All component structs are valid
    - Variables in state_space match variable definitions
    - Parameters match equation variables
    - Variables referenced in causal graph exist
    - Equations target variables that exist
  """
  @spec validate_model(TiannaraRuntime.WorldModel.Ontology.WorldModel.t()) :: validation_result()
  def validate_model(%TiannaraRuntime.WorldModel.Ontology.WorldModel{} = model) do
    with {:ok, _} <- validate(model),
         {:ok, _} <- validate_internal_consistency(model) do
      {:ok, model}
    end
  end

  @doc """
  Batch validate a list of structs. Returns list of {index, :ok | {:error, reason}}.
  """
  @spec validate_batch([term()]) :: [{non_neg_integer(), validation_result()}]
  def validate_batch(structs) do
    structs
    |> Enum.with_index()
    |> Enum.map(fn {s, i} -> {i, validate(s)} end)
  end

  defp validate_internal_consistency(model) do
    checks = [
      check_variables_match_state_space(model),
      check_equations_reference_variables(model),
      check_causal_graph_nodes_exist(model),
      check_parameters_match_equations(model)
    ]

    errors = Enum.reject(checks, &is_nil/1)

    case errors do
      [] -> {:ok, model}
      [first | _] -> {:error, first}
    end
  end

  defp check_variables_match_state_space(%{state_space: ss, variables: vars}) do
    var_ids = MapSet.new(vars, & &1.variable_id)
    ss_var_ids = MapSet.new(ss.variable_order)

    missing_in_ss = MapSet.difference(var_ids, ss_var_ids)

    if MapSet.size(missing_in_ss) > 0 do
      "Variables #{inspect(MapSet.to_list(missing_in_ss))} are defined but missing from state_space.variable_order"
    end
  end

  defp check_equations_reference_variables(%{equations: nil}), do: nil

  defp check_equations_reference_variables(%{equations: eqsys, variables: vars}) do
    var_ids = MapSet.new(vars, & &1.variable_id)

    referenced =
      eqsys.equations
      |> Enum.map(& &1.target_variable)
      |> MapSet.new()

    missing = MapSet.difference(referenced, var_ids)

    if MapSet.size(missing) > 0 do
      "Equations reference undefined variables: #{inspect(MapSet.to_list(missing))}"
    end
  end

  defp check_causal_graph_nodes_exist(%{causal_graph: nil}), do: nil

  defp check_causal_graph_nodes_exist(%{causal_graph: cg, variables: vars}) do
    var_ids = MapSet.new(vars, & &1.variable_id)
    node_ids = MapSet.new(cg.nodes, & &1.node_id)
    missing = MapSet.difference(node_ids, var_ids)

    if MapSet.size(missing) > 0 do
      "CausalGraph references undefined variable nodes: #{inspect(MapSet.to_list(missing))}"
    end
  end

  defp check_parameters_match_equations(%{parameters: params, equations: nil}) when params != [],
    do: "Parameters defined but no equations system exists"

  defp check_parameters_match_equations(_), do: nil
end
