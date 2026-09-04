defmodule Tiannara.Graph.Behaviour do
  @moduledoc """
  Contract for reality-graph implementations (InMemory, Persistent, Postgres).
  Every implementation exposes the same operation surface so lineage, blast
  radius, causal and contradiction analysis work unchanged on any backend.

  Constitutional basis: Replaceability, Modularity, "Preserve lineage",
  "Maintain audit trails".
  """

  @callback new() :: graph()
  @callback add_node(graph(), node_id :: term(), attrs :: map()) :: graph()
  @callback update_node(graph(), node_id :: term(), attrs :: map()) ::
              graph() | {:error, :missing_node}
  @callback get_node(graph(), node_id :: term()) :: {:ok, attrs :: map()} | :not_found
  @callback node_ids(graph()) :: [term()]
  @callback add_edge(graph(), edge_id :: term(), from :: term(), to :: term(),
                     label :: term(), metadata :: map()) ::
              {:ok, graph()} | {:error, :missing_node}
  @callback get_edge(graph(), edge_id :: term()) ::
              {:ok, Tiannara.Graph.Edge.t()} | :not_found
  @callback edges(graph()) :: [Tiannara.Graph.Edge.t()]
  @callback out_edges(graph(), node_id :: term()) :: [Tiannara.Graph.Edge.t()]
  @callback in_edges(graph(), node_id :: term()) :: [Tiannara.Graph.Edge.t()]

  @type graph :: term()
end