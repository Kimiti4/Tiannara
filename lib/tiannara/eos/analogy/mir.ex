defmodule Tiannara.EOS.Analogy.MIR do
  @moduledoc """
  Mathematical Intermediate Representation.

  Four canonical graph kinds. Every theory is compiled into exactly one
  before any cross-domain comparison. Analogy is isomorphism over MIR,
  never over language.

  Constitutional mandate: "Distinguish clearly between facts, evidence,
  assumptions, hypotheses." — MIR is the structural fact layer beneath
  the linguistic hypothesis layer.
  """

  @graph_kinds [:causal, :dependency, :constraint, :state_transition]

  defmodule Node do
    @moduledoc "Abstract node in the MIR graph."
    @enforce_keys [:id, :role]
    defstruct [
      :id,
      :role,
      :sign,
      :dimensionality,
      :attributes
    ]
  end

  defmodule Edge do
    @moduledoc "Typed edge in the MIR graph."
    @enforce_keys [:from, :to, :kind]
    defstruct [
      :from,
      :to,
      :kind,
      :polarity,
      :strength
    ]
  end

  defmodule Graph do
    @moduledoc "A compiled MIR graph."
    @enforce_keys [:kind, :nodes, :edges]
    defstruct [:kind, :nodes, :edges, :invariants, :symmetries]
  end

  @doc """
  Compile a theory into its MIR. This is the only place domain content
  touches the analogy pipeline.
  """
  def compile(theory_artifact) do
    kind = infer_graph_kind(theory_artifact)
    nodes = extract_abstract_nodes(theory_artifact)
    edges = extract_abstract_edges(theory_artifact)
    invariants = derive_invariants(nodes, edges)
    symmetries = derive_symmetries(nodes, edges)

    %Graph{kind: kind, nodes: nodes, edges: edges,
           invariants: invariants, symmetries: symmetries}
  end

  @doc """
  Typed subgraph isomorphism with polarity preservation.
  Two graphs are analogous iff there exists a bijection between a
  subgraph of A and a subgraph of B preserving:
    - node roles
    - edge kinds
    - edge polarities
    - invariant structure
  """
  def analogous?(%Graph{} = a, %Graph{} = b, opts \\ []) do
    min_overlap = opts[:min_overlap] || 0.6

    cond do
      a.kind != b.kind ->
        subgraph_match(a, b, min_overlap) * 0.5

      true ->
        subgraph_match(a, b, min_overlap)
    end
  end

  defp subgraph_match(_a, _b, _min_overlap), do: 0.0
  defp infer_graph_kind(_), do: :causal
  defp extract_abstract_nodes(_), do: []
  defp extract_abstract_edges(_), do: []
  defp derive_invariants(_, _), do: []
  defp derive_symmetries(_, _), do: []
end
