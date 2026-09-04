defmodule Tiannara.Graph.Postgres.Repo.SQL do
  @moduledoc """
  PostgreSQL-backed Repo. Dependencies are INJECTED (query/exec/json functions)
  so this module has no hard dependency on Postgrex/Ecto/Jason here; production
  wires real drivers. `init/1` creates the schema idempotently.

  Wire in production, e.g.:
      query_fun = fn sql, params -> Postgrex.query!(pool, sql, params) end
      exec_fun  = fn sql, params -> Postgrex.query!(pool, sql, params) end
      Tiannara.Graph.Postgres.Repo.SQL.init(
        query_fun: query_fun, exec_fun: exec_fun,
        json_encode: &Jason.encode!/1, json_decode: &Jason.decode!/1)
  """
  @behaviour Tiannara.Graph.Postgres.Repo

  defstruct [:query_fun, :exec_fun, :json_encode, :json_decode]

  @schema [
    """
    CREATE TABLE IF NOT EXISTS graph_nodes (
      node_id TEXT PRIMARY KEY,
      attrs   JSONB NOT NULL
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS graph_edges (
      edge_id   TEXT PRIMARY KEY,
      from_node TEXT NOT NULL REFERENCES graph_nodes(node_id),
      to_node   TEXT NOT NULL REFERENCES graph_nodes(node_id),
      label     TEXT NOT NULL,
      metadata  JSONB NOT NULL
    )
    """,
    "CREATE INDEX IF NOT EXISTS idx_graph_edges_from ON graph_edges(from_node)",
    "CREATE INDEX IF NOT EXISTS idx_graph_edges_to   ON graph_edges(to_node)"
  ]

  @impl true
  def init(opts) do
    handle = %__MODULE__{
      query_fun: Keyword.fetch!(opts, :query_fun),
      exec_fun: Keyword.fetch!(opts, :exec_fun),
      json_encode: Keyword.fetch!(opts, :json_encode),
      json_decode: Keyword.fetch!(opts, :json_decode)
    }

    Enum.each(@schema, fn ddl -> handle.exec_fun.(ddl, []) end)
    {:ok, handle}
  end

  @impl true
  def upsert_node(h, node_id, attrs) do
    case h.exec_fun.(
           """
           INSERT INTO graph_nodes (node_id, attrs) VALUES ($1, $2)
           ON CONFLICT (node_id) DO UPDATE SET attrs = EXCLUDED.attrs
           """,
           [to_string(node_id), h.json_encode.(attrs)]) do
      {:error, _} = e -> e
      _ -> :ok
    end
  end

  @impl true
  def get_node(h, node_id) do
    case h.query_fun.("SELECT attrs FROM graph_nodes WHERE node_id = $1", [to_string(node_id)]) do
      {:ok, [[attrs]]} -> {:ok, h.json_decode.(attrs)}
      {:ok, []} -> :not_found
      {:error, _} = e -> e
    end
  end

  @impl true
  def list_node_ids(h) do
    case h.query_fun.("SELECT node_id FROM graph_nodes", []) do
      {:ok, rows} -> {:ok, Enum.map(rows, &hd/1)}
      {:error, _} = e -> e
    end
  end

  @impl true
  def upsert_edge(h, edge_id, from, to, label, metadata) do
    case h.exec_fun.(
           """
           INSERT INTO graph_edges (edge_id, from_node, to_node, label, metadata)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (edge_id) DO UPDATE SET
             from_node = EXCLUDED.from_node, to_node = EXCLUDED.to_node,
             label = EXCLUDED.label, metadata = EXCLUDED.metadata
           """,
           [to_string(edge_id), to_string(from), to_string(to), to_string(label),
            h.json_encode.(metadata)]) do
      {:error, _} = e -> e
      _ -> :ok
    end
  end

  @impl true
  def get_edge(h, edge_id) do
    case h.query_fun.(
           "SELECT from_node, to_node, label, metadata FROM graph_edges WHERE edge_id = $1",
           [to_string(edge_id)]) do
      {:ok, [[from, to, label, metadata]]} ->
        {:ok, %{from: from, to: to, label: label, metadata: h.json_decode.(metadata)}}

      {:ok, []} ->
        :not_found

      {:error, _} = e ->
        e
    end
  end

  @impl true
  def list_edges(h) do
    case h.query_fun.(
           "SELECT edge_id, from_node, to_node, label, metadata FROM graph_edges", []) do
      {:ok, rows} ->
        {:ok,
         Enum.map(rows, fn [id, from, to, label, metadata] ->
           %{edge_id: id, from: from, to: to, label: label, metadata: h.json_decode.(metadata)}
         end)}

      {:error, _} = e ->
        e
    end
  end

  @impl true
  def out_edge_ids(h, node_id) do
    case h.query_fun.("SELECT edge_id FROM graph_edges WHERE from_node = $1", [to_string(node_id)]) do
      {:ok, rows} -> {:ok, Enum.map(rows, &hd/1)}
      {:error, _} = e -> e
    end
  end

  @impl true
  def in_edge_ids(h, node_id) do
    case h.query_fun.("SELECT edge_id FROM graph_edges WHERE to_node = $1", [to_string(node_id)]) do
      {:ok, rows} -> {:ok, Enum.map(rows, &hd/1)}
      {:error, _} = e -> e
    end
  end

  @impl true
  def delete_all(h) do
    h.exec_fun.("DELETE FROM graph_edges", [])
    h.exec_fun.("DELETE FROM graph_nodes", [])
    :ok
  end

  @impl true
  def close(_h), do: :ok
end