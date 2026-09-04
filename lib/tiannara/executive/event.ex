defmodule Tiannara.Executive.Event do
  @moduledoc """
  Immutable event records for the Executive Memory event system.

  Events form an append-only log of all significant state changes,
  decisions, and system occurrences.
  """

  defstruct [:id, :type, :data, :timestamp, :metadata]

  @type t :: %__MODULE__{
    id: String.t(),
    type: String.t(),
    data: map(),
    timestamp: DateTime.t(),
    metadata: map()
  }

  @doc "Creates a new event."
  def new(type, data, metadata \\ %{}) do
    %__MODULE__{
      id: Tiannara.Executive.Types.new_id(),
      type: type,
      data: data,
      timestamp: DateTime.utc_now(),
      metadata: metadata
    }
  end

  @doc "Serializes an event to a binary."
  def to_binary(%__MODULE__{} = event) do
    :erlang.term_to_binary(event)
  end

  @doc "Deserializes a binary to an event."
  def from_binary(bin) do
    :erlang.binary_to_term(bin)
  end

  @doc "Returns a human-readable description of the event."
  def describe(%__MODULE__{type: type, data: data}) do
    "[#{type}] #{inspect(data)}"
  end
end
