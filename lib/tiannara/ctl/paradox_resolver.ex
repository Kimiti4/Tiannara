defmodule Tiannara.CTL.ParadoxResolver do
  @moduledoc "Bounded causal contradiction analyzer. It detects and classifies conflicts; it never claims to rewrite history."

  @spec resolve(map(), map()) :: {:ok, :resolved} | {:error, term()}
  def resolve(branch_h, base_h) when is_map(branch_h) and is_map(base_h) do
    contradictions = conflicting_keys(branch_h, base_h)
    broken = Map.get(branch_h, :broken_downstream, false) || Map.get(base_h, :broken_downstream, false)
    cond do
      broken -> {:error, :downstream_causality_broken}
      contradictions == [] -> {:ok, :resolved}
      true -> {:error, {:causal_contradiction, contradictions}}
    end
  end
  def resolve(_, _), do: {:error, :invalid_causal_state}

  defp conflicting_keys(a, b) do
    a
    |> Map.keys()
    |> Enum.filter(fn k -> Map.has_key?(b, k) and Map.get(a, k) != Map.get(b, k) end)
    |> Enum.reject(&(&1 in [:stress, :timestamp, :revision]))
  end
end
