defmodule Tiannara.SOPL.MetaRuin do
  @moduledoc """
  SOPL-5: MetaRuin (Meta-Archaeology)
  
  A first-class citizen tracking failed evolutionary algorithms.
  Extremely expensive failures that often contain brilliant, reusable mechanics
  (e.g., a revolutionary pressure strategy that ultimately collapsed).
  """
  defstruct [
    :id,
    :meta_genome_id,
    :collapse_epoch,
    :failure_vector,          # Why did it fail? (e.g. :monoculture, :cognitive_stagnation)
    :salvageable_strategies   # Mechanisms worth preserving (e.g. its pressure_strategy)
  ]
end

defmodule Tiannara.SOPL.MetaInnovation do
  @moduledoc """
  SOPL-5: MetaInnovation
  
  Tracks genuinely new evolutionary mechanisms discovered by the L9 engine.
  """
  defstruct [
    :id,
    :meta_genome_id,
    :strategy_domain,         # e.g., :pressure, :speciation, :recombination
    :novelty_score,           # Distance from known meta-strategies
    :cognitive_yield_bonus    # How much this mechanism tangibly improved downstream cognition
  ]
end
