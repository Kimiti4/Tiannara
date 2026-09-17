defmodule Tiannara.OSE.OntologyQuarantine do
  @moduledoc """
  Ontological Selection Ecology: Ontology Quarantine.
  
  Prevents malicious or unstable grammars (paradox exploits, recursion bombs)
  from contaminating the broader ecology.
  """
  
  require Logger

  @doc """
  Inspects universes before they enter the causal sandbox.
  """
  def inspect(universe) do
    Logger.debug("🛡️ [OSE] Quarantine scanning ontology #{universe.id} for paradox exploits...")
    
    if :dimensional_compression in universe.causal_primitives and universe.time_structure == :bidirectional do
      Logger.warning("🛡️ [OSE] Quarantine triggered for #{universe.id}: Time-Compression recursion bomb detected! Stripping bidirectional time.")
      %{universe | time_structure: :unidirectional}
    else
      universe
    end
  end
end
