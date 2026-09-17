defmodule Tiannara.CLSL.Compiler do
  @moduledoc """
  Causal Language Standardization Layer: Compiler.
  
  Compiles OPC Tier 4 Causal ASTs into unified CLSL IR, while
  explicitly tracking translation loss to avoid destroying ontology diversity.
  """
  
  require Logger
  alias Tiannara.CLSL.{IR, IRTranslationLoss}

  @doc """
  Compiles a CausalAST into a CLSL IR.
  """
  def compile(universe_ast) do
    Logger.debug("🔌 [CLSL] Compiling Causal AST #{universe_ast.id} into Universal IR...")
    
    # Analyze translation loss (what cannot be cleanly mapped)
    loss = calculate_translation_loss(universe_ast)
    
    ir = %IR{
      id: universe_ast.id,
      time_model: map_time(universe_ast.time_structure),
      identity_model: map_identity(universe_ast.identity_constraints),
      entropy_model: universe_ast.entropy_dynamics,
      physics_bindings: map_physics(universe_ast),
      observer_model: universe_ast.observer_model,
      recursion_model: :bounded, # Inferred baseline
      topology_model: :manifold, # Inferred baseline
      causal_resolution_model: universe_ast.interaction_rules,
      translation_loss: loss
    }
    
    if loss.semantic_loss > 0.0 or length(loss.untranslated_primitives) > 0 do
      Logger.warning("🔌 [CLSL] Translation Loss Detected for #{ir.id}: Semantic=#{loss.semantic_loss}, Untranslated=#{inspect(loss.untranslated_primitives)}")
    else
      Logger.info("🔌 [CLSL] #{ir.id} successfully compiled to IR with zero translation loss.")
    end
    
    ir
  end

  defp calculate_translation_loss(ast) do
    # Exotic primitives that CLSL standard bindings cannot perfectly capture
    untranslated = Enum.filter(ast.causal_primitives, fn p ->
      p in [:dimensional_compression, :quantum_entanglement, :holographic_locality]
    end)
    
    %IRTranslationLoss{
      semantic_loss: length(untranslated) * 15.0,
      causal_loss: if(:holographic_locality in untranslated, do: 20.0, else: 0.0),
      observer_loss: if(ast.observer_model == :active_participant, do: 10.0, else: 0.0),
      topology_loss: if(:dimensional_compression in untranslated, do: 25.0, else: 0.0),
      untranslated_primitives: untranslated
    }
  end

  defp map_time(:bidirectional), do: :branching_recursive
  defp map_time(other), do: other

  defp map_identity(:fluid), do: :observer_dependent
  defp map_identity(other), do: other

  defp map_physics(ast) do
    %{
      gravity: :information_density_gradient,
      causality: if(ast.interaction_rules == :probabilistic, do: :probabilistic_consistency_field, else: :strict_determinism)
    }
  end
end
