defmodule Tiannara.Domains.Domain do
  @moduledoc """
  Represents a domain research lens in Tiannara.
  Fields are static; all scores and analytics are projected dynamically from the Knowledge Graph.
  """
  @derive Jason.Encoder
  defstruct [
    :id,           # atom (e.g., :engineering)
    :name,         # string
    :description,  # string
    :program_ids,  # list of program ID strings
    :status        # :active | :hypothetical
  ]
end
