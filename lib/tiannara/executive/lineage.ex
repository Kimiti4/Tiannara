defmodule Tiannara.Executive.Lineage do
  @moduledoc """
  Knowledge ancestry tracking for Executive Memory.

  Tracks how each piece of knowledge was derived, who created it,
  and what evidence level supports it.
  """

  defstruct [:id, :parent_id, :evidence_level, :evidence_type, :created_by, :created_at, :metadata]

  @evidence_types [:fact, :evidence, :assumption, :hypothesis, :validated, :principle]
  @evidence_min 0.1

  @type evidence_type :: :fact | :evidence | :assumption | :hypothesis | :validated | :principle

  @type t :: %__MODULE__{
    id: String.t(),
    parent_id: String.t() | nil,
    evidence_level: Tiannara.Executive.Types.evidence_level(),
    evidence_type: evidence_type(),
    created_by: String.t(),
    created_at: DateTime.t(),
    metadata: map()
  }

  @doc "Creates a new lineage record for a memory entry."
  def new(created_by, evidence_type \\ :hypothesis) do
    evidence_type = if evidence_type in @evidence_types, do: evidence_type, else: :hypothesis
    %__MODULE__{
      id: Tiannara.Executive.Types.new_id(),
      parent_id: nil,
      evidence_level: initial_level(evidence_type),
      evidence_type: evidence_type,
      created_by: created_by,
      created_at: DateTime.utc_now(),
      metadata: %{}
    }
  end

  @doc "Derives a new lineage from a parent lineage."
  def derive(%__MODULE__{} = parent, created_by, evidence_type \\ :evidence) do
    evidence_type = if evidence_type in @evidence_types, do: evidence_type, else: :evidence
    %__MODULE__{
      id: Tiannara.Executive.Types.new_id(),
      parent_id: parent.id,
      evidence_level: min(parent.evidence_level + 0.1, 1.0),
      evidence_type: evidence_type,
      created_by: created_by,
      created_at: DateTime.utc_now(),
      metadata: %{derived_from: parent.id}
    }
  end

  @doc "Validates that a lineage meets the minimum evidence threshold."
  def valid?(%__MODULE__{evidence_level: level}) when level >= @evidence_min, do: true
  def valid?(_), do: false

  @doc "Converts lineage to a storage record."
  def to_record(%__MODULE__{} = l) do
    {{:lineage, l.id}, l}
  end

  defp initial_level(:fact), do: 1.0
  defp initial_level(:evidence), do: 0.7
  defp initial_level(:validated), do: 0.9
  defp initial_level(:principle), do: 1.0
  defp initial_level(:hypothesis), do: 0.3
  defp initial_level(:assumption), do: 0.1
end
