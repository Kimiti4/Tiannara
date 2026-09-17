defmodule Tiannara.OSE.CrossOntologyTranslation do
  @moduledoc """
  Ontological Selection Ecology: Cross-Ontology Translation.
  
  Calculates partial interoperability between incompatible physics grammars,
  preventing complete semantic isolation.
  """

  require Logger

  @doc """
  Calculates the interoperability score between two active universes.
  """
  def calculate_interoperability(u1, u2) do
    Logger.debug("🔗 [OSE] Translating semantics between #{u1.id} and #{u2.id}...")
    
    # Calculate shared primitives and topology compatibility
    shared_prims = Enum.count(u1.causal_primitives, &(&1 in u2.causal_primitives))
    time_compat = if u1.time_structure == u2.time_structure, do: 10.0, else: 0.0
    
    score = (shared_prims * 5.0) + time_compat
    
    Logger.debug("🔗 [OSE] Interoperability index: #{Float.round(score, 2)}")
    score
  end
end
