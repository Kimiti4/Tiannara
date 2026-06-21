defmodule Tiannara.Core.WorldModel.Supervisor do
  @moduledoc """
  Supervision tree for the World Model subsystem.

  Manages all World Model components as a coordinated system:
  - Entity Registry
  - Belief System
  - Causal Graph Engine
  - Timeline Manager
  - Uncertainty Tracker
  - Prediction Engine
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    shard_id = Keyword.get(opts, :shard_id, :world_0)
    name = Tiannara.ROS.Registry.via(__MODULE__, shard_id)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    shard_id = Keyword.get(opts, :shard_id, :world_0)

    children = [
      # Entity Registry - manages all entities in the World Model
      {Tiannara.Core.WorldModel.EntityRegistry, [shard_id: shard_id]},
      # Belief System - manages confidence-weighted beliefs
      {Tiannara.Core.WorldModel.BeliefSystem, [shard_id: shard_id]},
      # Causal Graph Engine - manages cause-effect relationships
      {Tiannara.Core.WorldModel.CausalEngine, [shard_id: shard_id]},
      # Timeline Manager - manages past, present, future states
      {Tiannara.Core.WorldModel.TimelineManager, [shard_id: shard_id]},
      # Uncertainty Tracker - manages ambiguities and contradictions
      {Tiannara.Core.WorldModel.UncertaintyTracker, [shard_id: shard_id]},
      # Prediction Engine - generates scenario forecasts
      {Tiannara.Core.WorldModel.PredictionEngine, [shard_id: shard_id]}
    ]

    Logger.info("Initializing World Model Shard (#{shard_id}) supervisor with #{length(children)} worker processes")

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 30)
  end
end
