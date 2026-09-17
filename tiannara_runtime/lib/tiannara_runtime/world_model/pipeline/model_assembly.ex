defmodule TiannaraRuntime.WorldModel.Pipeline.ModelAssembly do
  @moduledoc """
  Phase 17.2 — Model Assembly (Pipeline Stage 6).

  Takes all pipeline outputs (variables, causal graph, equations, parameters)
  and assembles them into a complete WorldModel, then registers it in the
  ModelRegistry.

  ## Pipeline stage (from MODEL_PIPELINE.md):
    Stage 6 — Model Assembly:
      6a. Assemble all components into WorldModel.t
      6b. Compute model fingerprint (replay root)
      6c. Register model in ModelRegistry with status :draft
  """

  @behaviour TiannaraRuntime.WorldModel.Behaviours.Pipeline

  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias TiannaraRuntime.WorldModel.Ontology.{WorldModel, StateSpace, Variable}

  @doc """
  Assemble all components into a WorldModel and register it.

  Expected components map keys:
    - `:name` — human-readable name (required)
    - `:domain` — research domain atom (required)
    - `:variables` — [Variable.t()]
    - `:causal_graph` — CausalGraph.t()
    - `:equation_system` — EquationSystem.t()
    - `:parameters` — [Parameter.t()]
    - `:evidence_roots` — [String.t()]
    - `:metadata` — map() of extra metadata
    - `:variable_root`, `:structure_root`, `:equation_root`, `:parameter_root` — for fingerprint

  ## Returns
    `{:ok, WorldModel.t()}`
  """
  @impl true
  @spec assemble_model(map()) :: {:ok, WorldModel.t()} | {:error, String.t()}
  def assemble_model(components) when is_map(components) do
    name = Map.get(components, :name)
    domain = Map.get(components, :domain)
    variables = Map.get(components, :variables, [])
    causal_graph = Map.get(components, :causal_graph)
    equation_system = Map.get(components, :equation_system)
    parameters = Map.get(components, :parameters, [])
    evidence_roots = Map.get(components, :evidence_roots, [])
    metadata = Map.get(components, :metadata, %{})

    variable_root = Map.get(components, :variable_root)
    structure_root = Map.get(components, :structure_root)
    equation_root = Map.get(components, :equation_root)
    parameter_root = Map.get(components, :parameter_root)

    fingerprint = compute_model_fingerprint(%{
      variable_root: variable_root,
      structure_root: structure_root,
      equation_root: equation_root,
      parameter_root: parameter_root
    })

    state_space = build_state_space(variables)

    model_id = compute_model_id(fingerprint, name)

    with {:ok, model} <- WorldModel.new(
           model_id: model_id,
           name: name,
           domain: domain,
           state_space: state_space,
           variables: variables,
           parameters: parameters,
           equations: equation_system,
           causal_graph: causal_graph,
           evidence_roots: evidence_roots,
           metadata: metadata,
           fingerprint: fingerprint,
           status: :draft
         ) do
      ModelRegistry.store_model(model, force: false)
    end
  end

  @doc """
  Build a StateSpace from a list of variables.
  """
  @spec build_state_space([Variable.t()]) :: StateSpace.t()
  def build_state_space(variables) do
    variable_order = Enum.map(variables, & &1.variable_id)
    bounds = build_bounds_map(variables)
    support_type = infer_support_type(variables)

    {:ok, ss} =
      StateSpace.new(
        dimensions: length(variables),
        variable_order: variable_order,
        bounds: bounds,
        support_type: support_type
      )

    ss
  end

  @doc """
  Build a bounds map from variable domains.
  """
  @spec build_bounds_map([Variable.t()]) :: map()
  def build_bounds_map(variables) do
    variables
    |> Enum.filter(fn v -> v.domain != nil end)
    |> Enum.into(%{}, fn v -> {v.variable_id, v.domain} end)
  end

  @doc """
  Infer state space support type from variable types.
  """
  @spec infer_support_type([Variable.t()]) :: :continuous | :discrete | :mixed
  def infer_support_type(variables) do
    types = Enum.map(variables, & &1.type) |> Enum.uniq()

    cond do
      Enum.all?(types, &(&1 == :continuous)) -> :continuous
      Enum.any?(types, &(&1 == :continuous)) -> :mixed
      true -> :discrete
    end
  end

  @doc """
  Compute model fingerprint from stage roots.

  fingerprint = SHA-256(sorted concatenated stage roots)
  """
  @spec compute_model_fingerprint(map()) :: String.t()
  def compute_model_fingerprint(roots) do
    roots
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
    |> Enum.sort_by(fn {k, _v} -> to_string(k) end)
    |> Enum.map(fn {_k, v} -> v end)
    |> Enum.join("|")
    |> then(fn combined ->
      :crypto.hash(:sha256, combined) |> Base.encode16(case: :lower)
    end)
  end

  defp compute_model_id(fingerprint, nil), do: compute_model_id(fingerprint, "unnamed")
  defp compute_model_id(fingerprint, name) do
    "wm_#{:crypto.hash(:sha256, name <> fingerprint) |> Base.encode16(case: :lower) |> String.slice(0, 16)}"
  end
end
