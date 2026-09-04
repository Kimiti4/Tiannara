defmodule Tiannara.Graph.Postgres do
  @moduledoc """
  Persistent reality-graph adapter implementing `Graph.Behaviour` against a
  pluggable `Repo` (PostgreSQL in production). Preserves edge metadata, so
  lineage / blast-radius / causal / contradiction analysis work unchanged.

  Constitutional basis: Replaceability, "Preserve lineage", "Maintain audit
  trails", "Support reproducibility".
  """
  @behaviour Tiannara.Graph.Behaviour

  alias Tiannara.Graph.Edge

  defstruct [:repo, :handle]

  @impl true
  def new do
    {repo_module, opts} = Application.fetch_env!(:tiannara, :graph_repo)
    connect(repo_module, opts)
  end

  @doc "Explicit constructor: connect to a repo module with its opts."
  def connect(repo_module, opts) do
    {:ok, handle} = repo_module.init(opts)
    %__MODULE__{repo: repo_module, handle: handle}
  end

  def close(%__MODULE__{repo: repo, handle: handle}), do: repo.close(handle)

  @impl true
  def add_node(%__MODULE__{repo: repo, handle: h} = g, node_id, attrs) do
    :ok = repo.upsert_node(h, node_id, attrs)
    g
  end

  @impl true
  def update_node(%__MODULE__{repo: repo, handle: h} = g, node_id, attrs) do
    case repo.get_node(h, node_id) do
      {:ok, _} ->
        :ok = repo.upsert_node(h, node_id, attrs)
        g

      :not_found ->
        {:error, :missing_node}
    end
  end

  @impl true
  def get_node(%__MODULE__{repo: repo, handle: h}, node_id) do
    case repo.get_node(h, node_id) do
      {:ok, attrs} -> {:ok, attrs}
      :not_found -> :error
    end
  end

  @impl true
  def node_ids(%__MODULE__{repo: repo, handle: h}) do
    {:ok, ids} = repo.list_node_ids(h)
    ids
  end

  @impl true
  def add_edge(%__MODULE__{repo: repo, handle: h} = g, edge_id, from, to, label, metadata) do
    with {:ok, _} <- repo.get_node(h, from),
         {:ok, _} <- repo.get_node(h, to) do
      :ok = repo.upsert_edge(h, edge_id, from, to, label, metadata)
      {:ok, g}
    else
      :not_found -> {:error, :missing_node}
    end
  end

  @impl true
  def get_edge(%__MODULE__{repo: repo, handle: h}, edge_id) do
    case repo.get_edge(h, edge_id) do
      {:ok, %{from: from, to: to, label: label, metadata: metadata}} ->
        {:ok, %Edge{id: edge_id, from: from, to: to, label: label, metadata: metadata}}

      :not_found ->
        :error
    end
  end

  @impl true
  def edges(%__MODULE__{repo: repo, handle: h}) do
    {:ok, rows} = repo.list_edges(h)

    Enum.map(rows, fn %{edge_id: id, from: f, to: t, label: l, metadata: m} ->
      %Edge{id: id, from: f, to: t, label: l, metadata: m}
    end)
  end

  @impl true
  def out_edges(%__MODULE__{} = g, node_id) do
    {:ok, ids} = g.repo.out_edge_ids(g.handle, node_id)
    for id <- ids, {:ok, e} = get_edge(g, id), do: e
  end

  @impl true
  def in_edges(%__MODULE__{} = g, node_id) do
    {:ok, ids} = g.repo.in_edge_ids(g.handle, node_id)
    for id <- ids, {:ok, e} = get_edge(g, id), do: e
  end
end