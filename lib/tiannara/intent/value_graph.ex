defmodule Tiannara.Intent.ValueGraph do
  @moduledoc """
  Phase 19: Represents the latent human values, ethical boundaries, 
  and long-term purpose behind a stated objective.
  """
  defstruct [
    :stated_goal,          # "Increase engagement"
    :latent_values,        # ["User satisfaction", "Long-term retention", "Trust"]
    :anti_values,          # ["Addiction", "Dark patterns", "Data exploitation"]
    :betrayal_conditions   # "If users spend more time but report lower happiness, the goal is betrayed."
  ]
end
