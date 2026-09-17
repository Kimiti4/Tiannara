defmodule TiannaraRuntime.WorldModel.Composition.WorldNode do
  @moduledoc """
  Phase 17.6.1 — WorldNode struct.
  A node in the world graph representing a component of a composed world model.
  Fields: node_id, type, label, properties, metadata.
  """
  defstruct [:node_id, :type, :label, :properties, :metadata]

  @type node_type ::
          :world_model | :variable | :equation | :causal_graph
          | :evidence | :prediction | :counterfactual

  @type t :: %__MODULE__{
          node_id: String.t() | nil,
          type: node_type() | nil,
          label: String.t() | nil,
          properties: map() | nil,
          metadata: map() | nil
        }
end
