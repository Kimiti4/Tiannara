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
      correlation_id: opts[:correlation_id] || generate_uuid_v4(),
      occurred_at: opts[:occurred_at] || DateTime.utc_now(),
      schema_version: opts[:schema_version] || 1
    }
  end

  # RFC 4122 v4 UUID via :crypto — replaces Ecto.UUID.generate/0, which was an
  # UndefinedFunctionError waiting to happen (ecto is not a dependency).
  defp generate_uuid_v4 do
    <<a::48, _::4, b::12, _::2, c::62>> = :crypto.strong_rand_bytes(16)

    <<a::48, 4::4, b::12, 2::2, c::62>>
    |> Base.encode16(case: :lower)
    |> binary_insert_dashes()
  end

  defp binary_insert_dashes(
         <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
           e::binary-size(12)>>
       ),
       do: "#{a}-#{b}-#{c}-#{d}-#{e}"

  def validate(%__MODULE__{} = event) do
    cond do
      not is_binary(event.type) -> {:error, :invalid_type}
      event.source == nil -> {:error, :missing_source}
      not is_map(event.payload) -> {:error, :invalid_payload}
      true -> :ok
    end
  end
end
