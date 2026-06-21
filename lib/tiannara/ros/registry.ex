defmodule Tiannara.ROS.Registry do
  @moduledoc """
  Regional Ontological Shards (ROS) Registry.

  Provides dynamic registration for World Model components so that
  multiple independent epistemic branches (shards) can run simultaneously
  on the same BEAM node without colliding names.
  """

  @doc "Get the :via tuple for a given module and shard ID."
  def via(module, shard_id \\ :world_0) do
    {:via, Registry, {__MODULE__, {module, shard_id}}}
  end

  def child_spec(_) do
    Registry.child_spec(
      keys: :unique,
      name: __MODULE__
    )
  end
end
