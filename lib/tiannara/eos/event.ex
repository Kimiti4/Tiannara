defmodule Tiannara.EOS.Event do
  @moduledoc """
  Base event struct for the EOS domain buses.

  Every event has a type, source, payload, and correlation_id for lineage tracing.
  """

  @enforce_keys [:type, :source, :payload]
  defstruct [
    :type,
    :source,
    :payload,
    correlation_id: nil,
    occurred_at: nil,
    schema_version: 1
  ]

  @type t :: %__MODULE__{}

  def new(type, source, payload, opts \\ []) do
    %__MODULE__{
      type: type,
      source: source,
      payload: payload,
      correlation_id: opts[:correlation_id] || Ecto.UUID.generate(),
      occurred_at: opts[:occurred_at] || DateTime.utc_now(),
      schema_version: opts[:schema_version] || 1
    }
  end

  def validate(%__MODULE__{} = event) do
    cond do
      not is_binary(event.type) -> {:error, :invalid_type}
      event.source == nil -> {:error, :missing_source}
      not is_map(event.payload) -> {:error, :invalid_payload}
      true -> :ok
    end
  end
end
