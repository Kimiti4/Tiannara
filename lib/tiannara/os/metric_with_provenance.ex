defmodule TiannaraOS.MetricWithProvenance do
  @moduledoc """
  Wraps computed metrics with a provenance mapping tracing back to the number
  of active theories, evidence, replication, and repository worlds.
  """

  @derive Jason.Encoder
  defstruct [
    :value,             # float() | any()
    provenance: %{      # map()
      theories_count: 0,
      evidence_nodes_count: 0,
      replication_events_count: 0,
      repository_worlds_count: 0
    }
  ]

  @type t :: %__MODULE__{
    value: float() | any(),
    provenance: %{
      theories_count: integer(),
      evidence_nodes_count: integer(),
      replication_events_count: integer(),
      repository_worlds_count: integer()
    }
  }

  @doc """
  Constructs a provenance-traced metric from the active State.
  """
  def from_state(value, state) do
    theories_count = Map.size(state.theories)
    
    evidence_nodes_count =
      state.evidence_graph
      |> Map.values()
      |> Enum.count(fn node -> node.type == :evidence end)

    replication_events_count =
      state.evidence_graph
      |> Map.values()
      |> Enum.count(fn node -> 
        node.type == :replication or Map.get(node.metadata, :source) == :replication 
      end)

    repository_worlds_count =
      state.worlds
      |> Map.values()
      |> Enum.count(fn w -> Map.get(w, :twin) != nil end)

    %__MODULE__{
      value: value,
      provenance: %{
        theories_count: theories_count,
        evidence_nodes_count: evidence_nodes_count,
        replication_events_count: replication_events_count,
        repository_worlds_count: repository_worlds_count
      }
    }
  end
end
