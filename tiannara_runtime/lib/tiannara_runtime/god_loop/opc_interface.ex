defmodule Tiannara.GodLoop.OPCInterface do
  @moduledoc """
  God-Loop: OPC Interface.
  
  Bridge allowing MCAL's new reasoning modes to rewrite OPC's causal laws 
  and physics bounds.
  """
  
  require Logger

  alias Tiannara.OPC.T4.{PhysicsGrammarGenerator, MutationCompiler, ParadoxResolver, UniverseASTEmitter}

  @doc """
  Mutates OPC causal physics based on MCAL cognition and CIS gradients.
  Now utilizes the Tier 4 Compiler to generate full Causal ASTs.
  """
  def mutate(opc_state, _mc_state, gradients) do
    Logger.debug("🌌 [God-Loop OPC Interface] Intercepting thermodynamic pressure...")
    
    # Generate base grammar
    base = PhysicsGrammarGenerator.generate_base()
    
    # Push gradient pressure into the compiler
    compiled_grammar = MutationCompiler.compile(base, gradients)
    
    # Resolve paradoxes to prevent annihilation
    resolved_grammar = ParadoxResolver.resolve(compiled_grammar)
    
    # Emit full executable Universe AST
    universe_ast = UniverseASTEmitter.emit(resolved_grammar)
    
    # Store the generated physics AST in the OPC state
    new_state = Map.put(opc_state, :active_physics_ast, universe_ast)
    
    new_state
  end
end
