defmodule Tiannara.Graph.Edge do
  @moduledoc """
  A directed edge in the reality graph. Preserves metadata so lineage /
  blast-radius / causal / contradiction analysis work unchanged.

  Constitutional basis: "Preserve lineage", "Maintain audit trails".
  """

  @enforce_keys [:id, :from, :to]
  defstruct [:id, :from, :to, :label, :metadata]

  @type t :: %__MODULE__{
    id: term(),
    from: term(),
    to: term(),
    label: term() | nil,
    metadata: map() | nil
  }
end