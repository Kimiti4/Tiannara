defmodule TiannaraRuntime.WorldModel.Composition.ComposedWorldModel do
  @moduledoc """
  Phase 17.6.1 — ComposedWorldModel struct.
  A deterministic composition of multiple certified world models.
  Fields: composition_id, name, parent_model_ids, world_graph, shared_variables,
          sync_rules, interfaces, evidence_roots, replay_fingerprint, archaeology_root,
          certificate, created_at.
  """
  defstruct [
    :composition_id, :name, :parent_model_ids, :world_graph,
    :shared_variables, :sync_rules, :interfaces,
    :evidence_roots, :replay_fingerprint, :archaeology_root,
    :certificate, :created_at
  ]

  @type composition_id :: String.t()
  @type t :: %__MODULE__{
          composition_id: composition_id | nil,
          name: String.t() | nil,
          parent_model_ids: [String.t()] | nil,
          world_graph: TiannaraRuntime.WorldModel.Composition.WorldGraph.t() | nil,
          shared_variables: [TiannaraRuntime.WorldModel.Composition.SharedVariable.t()] | nil,
          sync_rules: [TiannaraRuntime.WorldModel.Composition.SynchronizationRule.t()] | nil,
          interfaces: [TiannaraRuntime.WorldModel.Composition.DomainInterface.t()] | nil,
          evidence_roots: [String.t()] | nil,
          replay_fingerprint: String.t() | nil,
          archaeology_root: String.t() | nil,
          certificate: TiannaraRuntime.WorldModel.Composition.CompositionCertificate.t() | nil,
          created_at: String.t() | nil
        }

  @doc """
  Generates a content-addressed composition_id using SHA-256 over canonical form.
  """
  def generate_id(canonical) when is_map(canonical) do
    hash =
      :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "cw_" <> hash
  end
end
