defmodule Tiannara.ASC.Civilization.AutonomousGuildCampaign do
  @moduledoc """
  Phase 9: Spawns an EngineeringTask and hands it to the Guild Orchestrator.
  """
  alias Tiannara.ASC.Civilization.{EngineeringTask, GuildOrchestrator}
  require Logger

  def run do
    Logger.info("🌌 [Phase 9] Initiating Autonomous Software Guild Campaign")
    
    # Force a high exploitation bias genome to trigger the Reviewer loopback
    genome = %{methodology: :default, exploration_bias: 0.5, exploitation_bias: 0.8}
    
    task = %EngineeringTask{
      id: "task_#{:erlang.unique_integer([:positive])}",
      goal: "Optimize the TransferEcology ETS lookup patterns to reduce latency.",
      assigned_genome: genome
    }
    
    GuildOrchestrator.execute(task)
  end
end
