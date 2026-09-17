defmodule Tiannara.Phase11.CRCA.MultiHistorySync do
  @moduledoc """
  Merges divergent history DAGs without inducing causal paradoxes.
  Uses topological alignment + monotonic tick mapping.
  """
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{
      conn_name: opts[:connection_name],
      pending_merges: %{},
      sync_surfaces: %{}
    }}
  end

  @doc "Prepare multi-history merge for arbitration ID"
  @spec prepare_merge(arb_id :: String.t(), a :: String.t(), b :: String.t(), conn_name :: atom()) :: 
    {:ok, surface_id :: String.t()}
  def prepare_merge(arb_id, a, b, conn_name) do
    surface_id = "temporal_surface_#{arb_id}"
    
    Gnat.pub(conn_name, "tiannara.crca.sync.prepare",
             Jason.encode!(%{surface_id: surface_id, partitions: [a, b]}))
             
    {:ok, surface_id}
  end

  @doc "Execute DAG merge with paradox safety checks"
  @spec execute_dag_merge(history_dag_a :: map(), history_dag_b :: map()) :: 
    {:ok, merged_dag :: map()} | {:error, :causal_paradox}
  def execute_dag_merge(dag_a, dag_b) do
    case Tiannara.Phase11.CRCA.ParadoxResolver.detect_cycles([dag_a, dag_b]) do
      :clean -> 
        {:ok, topological_merge(dag_a, dag_b)}
      {:cycles, _edges} -> 
        {:error, :causal_paradox}
    end
  end

  defp topological_merge(a, b) do
    # Simplified merge: union vertices, align edges by timestamp
    %{
      vertices: MapSet.union(a.vertices, b.vertices),
      edges: Map.merge(a.edges, b.edges, fn _k, e1, e2 -> max(e1, e2) end),
      root: a.root || b.root
    }
  end
end