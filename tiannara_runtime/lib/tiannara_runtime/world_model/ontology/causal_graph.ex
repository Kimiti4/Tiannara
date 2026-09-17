defmodule TiannaraRuntime.WorldModel.Ontology.CausalNode do
  @moduledoc """
  Phase 17 — CausalNode: a node in the causal graph, corresponding to a variable.
  """
  @enforce_keys [:node_id, :type]
  defstruct [:node_id, :type, :metadata]

  @type node_type :: :endogenous | :exogenous | :latent | :intervention

  @type t :: %__MODULE__{
          node_id: String.t(),
          type: node_type(),
          metadata: map()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    n = %__MODULE__{
      node_id: Keyword.get(opts, :node_id),
      type: Keyword.get(opts, :type),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    validate(n)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{node_id: id}) when is_nil(id) or id == "",
    do: {:error, "CausalNode node_id must not be empty"}
  def validate(%__MODULE__{type: t}) when t not in ~w(endogenous exogenous latent intervention)a,
    do: {:error, "CausalNode type must be one of: endogenous, exogenous, latent, intervention"}
  def validate(%__MODULE__{} = n), do: {:ok, n}
  def validate(_), do: {:error, "invalid CausalNode"}
end

defmodule TiannaraRuntime.WorldModel.Ontology.CausalEdge do
  @moduledoc """
  Phase 17 — CausalEdge: a directed causal relationship between two nodes.
  """
  @enforce_keys [:edge_id, :source, :target, :type]
  defstruct [:edge_id, :source, :target, :type, :confidence, :strength, :metadata]

  @type edge_type :: :direct | :inferred | :known | :speculative

  @type t :: %__MODULE__{
          edge_id: String.t(),
          source: String.t(),
          target: String.t(),
          type: edge_type(),
          confidence: float(),
          strength: float() | nil,
          metadata: map()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    e = %__MODULE__{
      edge_id: Keyword.get(opts, :edge_id, generate_id()),
      source: Keyword.get(opts, :source),
      target: Keyword.get(opts, :target),
      type: Keyword.get(opts, :type),
      confidence: Keyword.get(opts, :confidence, 1.0),
      strength: Keyword.get(opts, :strength),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    validate(e)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{source: s}) when is_nil(s) or s == "",
    do: {:error, "CausalEdge source must not be empty"}
  def validate(%__MODULE__{target: t}) when is_nil(t) or t == "",
    do: {:error, "CausalEdge target must not be empty"}
  def validate(%__MODULE__{source: s, target: t}) when s == t,
    do: {:error, "CausalEdge cannot have source == target (self-loop)"}
  def validate(%__MODULE__{type: t}) when t not in ~w(direct inferred known speculative)a,
    do: {:error, "CausalEdge type must be one of: direct, inferred, known, speculative"}
  def validate(%__MODULE__{confidence: c}) when c < 0.0 or c > 1.0,
    do: {:error, "CausalEdge confidence must be in [0.0, 1.0]"}
  def validate(%__MODULE__{} = e), do: {:ok, e}
  def validate(_), do: {:error, "invalid CausalEdge"}

  defp generate_id, do: "edge_" <> (:crypto.strong_rand_bytes(12) |> Base.encode16(case: :lower))
end

defmodule TiannaraRuntime.WorldModel.Ontology.CausalGraph do
  @moduledoc """
  Phase 17 — CausalGraph: a directed acyclic graph (DAG) of causal relationships.
  """
  @enforce_keys [:nodes, :edges]
  defstruct [:nodes, :edges, :latent_variables, :confounders, :do_calculus_level, :graph_fingerprint]

  @type t :: %__MODULE__{
          nodes: [TiannaraRuntime.WorldModel.Ontology.CausalNode.t()],
          edges: [TiannaraRuntime.WorldModel.Ontology.CausalEdge.t()],
          latent_variables: [String.t()],
          confounders: [map()],
          do_calculus_level: 1 | 2 | 3,
          graph_fingerprint: String.t() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    cg = %__MODULE__{
      nodes: Keyword.get(opts, :nodes, []),
      edges: Keyword.get(opts, :edges, []),
      latent_variables: Keyword.get(opts, :latent_variables, []),
      confounders: Keyword.get(opts, :confounders, []),
      do_calculus_level: Keyword.get(opts, :do_calculus_level, 1),
      graph_fingerprint: Keyword.get(opts, :graph_fingerprint)
    }
    validate(cg)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{nodes: ns}) when not is_list(ns),
    do: {:error, "CausalGraph nodes must be a list"}
  def validate(%__MODULE__{edges: es}) when not is_list(es),
    do: {:error, "CausalGraph edges must be a list"}
  def validate(%__MODULE__{do_calculus_level: l}) when l not in [1, 2, 3],
    do: {:error, "CausalGraph do_calculus_level must be 1, 2, or 3"}
  def validate(%__MODULE__{} = cg), do: {:ok, cg}
  def validate(_), do: {:error, "invalid CausalGraph"}
end
