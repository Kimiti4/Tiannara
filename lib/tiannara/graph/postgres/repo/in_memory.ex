defmodule Tiannara.Graph.Postgres.Repo.InMemory do
  @moduledoc """
  Agent-backed in-memory Repo. Used for tests and as a lightweight durable
  store (the handle is an Agent that outlives any single adapter struct).
  """
  @behaviour Tiannara.Graph.Postgres.Repo

  @impl true
  def init(_opts) do
    Agent.start_link(fn -> %{nodes: %{}, edges: %{}} end)
  end

  @impl true
  def upsert_node(handle, node_id, attrs) do
    Agent.update(handle, fn s -> %{s | nodes: Map.put(s.nodes, node_id, attrs)} end)
    :ok
  end

  @impl true
  def get_node(handle, node_id) do
    Agent.get(handle, fn s ->
      case Map.fetch(s.nodes, node_id) do
        {:ok, attrs} -> {:ok, attrs}
        :error -> :not_found
      end
    end)
  end

  @impl true
  def list_node_ids(handle) do
    {:ok, Agent.get(handle, fn s -> Map.keys(s.nodes) end)}
  end

  @impl true
  def upsert_edge(handle, edge_id, from, to, label, metadata) do
    Agent.update(handle, fn s ->
      %{s | edges: Map.put(s.edges, edge_id,
        %{from: from, to: to, label: label, metadata: metadata})}
    end)

    :ok
  end

  @impl true
  def get_edge(handle, edge_id) do
    Agent.get(handle, fn s ->
      case Map.fetch(s.edges, edge_id) do
        {:ok, e} -> {:ok, e}
        :error -> :not_found
      end
    end)
  end

  @impl true
  def list_edges(handle) do
    {:ok,
     Agent.get(handle, fn s ->
       Enum.map(s.edges, fn {id, e} -> Map.put(e, :edge_id, id) end)
     end)}
  end

  @impl true
  def out_edge_ids(handle, node_id) do
    {:ok, Agent.get(handle, fn s ->
      for {id, e} <- s.edges, e.from == node_id, do: id
    end)}
  end

  @impl true
  def in_edge_ids(handle, node_id) do
    {:ok, Agent.get(handle, fn s ->
      for {id, e} <- s.edges, e.to == node_id, do: id
    end)}
  end

  @impl true
  def delete_all(handle) do
    Agent.update(handle, fn _ -> %{nodes: %{}, edges: %{}} end)
    :ok
  end

  @impl true
  def close(handle) do
    if Process.alive?(handle), do: Agent.stop(handle)
    :ok
  end
end