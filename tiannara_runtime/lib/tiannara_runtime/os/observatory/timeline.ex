defmodule TiannaraRuntime.OS.Observatory.Timeline do
  @moduledoc """
  Mission Timeline

  Spacecraft-style timeline showing:
  Discoveries → Engineering → Optimization → Evolution → Milestones → Certification

  Every significant event is tracked with timestamp and context.
  """

  @type timeline_event :: %{
    timestamp: integer(),
    event_type: atom(),
    description: String.t(),
    data: map()
  }

  @type timeline :: [timeline_event()]

  @doc """
  Initializes an empty timeline.
  """
  @spec initialize() :: timeline()
  def initialize() do
    []
  end

  @doc """
  Adds an event to the timeline from an artifact.
  """
  @spec add_event(timeline(), map()) :: timeline()
  def add_event(timeline, artifact) do
    event = %{
      timestamp: artifact.timestamp,
      event_type: artifact.type,
      description: format_event_description(artifact),
      data: artifact.data
    }

    # Keep timeline sorted by timestamp (newest first)
    [event | timeline]
    |> Enum.sort_by(fn e -> -e.timestamp end)
  end

  @doc """
  Returns all timeline events.
  """
  @spec get_events(timeline()) :: timeline()
  def get_events(timeline) do
    timeline
  end

  @doc """
  Returns events within a time range.
  """
  @spec get_events_in_range(timeline(), integer(), integer()) :: timeline()
  def get_events_in_range(timeline, since, until_ts) do
    timeline
    |> Enum.filter(fn event ->
      event.timestamp >= since and event.timestamp <= until_ts
    end)
  end

  @doc """
  Returns events of a specific type.
  """
  @spec get_events_by_type(timeline(), atom()) :: timeline()
  def get_events_by_type(timeline, event_type) do
    timeline
    |> Enum.filter(fn event ->
      event.event_type == event_type
    end)
  end

  @doc """
  Returns the count of timeline events.
  """
  @spec count(timeline()) :: integer()
  def count(timeline) do
    length(timeline)
  end

  @doc """
  Formats the timeline for display.
  """
  @spec format(timeline()) :: String.t()
  def format(timeline) do
    timeline
    |> Enum.map(fn event ->
      timestamp = format_timestamp(event.timestamp)
      "[#{timestamp}] #{event.event_type}: #{event.description}"
    end)
    |> Enum.join("\n")
  end

  # ── Internal Functions ──────────────────────────────────────

  defp format_event_description(artifact) do
    case artifact.type do
      :observation -> "New observation recorded"
      :hypothesis -> "Hypothesis generated: #{get_in(artifact.data, [:name]) || "unknown"}"
      :experiment -> "Experiment started: #{get_in(artifact.data, [:name]) || "unknown"}"
      :simulation -> "Simulation executed"
      :discovery -> "Discovery validated: #{get_in(artifact.data, [:name]) || "unknown"}"
      :engineering -> "Engineering design created"
      :certification -> "Certification completed"
      :replay -> "Replay verification performed"
      :archaeology -> "Archaeology record created"
      _ -> "Artifact recorded"
    end
  end

  defp format_timestamp(timestamp) do
    DateTime.from_unix!(timestamp, :millisecond)
    |> DateTime.to_string()
  end
end
