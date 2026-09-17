defmodule Tiannara.OPC.RealityCompiler.InvariantDetector do

  def detect(chains) do
    Enum.map(chains, fn chain ->
      # Group events by type and count occurrences
      type_counts = 
        chain
        |> Enum.map(& &1.type)
        |> Enum.reduce(%{}, fn type, acc -> Map.update(acc, type, 1, &(&1 + 1)) end)

      stable =
        Enum.filter(type_counts, fn {_k, v} -> v >= 3 end)
        |> Enum.map(fn {k, _} -> k end)

      %{chain: chain, invariants: stable}
    end)
  end
end
