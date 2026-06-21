defmodule Tiannara.ROS.ShardSupervisor do
  @moduledoc """
  DynamicSupervisor for Regional Ontological Shards.
  
  Spawns entire WorldModel supervision trees dynamically for each new epistemic branch.
  """
  
  use DynamicSupervisor
  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a new WorldModel shard dynamically.
  """
  def start_shard(shard_id) do
    Logger.info("🌌 [ROS] Spawning Epistemic Branch: #{shard_id}")
    child_spec = %{
      id: {Tiannara.Core.WorldModel.Supervisor, shard_id},
      start: {Tiannara.Core.WorldModel.Supervisor, :start_link, [[shard_id: shard_id]]},
      restart: :transient,
      type: :supervisor
    }
    
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
