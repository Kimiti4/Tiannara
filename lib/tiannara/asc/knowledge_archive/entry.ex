defmodule Tiannara.ASC.KnowledgeArchive.Entry do
  @moduledoc "A single knowledge archive entry."

  @derive Jason.Encoder
  defstruct [
    :id,
    :type,        # :architecture | :failure | :success | :test | :incident | :api | :repair | :optimization | :insight | :law
    :project_id,
    :content,
    :tags,
    :confidence,
    :kg_node_id,  # linked KnowledgeGraph node ID after promotion
    :created_at
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    type: atom(),
    project_id: String.t() | nil,
    content: map(),
    tags: [String.t()],
    confidence: float(),
    kg_node_id: String.t() | nil,
    created_at: DateTime.t() | nil
  }
end
