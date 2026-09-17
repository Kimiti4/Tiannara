defmodule TiannaraRuntime.WorldModel.Pipeline.EquationLearning do
  @moduledoc """
  Phase 17.2 — Equation Learning (Pipeline Stage 4).

  Takes a causal graph (Stage 3 output) and evidence set (Stage 1 output)
  and assigns governing equations to each variable.

  ## Pipeline stage (from MODEL_PIPELINE.md):
    Stage 4 — Equation Learning:
      4a. For each variable, learn/assign governing equations
      4b. Represent equations in symbolic form
      4c. Compute equation_root
  """

  @behaviour TiannaraRuntime.WorldModel.Behaviours.Pipeline

  alias TiannaraRuntime.WorldModel.Ontology.{CausalGraph, CausalEdge, Equation, EquationSystem}

  @doc """
  Learn equations from causal graph.

  ## Returns
    `{:ok, %{equation_system: EquationSystem.t(), equation_root: String.t()}}`
  """
  @impl true
  @spec learn_equations(CausalGraph.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def learn_equations(%CausalGraph{} = causal_graph, _evidence_set) do
    equations = build_equations(causal_graph)

    with {:ok, eq_system} <- EquationSystem.new(equations: equations) do
      equation_root = compute_equation_root(eq_system)
      {:ok, %{equation_system: eq_system, equation_root: equation_root}}
    end
  end

  @doc """
  Build equations for each endogenous node in the causal graph.
  """
  @spec build_equations(CausalGraph.t()) :: [Equation.t()]
  def build_equations(%CausalGraph{nodes: nodes, edges: edges}) do
    incoming = build_incoming_map(edges)

    nodes
    |> Enum.filter(fn n -> n.type == :endogenous end)
    |> Enum.map(fn n ->
      parents = Map.get(incoming, n.node_id, [])
      build_equation_for_variable(n.node_id, parents)
    end)
    |> Enum.filter(fn {:ok, _} -> true; {:error, _} -> false end)
    |> Enum.map(fn {:ok, eq} -> eq end)
  end

  @doc """
  Build the equation for a single variable given its parents.
  """
  @spec build_equation_for_variable(String.t(), [String.t()]) :: {:ok, Equation.t()} | {:error, String.t()}
  def build_equation_for_variable(variable_id, parents) do
    expression = build_expression(variable_id, parents)
    eq_type = infer_equation_type(variable_id, parents)

    Equation.new(
      target_variable: variable_id,
      expression: expression,
      type: eq_type,
      derivation: :learned,
      assumptions: ["linear approximation"],
      confidence: 0.5
    )
  end

  @doc """
  Build symbolic expression map for a variable given its parents.
  """
  @spec build_expression(String.t(), [String.t()]) :: map()
  def build_expression(_variable_id, [] = _parents) do
    %{
      "form" => "constant",
      "parameters" => ["baseline"]
    }
  end

  def build_expression(variable_id, parents) do
    %{
      "form" => "linear",
      "target" => variable_id,
      "parents" => parents,
      "parameters" => Enum.map(parents, fn p -> "beta_#{p}" end) ++ ["intercept"],
      "link" => "identity"
    }
  end

  @doc """
  Infer equation type based on variable and its parents.
  """
  @spec infer_equation_type(String.t(), [String.t()]) :: atom()
  def infer_equation_type(_variable_id, _parents), do: :algebraic

  @doc """
  Build a map of node_id → list of parent node_ids from edges.
  """
  @spec build_incoming_map([CausalEdge.t()]) :: %{String.t() => [String.t()]}
  def build_incoming_map(edges) do
    Enum.reduce(edges, %{}, fn e, acc ->
      Map.update(acc, e.target, [e.source], fn sources -> [e.source | sources] end)
    end)
  end

  @doc """
  Compute equation_root from canonical equation system.
  """
  @spec compute_equation_root(EquationSystem.t()) :: String.t()
  def compute_equation_root(%EquationSystem{equations: equations}) do
    canonical =
      equations
      |> Enum.map(fn eq -> %{
        "target" => eq.target_variable,
        "type" => eq.type,
        "derivation" => eq.derivation,
        "confidence" => eq.confidence,
        "expression" => eq.expression
      } end)
      |> Enum.sort_by(fn e -> e["target"] end)
      |> Jason.encode!()

    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end
end
