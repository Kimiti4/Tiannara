defmodule Tiannara.MetaEcology.ClusterFormation do
  @moduledoc """
  Meta-Ecology: Cluster Formation.
  
  Binds ≥ 3 worlds together when they successfully exchange stable ontological signals.
  Forms the foundational graph for the regional Meta-Ecology.
  """
  
  require Logger
  alias Tiannara.MetaEcology.StabilityMetrics
  
  @doc """
  Attempts to form a cluster from a list of world IDs.
  Requires at least 3 worlds to form a stable triangular graph.
  """
  def form_cluster(cluster_id, world_ids) when length(world_ids) >= 3 do
    Logger.info("🌐 [Meta-Ecology] Attempting to bind worlds #{inspect(world_ids)} into cluster #{cluster_id}")
    
    # Evaluate if the combined states are stable
    # (Mocking state aggregation)
    case StabilityMetrics.evaluate_cluster_health(%{}) do
      {:ok, :stable} ->
        Logger.info("✅ [Meta-Ecology] Cluster #{cluster_id} formed successfully.")
        {:ok, %{id: cluster_id, worlds: world_ids}}
        
      {:error, _reason} ->
        Logger.error("🚫 [Meta-Ecology] Cluster #{cluster_id} formation failed. Too much internal stress.")
        {:error, :cluster_unstable}
    end
  end
  
  def form_cluster(cluster_id, _world_ids) do
    Logger.error("🚫 [Meta-Ecology] Cannot form cluster #{cluster_id}. Requires ≥ 3 worlds for structural tensegrity.")
    {:error, :insufficient_worlds}
  end
end
