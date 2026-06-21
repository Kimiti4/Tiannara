defmodule Tiannara.NDE.Novelty do
  @moduledoc """
  Injects bounded novelty to prevent monoculture heat death.
  """
  require Logger

  def inject(ecology, pressure) do
    Logger.warning("🌀 [NDE] Injecting semantic novelty (Pressure: #{Float.round(pressure, 2)})")

    ecology
    |> mutate_lineages(pressure)
    |> generate_niches(pressure)
    |> reinforce_hybrids()
  end

  defp mutate_lineages(ecology, pressure) do
    lineages = Map.get(ecology, :lineages, [])
    mutated = Enum.map(lineages, fn lineage ->
      if :rand.uniform() < pressure * 0.1 do
        Map.put(lineage, :mutation_rate, Map.get(lineage, :mutation_rate, 0.01) + 0.05)
      else
        lineage
      end
    end)
    Map.put(ecology, :lineages, mutated)
  end

  defp generate_niches(ecology, pressure) do
    niches = Map.get(ecology, :niches, [])
    if pressure > 0.7 do
      new_niche = %{
        id: "niche_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
        type: :contrarian,
        entropy_seed: :rand.uniform()
      }
      Map.put(ecology, :niches, [new_niche | niches])
    else
      ecology
    end
  end

  defp reinforce_hybrids(ecology), do: ecology
end
