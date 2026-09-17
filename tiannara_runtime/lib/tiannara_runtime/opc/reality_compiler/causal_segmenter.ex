defmodule Tiannara.OPC.RealityCompiler.CausalSegmenter do

  def segment(events) do
    events
    |> Enum.sort_by(& &1.timestamp)
    |> group_by_causality()
  end

  defp group_by_causality(events) do
    Enum.chunk_while(events, [], fn event, acc ->
      case acc do
        [] -> {:cont, [event]}
        [prev | _] ->
          if causal?(prev, event) do
            {:cont, [event | acc]}
          else
            {:cont, Enum.reverse(acc), [event]}
          end
      end
    end, fn acc -> {:cont, Enum.reverse(acc), []} end)
  end

  defp causal?(a, b) do
    a.type == b.type or
      abs(a.timestamp - b.timestamp) < 1000
  end
end
