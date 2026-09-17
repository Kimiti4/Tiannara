defprotocol TiannaraRuntime.WorldModel.Composition.Behaviours.GraphRepresentable do
  @moduledoc """
  Phase 17.6.1 — GraphRepresentable protocol.
  Describes how a world model or component renders itself as nodes/edges in the world graph.
  """

  @doc "Converts this component to a list of WorldNode structs."
  def to_nodes(component)

  @doc "Converts this component to a list of WorldEdge structs."
  def to_edges(component)

  @doc "Returns the component's dependencies as node IDs."
  def dependencies(component)
end
