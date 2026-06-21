defmodule Tiannara.ASC.Laws.Experiment do
  @moduledoc """
  Phase 5F: Represents a scientifically designed experiment containing conditions
  that will be executed by the standard transfer machinery.
  """

  @enforce_keys [:bucket, :repetitions]
  defstruct [
    :bucket,            # e.g., {:security, :data, :far}
    :repetitions,       # Number of synthetic transfers to run
    :source_domain,
    :target_domain,
    :semantic_distance,
    :adaptation_strategy
  ]
end
