defmodule Tiannara.OrbitState do
  @moduledoc """
  Represents a snapshotted orbit state for a given civilization at an epoch in a trajectory.
  """
  @derive Jason.Encoder
  defstruct [
    :orbit_id,              # atom (e.g. :stability_orbit, :collapse_recovery_orbit, :other_orbit_0, :other_orbit_1)
    :orbit_name,            # String representation
    :gsi,                   # float
    :agency,                # float
    :robustness,            # float
    :generativity,          # float
    :identity_persistence,  # float
    :world_id,              # String
    :civilization_id,       # String
    :epoch,                 # integer
    :trajectory_id          # String
  ]
end
