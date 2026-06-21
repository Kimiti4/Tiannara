defmodule Tiannara.ROS.CivilizationRuin do
  @moduledoc """
  A fossilized remnant of a civilization that has died or migrated.
  Preserves historical data for LEOC, ECL, and ACM layers without executing logic.
  """

  @enforce_keys [
    :original_civ_id,
    :shard_id,
    :ruin_reason
  ]
  
  defstruct [
    :original_civ_id,      # ID of the civilization
    :shard_id,             # The shard this ruin exists in
    :ruin_reason,          # :migration, :collapse, :fission
    :identity_seed,        # The %IdentitySeed{} captured at the time of ruination
    :active,               # Always false for a ruin
    :created_at            # DateTime
  ]

  alias Tiannara.OMCS.IdentitySeed

  @doc "Fossilize a civilization into a ruin."
  def create(shard_id, civ_id, reason, %IdentitySeed{} = seed) do
    %__MODULE__{
      original_civ_id: civ_id,
      shard_id: shard_id,
      ruin_reason: reason,
      identity_seed: seed,
      active: false,
      created_at: DateTime.utc_now()
    }
  end
end
