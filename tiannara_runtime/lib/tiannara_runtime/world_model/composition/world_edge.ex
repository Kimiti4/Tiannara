defmodule TiannaraRuntime.WorldModel.Composition.WorldEdge do
  @moduledoc """
  Phase 17.6.1 — WorldEdge struct.
  An edge in the world graph representing a relationship between components.
  Fields: edge_id, source_id, target_id, type, weight, metadata.
  """
  defstruct [:edge_id, :source_id, :target_id, :type, :weight, :metadata]

  @type edge_type ::
          :dependency | :causality | :synchronization
          | :composition | :ownership

  @type t :: %__MODULE__{
          edge_id: String.t() | nil,
          source_id: String.t() | nil,
          target_id: String.t() | nil,
          type: edge_type() | nil,
          weight: float() | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash =
      :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "we_" <> hash
  end
end
