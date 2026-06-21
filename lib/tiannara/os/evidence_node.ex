defmodule TiannaraOS.EvidenceNode do
  @moduledoc """
  Represents a single node in the unified Evidence Graph of TiannaraOS.
  Nodes represent theories, claims, hypotheses, experiments, evidence, replications, or discoveries.
  """

  @derive Jason.Encoder
  defstruct [
    :id,              # atom() - unique identifier
    :type,            # atom() - :theory, :claim, etc.
    :name,            # String.t() - name or description
    :value,           # any() - outcome/priority value
    :validity,        # atom() - :valid, :contested, or :invalid
    confidence: 1.0,  # float() - unified global confidence
    utility: 1.0,           # float() - usefulness metric
    justifications: [], # list(atom()) - parent nodes supporting this node (justification chain going upstream)
    dependents: [],     # list(atom()) - child nodes depending on this node (prediction chain going downstream)
    metadata: %{
      provenance: [],
      confidence_history: [],
      last_updated_at: nil,
      relations: %{}  # New field for edge metadata
    }
  ]

  @type t :: %__MODULE__{
    id: atom(),
    type: :theory | :claim | :hypothesis | :experiment | :evidence | :replication | :discovery | :research_program | :institution | :discovery_asset | :world | :tool_genome | :portfolio,
    name: String.t(),
    value: any(),
    validity: :valid | :contested | :invalid,
    confidence: float(),
    utility: float(),
    justifications: [atom()],
    dependents: [atom()],
    metadata: map()
  }
end