defmodule Tiannara.OPC.PatternEngine do
  @moduledoc """
  Phase 5F.9 — Pattern engine.
  Converts causal chains into high-level pattern descriptors.
  """

  alias Tiannara.OPC.InvariantDetector

  def extract(chains) when is_list(chains) do
    chains
    |> InvariantDetector.detect()
    |> Enum.map(fn %{chain: chain, invariants: invariants} ->
      %{
        pattern_type: classify(chain),
        invariants: invariants,
        strength: confidence(chain, invariants)
      }
    end)
  end

  defp classify(chain) do
    cond do
      length(chain) > 20 -> :high_complexity
      length(chain) > 10 -> :medium_complexity
      true -> :low_complexity
    end
  end

  defp confidence(chain, invariants) do
    base = min(1.0, length(chain) / 10)
    bonus = min(0.5, length(invariants) * 0.1)
    Float.round(base + bonus, 2)
  end
end
