defmodule Tiannara.KnowledgeGraph.Node do
  @moduledoc """
  Represents a generic node in the unified scientific knowledge graph.
  Types can be: :principle, :theory, :law, :discovery, :intervention, :outcome.
  """
  @derive Jason.Encoder
  defstruct [
    :id,
    :type,        # :principle | :theory | :law | :discovery | :intervention | :outcome
    :name,
    :description,
    :domains,     # list of domain IDs (atoms or strings)
    parents: [],  # list of parent node IDs
    children: [], # list of child node IDs
    metadata: %{},# map of custom metadata (e.g., %{confidence: 0.82, status: :validated})
    timestamp: nil
  ]
end
