defmodule Tiannara.OPC.Tier3.CommitEngine do
  @moduledoc """
  Tier 3 OPC: Commit Engine.
  
  Orchestrates the pre-execution pipeline for irreversible mutations.
  Flow:
  1. Compiles AST to Mutation
  2. Projects Futures (Semantic Sanity Layer)
  3. Validates Causal Budget
  4. Records in Irreversibility Ledger
  5. Commits to Substrate
  6. Triggers Compensatory Evolution if divergence is high.
  """
  
  require Logger
  
  alias Tiannara.OPC.Tier3.{
    MutationCompiler,
    StabilityProjector,
    CausalBudgetController,
    IrreversibilityLedger,
    CompensationEngine
  }
  
  @doc """
  Executes the full Tier 3 reality commit pipeline.
  """
  def commit_law(ast, current_shear, world_state) do
    Logger.info("======================================================")
    Logger.info("🌌 [Tier 3 Commit Engine] Initiating Irreversible Reality Commit")
    Logger.info("======================================================")
    
    with {:ok, mutation} <- MutationCompiler.compile(ast, :law),
         {:ok, stable_mutation} <- StabilityProjector.project_futures(mutation, world_state),
         {:ok, new_shear} <- CausalBudgetController.evaluate_budget(stable_mutation, current_shear) do
      
      # Persist to ledger
      IrreversibilityLedger.record_mutation(stable_mutation, %{status: :committed, global_shear: new_shear})
      
      Logger.warning("⚡ [Tier 3 Commit Engine] MUTATION COMMITTED to Substrate (ID: #{stable_mutation.id}).")
      
      # If confidence is moderate but acceptable, trigger compensation proactively
      patches = if stable_mutation.confidence_projection < 0.8 do
        CompensationEngine.calculate_compensation(stable_mutation, (1.0 - stable_mutation.confidence_projection) * 100)
      else
        []
      end
      
      {:ok, :committed, stable_mutation, patches}
    else
      {:error, reason} ->
        Logger.error("❌ [Tier 3 Commit Engine] Commit aborted during pre-execution sanity check: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
