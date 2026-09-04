defmodule Tiannara.Graph.Postgres.Repo do
  @moduledoc """
  Data-access contract for the persistent graph. Production is backed by
  PostgreSQL (see Repo.SQL + migration); tests/dev use Repo.InMemory. Any
  module implementing this behaviour can serve as the graph's storage.

  Constitutional basis: Replaceability, Modularity ("explicit interfaces,
  independent replacement"), "Support reproducibility".
  """

  @callback init(opts :: keyword()) :: {:ok, handle :: term()} | {:error, term()}
  @callback upsert_node(handle :: term(), node_id :: term(), attrs :: map()) ::
              :ok | {:error, term()}
  @callback get_node(handle :: term(), node_id :: term()) :: {:ok, map()} | :not_found
  @callback list_node_ids(handle :: term()) :: {:ok, [term()]}
  @callback upsert_edge(handle :: term(), edge_id :: term(), from :: term(), to :: term(),
              label :: term(), metadata :: map()) :: :ok | {:error, term()}
  @callback get_edge(handle :: term(), edge_id :: term()) :: {:ok, map()} | :not_found
  @callback list_edges(handle :: term()) :: {:ok, [map()]}
  @callback out_edge_ids(handle :: term(), node_id :: term()) :: {:ok, [term()]}
  @callback in_edge_ids(handle :: term(), node_id :: term()) :: {:ok, [term()]}
  @callback delete_all(handle :: term()) :: :ok
  @callback close(handle :: term()) :: :ok
end