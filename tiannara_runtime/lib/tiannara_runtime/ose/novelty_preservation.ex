defmodule Tiannara.OSE.NoveltyPreservation do
  @moduledoc """
  Ontological Selection Ecology: Novelty Preservation.
  
  The biodiversity reserve. Guarantees rare physics grammars are not extinguished,
  subsidizing them with the `Diversity Reserve` budget.
  """
  
  require Logger

  @diversity_reserve_budget 50.0

  @doc """
  Evaluates active universes and applies a diversity subsidy to rare ontologies.
  """
  def apply_subsidy(universes) do
    Logger.debug("🌱 [OSE] Evaluating ecological biodiversity...")
    
    # Identify the universe with the most unique primitives
    rarest = Enum.max_by(universes, fn u ->
      Enum.count(u.causal_primitives, fn p ->
        Enum.all?(universes -- [u], fn o -> p not in o.causal_primitives end)
      end)
    end, fn -> nil end)
    
    if rarest do
      Logger.info("🌱 [OSE] Novelty Preservation: #{rarest.id} contains rare primitives. Applying Diversity Subsidy.")
      Enum.map(universes, fn u ->
        if u.id == rarest.id do
          Map.put(u, :budget, u.budget + @diversity_reserve_budget)
        else
          u
        end
      end)
    else
      universes
    end
  end
end
