defmodule Tiannara.Sentinel.Observation do
  @moduledoc """
  Data types for the Universal Observation System.
  Defines observation streams (health, event, metric) and their structure.
  """

  defstruct [
    :id,
    :type,
    :subsystem,
    :timestamp,
    :data,
    :confidence,
    :stream,
    :tags,
    :metadata
  ]

  @type stream_type :: :health | :event | :metric
  @type t :: %__MODULE__{
          id: String.t(),
          type: stream_type(),
          subsystem: atom(),
          timestamp: DateTime.t(),
          data: map(),
          confidence: float(),
          stream: String.t(),
          tags: list(String.t()),
          metadata: map()
        }

  @doc """
  Creates a new observation with auto-generated ID and current timestamp.
  """
  def new(type, subsystem, data, opts \\ []) do
    %__MODULE__{
      id: Map.get(opts, :id, "#{subsystem}_#{type}_#{System.unique_integer([:positive])}"),
      type: type,
      subsystem: subsystem,
      timestamp: DateTime.utc_now(),
      data: data,
      confidence: Map.get(opts, :confidence, 1.0),
      stream: Map.get(opts, :stream, observation_stream(type, subsystem)),
      tags: Map.get(opts, :tags, []),
      metadata: Map.get(opts, :metadata, %{})
    }
  end

  @doc """
  Determines the default stream name for a given type and subsystem.
  """
  def observation_stream(:health, subsystem), do: "health:#{subsystem}"
  def observation_stream(:event, subsystem), do: "event:#{subsystem}"
  def observation_stream(:metric, subsystem), do: "metric:#{subsystem}"
  def observation_stream(_, subsystem), do: "stream:#{subsystem}"
end
