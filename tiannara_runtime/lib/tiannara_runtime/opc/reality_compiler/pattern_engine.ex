defmodule Tiannara.OPC.RealityCompiler.PatternEngine do

  def extract(chains) do
    chains
    |> Tiannara.OPC.RealityCompiler.InvariantDetector.detect()
    |> Enum.map(fn %{chain: chain, invariants: inv} ->
      %{
        pattern_type: classify(chain),
        invariants: inv,
        strength: confidence(chain)
      }
    end)
  end

  defp classify(chain) do
    cond do
      length(chain) > 20 -> :high_complexity
      true -> :low_complexity
    end
  end

  defp confidence(chain) do
    min(1.0, length(chain) / 10)
  end
end
