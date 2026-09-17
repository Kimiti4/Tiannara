defmodule Tiannara.MCALv2.RecursiveFeedbackLoop do
  @moduledoc """
  MCAL v2: Orchestration Loop.
  
  MCAL state -> CIS evaluation -> Identity mutation -> Divergence generation -> Survival evaluation.
  """
  
  require Logger
  
  alias Tiannara.MCALv2.{Identity, MutationEngine, SurvivalEvaluator, IdentitySelector, IdentityTree}

  @doc """
  Executes the full recursive identity loop.
  """
  def cycle() do
    Logger.info("\n=== INITIATING RECURSIVE IDENTITY LOOP ===")
    
    # 1. Start with a root identity
    root_identity = %Identity{
      id: UUID.uuid4(),
      cognitive_policy: :stabilization,
      memory_signature: 0.5,
      mutation_rate: 0.1,
      ecological_role: :preserver,
      causal_bias: 0.5,
      cross_world_projection: ["world_1", "world_2"],
      fitness_score: 0.0,
      lineage_parent: nil
    }
    
    IdentityTree.set_root(root_identity)
    
    # 2. Simulate an incoming CIS Stress Signal
    stress_signal = :high_stress
    Logger.warning("🚨 [CIS Feedback] Emitting ecosystem stress signal: #{inspect(stress_signal)}")
    
    # 3. Spawn divergent identities (Mutation)
    Logger.info("🧬 [MCAL v2] Spawning recursive identity branches to handle stress...")
    branches = Enum.map(1..3, fn _ -> 
      branch = MutationEngine.spawn(root_identity, stress_signal)
      IdentityTree.register_identity(branch)
      branch
    end)
    
    # 4. Evaluate Survival Fitness
    Logger.info("⚖️ [MCAL v2] Submitting branches to Survival Evaluator...")
    scored_branches = Enum.map(branches, &SurvivalEvaluator.evaluate(&1, stress_signal))
    
    # 5. Select fittest identity
    fittest = IdentitySelector.select(scored_branches)
    
    # 6. Establish new root
    IdentityTree.set_root(fittest)
    
    Logger.info("✅ [MCAL v2] Recursive cycle complete. Identity ecology adapted.")
    fittest
  end
end
