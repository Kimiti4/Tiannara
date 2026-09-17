defmodule Tiannara.SCL.AxiomDiversityPreserver do
  @moduledoc """
  Meta-Theory of Everything Compiler: Axiom Diversity Preserver.
  
  Prevents over-canonicalization, attractor collapse, and axiom monoculture
  during SCL compression. Ensures the M-TOE remains generative, not reductive.
  """
  
  require Logger

  @doc """
  Injects un-translatable or exotic semantics back into the generative axioms 
  to ensure maximum generative diversity under bounded compression.
  """
  def preserve(axioms, ir_list) do
    Logger.debug("🧬 [SCL] Preserving Axiom Diversity against monoculture compression...")
    
    # Collect all untranslated primitives from translation loss across all IRs
    exotic_primitives = 
      ir_list
      |> Enum.flat_map(fn ir -> ir.translation_loss.untranslated_primitives end)
      |> Enum.uniq()
      
    if length(exotic_primitives) > 0 do
      Logger.info("🧬 [SCL] Axiom Diversity Preserver injected exotic seeds: #{inspect(exotic_primitives)}")
      axioms ++ exotic_primitives
    else
      axioms
    end
  end
end
