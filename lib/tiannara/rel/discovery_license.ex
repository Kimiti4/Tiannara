defmodule Tiannara.REL.DiscoveryLicense do
  @moduledoc """
  Represents a licensing agreement between two civilizations for a discovery.
  If the licensee loses the discovery (e.g. through shedding during starvation),
  the license automatically terminates.
  """

  @enforce_keys [:id, :discovery_id, :owner_civ_id, :licensee_civ_id, :cost_per_tick]
  defstruct [
    :id,
    :discovery_id,
    :owner_civ_id,
    :licensee_civ_id,
    :cost_per_tick, # e.g. %{energy: 5}
    active: true,
    created_at: nil
  ]

  def new(owner_id, licensee_id, discovery_id, cost_map) do
    %__MODULE__{
      id: "lic:#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
      discovery_id: discovery_id,
      owner_civ_id: owner_id,
      licensee_civ_id: licensee_id,
      cost_per_tick: cost_map,
      created_at: DateTime.utc_now()
    }
  end
end
