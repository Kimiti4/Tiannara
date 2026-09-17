defmodule Tiannara.Phase17.UCC.IRGenerator do
  @moduledoc """
  Translates constraint hypergraphs into substrate-agnostic DAG IR.
  Preserves semantic topology via functor composition.
  """
  use GenServer
  require Logger

  alias Tiannara.Phase17.UCC.{ResourceAllocator, SurfaceCompiler}

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{compilation_queue: :queue.new()}}

  @doc "Start compilation pipeline"
  @spec start_compilation(harm_id :: String.t(), hypergraph :: map(), target :: atom()) :: {:ok, String.t()} | {:error, String.t()}
  def start_compilation(harm_id, graph, target) do
    surface_id = "ucc_surface_#{harm_id}_#{target}"
    GenServer.cast(__MODULE__, {:compile, surface_id, graph, target})
    {:ok, surface_id}
  end

  @impl true
  def handle_cast({:compile, surface_id, graph, target}, state) do
    ir = generate_dag_ir(graph)
    complexity = compute_ir_complexity(ir)
    resource = ResourceAllocator.estimate(ir, target)
    
    if resource.utilization_ratio > 0.85 do
      Logger.warning("🚧 UCC: Resource bound exceeded for #{surface_id}. Triggering sharding.")
      Tiannara.Phase17.UCC.FallbackRouter.shard(surface_id, ir, target)
    else
      SurfaceCompiler.lower(ir, surface_id, target)
      Logger.info("✅ UCC: IR lowered for #{surface_id}")
    end
    
    {:noreply, %{state | compilation_queue: :queue.in(surface_id, state.compilation_queue)}}
  end

  defp generate_dag_ir(graph) do
    # Offload heavy DAG construction to Rust NIF in production
    %{nodes: Map.keys(graph.constraints), edges: graph.edges, weights: graph.weights}
  end

  defp compute_ir_complexity(ir) do
    length(ir.nodes) + length(ir.edges)
  end
end