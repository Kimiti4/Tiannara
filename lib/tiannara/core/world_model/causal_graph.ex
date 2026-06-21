defmodule Tiannara.Core.WorldModel.CausalGraph do
  @moduledoc """
  Causal relationships and intervention engine.

  Maps cause-effect relationships in the World Model.
  Supports counterfactual reasoning and intervention analysis.

  Example:
    Market Volatility → Trading Risk → Portfolio Loss

  Connects directly to the Causal Domain.
  """

  defstruct [
    :nodes,
    :edges,
    :confidence_scores,
    :interventions
  ]

  @doc "Create a new causal graph."
  def new do
    %__MODULE__{
      nodes: [],
      edges: [],
      confidence_scores: %{},
      interventions: []
    }
  end

  @doc "Add a causal node."
  def add_node(graph, node_id, node_name) do
    new_nodes = [{node_id, node_name} | graph.nodes]
    %{graph | nodes: new_nodes}
  end

  @doc "Add a causal edge (cause → effect)."
  def add_edge(graph, cause_id, effect_id, strength \\ 0.5) do
    new_edges = [{cause_id, effect_id, strength} | graph.edges]
    %{graph | edges: new_edges}
  end

  @doc "Analyze interventions on a node."
  def analyze_intervention(graph, node_id) do
    downstream =
      Enum.filter(graph.edges, fn {cause, _effect, _strength} ->
        cause == node_id
      end)

    {:ok, downstream}
  end
end
