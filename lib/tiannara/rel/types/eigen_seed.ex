defmodule Tiannara.REL.Types.EigenSeed do
  @moduledoc """
  A lossy, compressed representation of an extinct civilization.
  Preserves attractors (domain affinities) for procedural re-emergence.
  """
  
  @type t :: %__MODULE__{
    id: String.t(),
    source_closure_id: String.t(),
    epistemic_signature: %{
      empiricism_bias: float(),
      abstraction_bias: float(),
      novelty_seeking: float(),
      contradiction_tolerance: float()
    },
    domain_affinities: %{atom() => float()},
    collapse_signature: atom(),
    fitness_profile: float(),
    latent_weight: float(),
    historical_disease_resistance: %{atom() => integer()},
    created_at: integer()
  }

  @enforce_keys [:id, :source_closure_id]
  defstruct [
    :id,
    :source_closure_id,
    epistemic_signature: %{
      empiricism_bias: 0.0,
      abstraction_bias: 0.0,
      novelty_seeking: 0.0,
      contradiction_tolerance: 0.0
    },
    domain_affinities: %{},
    collapse_signature: nil,
    fitness_profile: 0.0,
    latent_weight: 0.0,
    historical_disease_resistance: %{},
    created_at: nil
  ]
end
