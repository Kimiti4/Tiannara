defmodule Tiannara.OPC.T4.UniverseASTEmitter do
  @moduledoc """
  OPC Tier 4: Universe AST Emitter.
  
  Emits the finalized AST as an executable `Universe_α` reality specification.
  """
  
  require Logger
  alias Tiannara.OPC.T4.CausalAST

  @doc """
  Packages the resolved grammar into a full Causal AST and calculates its stability score.
  """
  def emit(grammar, base_id \\ nil) do
    id = base_id || "Universe_#{UUID.uuid4() |> String.slice(0, 8)}"
    
    Logger.info("🌌 [OPC T4] Emitting executable Causal AST for #{id}...")
    
    stability = calculate_base_stability(grammar)
    
    ast = %CausalAST{
      id: id,
      causal_primitives: grammar.causal_primitives,
      interaction_rules: grammar.interaction_rules,
      observer_model: grammar.observer_model,
      entropy_dynamics: grammar.entropy_dynamics,
      time_structure: grammar.time_structure,
      identity_constraints: grammar.identity_constraints,
      stability_score: Float.round(stability, 2)
    }
    
    Logger.info("🌌 [OPC T4] #{id} physics language compiled. Stability Base: #{ast.stability_score}")
    ast
  end

  defp calculate_base_stability(grammar) do
    # A highly active, fluid, non-linear universe is inherently less stable 
    # than a rigid deterministic one.
    base = 100.0
    
    penalty1 = if grammar.time_structure == :bidirectional, do: 20.0, else: 0.0
    penalty2 = if grammar.observer_model == :active_participant, do: 15.0, else: 0.0
    penalty3 = if grammar.interaction_rules == :probabilistic, do: 10.0, else: 0.0
    
    bonus = if :dimensional_compression in grammar.causal_primitives, do: 10.0, else: 0.0
    
    base - penalty1 - penalty2 - penalty3 + bonus
  end
end
