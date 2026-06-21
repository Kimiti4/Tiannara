defmodule Tiannara.OMCS.Milestone do
  @moduledoc """
  Represents a critical event in a civilization's narrative history.
  A sequence of milestones forms the civilization's Narrative Graph.
  """

  @enforce_keys [:id, :type, :timestamp]
  
  defstruct [
    :id,
    :type,           # :founding, :major_discovery, :war, :collapse, :merger, :paradigm_shift
    :timestamp,
    :description,    # String description of the event
    :importance,     # Float 0.0 - 1.0
    :participants,   # List of entity/civilization IDs involved
    :causal_links    # List of milestone IDs that caused this milestone
  ]

  @doc "Create a new milestone."
  def new(type, description, importance \\ 1.0, participants \\ [], causal_links \\ []) do
    %__MODULE__{
      id: generate_id(),
      type: type,
      timestamp: DateTime.utc_now(),
      description: description,
      importance: importance,
      participants: participants,
      causal_links: causal_links
    }
  end

  defp generate_id do
    "milestone:#{System.system_time(:millisecond)}:#{:crypto.strong_rand_bytes(4) |> Base.encode16()}"
  end
end
