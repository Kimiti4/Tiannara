defmodule Tiannara.Sentinel.D2.EcologyRegime do
  @moduledoc """
  D.2 Environmental Memory Layer.
  Tags empirical observations (Species, Breakthroughs, Extinctions) with the active
  environmental conditions to map which archetypes and attractors dominate under which pressures.
  """

  defstruct [
    acm_level: :medium,       # :low, :medium, :high, :extreme
    disease_level: :natural,  # :none, :natural, :aggressive, :pandemic
    resource_level: :balanced # :abundant, :balanced, :scarce, :collapse
  ]

  @type t :: %__MODULE__{
          acm_level: :low | :medium | :high | :extreme,
          disease_level: :none | :natural | :aggressive | :pandemic,
          resource_level: :abundant | :balanced | :scarce | :collapse
        }
end
