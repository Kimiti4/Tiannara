defmodule Tiannara.OPC.CausalSegmenter do
  @moduledoc """
  Phase 5F.9 — Causal segmenter.
  Builds causal chains from ordered event histories.
  """

  def segment(events) when is_list(events) do
    events
    |> Enum.sort_by(& &1.timestamp)
    |> Enum.chunk_while([], &chunker/2, &finish_chunk/1)
  end

  defp chunker(event, []), do: {:cont, [event]}

  defp chunker(event, [previous | _] = acc) do
    if causal?(previous, event) do
      {:cont, [event | acc]}
    else
      {:cont, Enum.reverse(acc), [event]}
    end
  end

  defp finish_chunk([]), do: {:cont, []}
  defp finish_chunk(acc), do: {:cont, Enum.reverse(acc), []}

  defp causal?(a, b) do
    a.type == b.type or abs(a.timestamp - b.timestamp) < 1_000_000
  end
end
