defmodule Tiannara.World.GraphAdapter do
  @moduledoc """
  Graph Adapter Behaviour — contract for pluggable graph data sources.

  Each external graph (Agency RealityGraph, legacy world models, etc.) must
  implement an adapter that exposes its entities in a format compatible with
  the UnifiedRealityGraph for the RealityCoordinator.

  Callbacks:
    - `pull_graph/2` — fetch entities since a given offset
    - `push_entity/2` — push a single entity back to the source
    - `current_offset/1` — latest available offset for incremental sync
    - `metadata/0` — adapter metadata for observability
  """

  @type entity :: %{
          id: String.t(),
          type: atom(),
          subtype: atom() | nil,
          attributes: map(),
          confidence: float(),
          uncertainty: float(),
          provenance: map() | nil,
          relationships: [map()]
        }

  @doc "Pulls all entities since the given offset. Returns entities and the new offset."
  @callback pull_graph(opts :: map(), offset :: term()) ::
              {:ok, %{entities: [entity()], offset: term()}} | {:error, term()}

  @doc "Pushes a single entity back to the source graph."
  @callback push_entity(entity :: entity(), opts :: map()) :: {:ok, term()} | {:error, term()}

  @doc "Returns the current offset of the source graph for incremental sync."
  @callback current_offset(opts :: map()) :: {:ok, term()} | {:error, term()}

  @doc "Returns metadata about the adapter for observability."
  @callback metadata() :: %{optional(atom()) => term()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Tiannara.World.GraphAdapter
    end
  end
end
