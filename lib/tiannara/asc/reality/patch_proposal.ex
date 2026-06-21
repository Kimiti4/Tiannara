defmodule Tiannara.ASC.Reality.PatchProposal do
  @moduledoc """
  Phase 8B: Represents a formal proposal to modify actual source code.
  Ensures the system does not mutate production code arbitrarily.
  """
  
  defstruct [
    :id,
    :target_file,
    :target_pattern,
    :replacement_content,
    :purpose,
    :source_genome_id,
    :status
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    target_file: String.t(),
    target_pattern: String.t(),
    replacement_content: String.t(),
    purpose: String.t(),
    source_genome_id: String.t(),
    status: :pending | :applied | :rejected | :committed
  }
end
