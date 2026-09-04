defmodule Tiannara.ASC.Research.Programs.TransferPhysicsProgram do
  @moduledoc """
  Phase 6.1: Executes real targeted hypothesis campaigns to discover transfer laws.
  """
  
  alias Tiannara.ASC.Research.{TelemetrySnapshot, ResearchRegistry}
  alias Tiannara.ASC.Laws.{ExperimentDesigner, Discoverer}
  require Logger

  def start do
    program = %Tiannara.ASC.Research.ResearchProgram{
      name: "Transfer Physics",
      domain: :transfer_physics,
      methodology: :targeted_experimentation,
      budget: 1000
    }
    
    ResearchRegistry.register_program(program)
  end

  def run_epoch(program_id, budget) do
    Logger.info("🔬 [TransferPhysics] Executing REAL Targeted Hypothesis Campaign (Budget: #{budget})")
    
    snap_before = TelemetrySnapshot.take()
    
    # 1. Design real experiments based on actual ecology gaps
    experiments = ExperimentDesigner.design_experiments()
    
    # 2. Execute a subset of them proportional to the budget
    # (Assuming each experiment costs ~10 units of budget/compute)
    batch_size = max(1, trunc(budget / 10))
    batch = Enum.take(experiments, batch_size)
    
    # 3. Run the actual campaign logic (injecting into real TransferEcology)
    Enum.each(batch, fn exp -> 
      Tiannara.ASC.Laws.TargetedHypothesisCampaign.execute_experimental_condition(exp) 
    end)
    
    # 4. Run the real Discoverer to mint laws from the new data
    Discoverer.discover_transfer_ecology_laws()
    
    snap_after = TelemetrySnapshot.take()
    delta = TelemetrySnapshot.calculate_delta(snap_before, snap_after)
    
    Logger.info("  📊 Real Delta: #{delta.laws_generated} laws minted, #{delta.utility_generated} utility gained.")
    
    ResearchRegistry.update_program_metrics(program_id, delta)
  end
end
