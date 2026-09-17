defmodule Tiannara.Phase17.UCC.FallbackRouter do
  @moduledoc """
  Handles overload by sharding surfaces or reducing precision.
  """
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{conn_name: opts[:connection_name]}}
  end

  @doc "Shard oversized surface across multiple nodes"
  @spec shard(surface_id :: String.t(), ir :: map(), target :: atom()) :: :ok
  def shard(surface_id, ir, target) do
    GenServer.cast(__MODULE__, {:shard, surface_id, ir, target})
  end

  @impl true
  def handle_cast({:shard, surface_id, ir, target}, state) do
    shards = split_ir(ir, 4)
    Enum.with_index(shards, fn shard, idx ->
      shard_id = "#{surface_id}_shard_#{idx}"
      Gnat.pub(state.conn_name || :tiannara_nats, "tiannara.phase17.ucc.shard.#{shard_id}",
               Jason.encode!(%{shard_id: shard_id, parent: surface_id, ir: shard, target: target}))
    end)
    {:noreply, state}
  end

  defp split_ir(ir, count) do
    # Simple graph partitioning for demonstration
    nodes = Enum.chunk_every(ir.nodes, ceil(length(ir.nodes) / count))
    Enum.map(nodes, fn chunk -> %{nodes: chunk, edges: filter_edges(ir.edges, chunk)} end)
  end

  defp filter_edges(edges, nodes), do: Enum.filter(edges, fn {_u, v} -> v in nodes end)
end