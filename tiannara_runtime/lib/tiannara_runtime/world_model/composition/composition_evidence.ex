defmodule TiannaraRuntime.WorldModel.Composition.CompositionEvidence do
  @moduledoc """
  Phase 17.6.1 — CompositionEvidence struct.
  Records the evidence lineage of a composition.
  Fields: evidence_id, composition_id, model_roots, interface_hashes, sync_hashes,
          math_verification, replay_attempts, metadata.
  """
  defstruct [
    :evidence_id, :composition_id, :model_roots, :interface_hashes,
    :sync_hashes, :math_verification, :replay_attempts, :metadata
  ]

  @type t :: %__MODULE__{
          evidence_id: String.t() | nil,
          composition_id: String.t() | nil,
          model_roots: [String.t()] | nil,
          interface_hashes: [String.t()] | nil,
          sync_hashes: [String.t()] | nil,
          math_verification: String.t() | nil,
          replay_attempts: [map()] | nil,
          metadata: map() | nil
        }
end
