defmodule Tiannara.REL.EconomicOutcome do
  @moduledoc """
  Represents the objective economic facts of a civilization upon dormancy or death.
  Emitted by REL.EconomyEngine for interpretation by the Sentinel Archive.
  """
  defstruct [
    civilization_id: nil,
    shard_id: nil,
    energy: 0,
    dormant: true,
    unstable_discoveries: 0,
    stable_discoveries: 0,
    compute_wasted: 0,
    prediction_accuracy: 0.0,
    disease_count: 0,
    age: 0
  ]
end
