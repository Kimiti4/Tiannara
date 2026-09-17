defmodule Tiannara.OPC.CanonicalAST do
  @moduledoc """
  Stage 4: OPC Canonical AST Generator
  
  The absolute sovereign translation layer. Python never submits an AST.
  Python submits a declarative PIS. This module uses pattern matching to
  translate strict PIS categories/interactions into safe, canonical ASTs
  that the underlying OPC compiler (`ObserverPhysicsCompiler`) can deploy.
  """
  
  require Logger
  
  @doc """
  Translates a constitutionally verified PIS map into a Canonical AST.
  """
  def generate_ast(pis_map) do
    Logger.info("[OPC] Generating Canonical AST for PIS #{pis_map["intent_id"]}")
    
    category = pis_map["category"]
    interaction = String.downcase(pis_map["interaction"])
    
    # We use strict pattern matching to define the authorized physical mechanics
    ast = build_canonical_mechanics(category, interaction)
    
    if ast == :unauthorized_mechanics do
      Logger.error("[OPC] AST Generation Failed: No canonical mapping for #{category}/#{interaction}")
      {:error, :unauthorized_physics_mechanics}
    else
      # Inject the temporal decay constraint directly into the AST root
      decay_ticks = pis_map["law_decay"]["half_life_ticks"]
      final_ast = {:with_decay, decay_ticks, ast}
      
      Logger.debug("[OPC] Successfully generated canonical AST.")
      {:ok, final_ast}
    end
  end
  
  # ── Canonical AST Templates ───────────────────────────────────────────────
  
  defp build_canonical_mechanics("semantic", "attract") do
    # Semantic attraction: Strength increases as distance decreases
    {:op, :+, [
      {:var, :baseline_semantic_gravity},
      {:op, :/, [
        {:const, 1.0},
        {:op, :pow, [{:var, :semantic_distance}, {:const, 2.0}]}
      ]}
    ]}
  end
  
  defp build_canonical_mechanics("semantic", "repel") do
    # Semantic repulsion: Force pushes away based on inverse distance
    {:op, :*, [
      {:const, -1.0},
      {:op, :/, [
        {:const, 1.0},
        {:var, :semantic_distance}
      ]}
    ]}
  end
  
  defp build_canonical_mechanics("causal", "accelerate") do
    # Causal acceleration: Increase tick rate locally
    {:op, :*, [
      {:var, :local_tick_rate},
      {:const, 1.15}
    ]}
  end
  
  defp build_canonical_mechanics("topological", "merge") do
    # Topological merge: Decrease edge resistance
    {:op, :/, [
      {:var, :edge_resistance},
      {:const, 2.0}
    ]}
  end
  
  # Fallback for unrecognized intents
  defp build_canonical_mechanics(_, _), do: :unauthorized_mechanics
  
end
