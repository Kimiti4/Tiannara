defmodule Tiannara.OSE.Evolution.CausalSpeciationEngine do
  @moduledoc """
  Ontological Selection Ecology: Causal Speciation Engine (CSE).
  
  Hybridizes successful grammars into descendant causal species.
  Bound to CTL: speciation must remain partially invertible or traceably reducible.
  """
  
  require Logger
  alias Tiannara.OPC.T4.CausalAST

  @doc """
  Attempts to hybridize two viable ASTs into a new descendant ontology species.
  """
  def speciate(ast1, ast2) do
    Logger.debug("🌿 [CSE] Attempting causal speciation between #{ast1.id} and #{ast2.id}...")
    
    # 1. Speciation Validity Constraint (CTL bound)
    # Check if the combined primitives are traceably reducible.
    # We reject speciation if both universes have strictly opposing, non-reducible core topologies.
    if :linear_time in ast1.causal_primitives and :bidirectional in ast2.causal_primitives do
      Logger.warning("🌿 [CSE] Speciation Rejected: Irreducible causal incompatibility (Time Topology).")
      nil
    else
      # 2. Hybridization
      hybrid_primitives = Enum.uniq(ast1.causal_primitives ++ ast2.causal_primitives)
      
      descendant = %CausalAST{
        id: "Species_#{:crypto.hash(:md5, ast1.id <> ast2.id) |> Base.encode16(case: :lower) |> binary_part(0, 8)}",
        causal_primitives: hybrid_primitives,
        interaction_rules: ast1.interaction_rules, # Inherit base physics from ast1
        observer_model: ast2.observer_model,       # Inherit observer from ast2
        entropy_dynamics: :feedback_stabilized,    # Hybrid stabilization
        time_structure: ast1.time_structure,
        identity_constraints: :fluid,
        stability_score: 50.0 # Base for new species
      }
      
      Logger.info("🌿 [CSE] Speciation Successful: Descendant #{descendant.id} created. Traceable to parents.")
      descendant
    end
  end
end
