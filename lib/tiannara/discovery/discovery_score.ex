defmodule Tiannara.Discovery.DiscoveryScore do
  defstruct [:novelty, :importance, :feasibility, :expected_information_gain,
    :reproducibility, :safety, :resource_efficiency]

  @type t :: %__MODULE__{}

  @dimensions [:novelty, :importance, :feasibility, :expected_information_gain,
    :reproducibility, :safety, :resource_efficiency]

  def dimensions, do: @dimensions

  def new(attrs \\ []) do
    %__MODULE__{novelty: 0.5, importance: 0.5, feasibility: 0.5,
      expected_information_gain: 0.5, reproducibility: 0.5, safety: 1.0, resource_efficiency: 0.5}
    |> struct(attrs)
  end

  def from_gap(gap) do
    severity_weight = case gap.severity do
      :critical -> 1.0; :high -> 0.8; :medium -> 0.6; :low -> 0.4; _ -> 0.5
    end
    new(novelty: min(1.0, gap.uncertainty),
      importance: severity_weight * (gap.estimated_impact || 0.5),
      feasibility: 0.7,
      expected_information_gain: min(1.0, (gap.estimated_impact || 0.5) * gap.uncertainty),
      reproducibility: 0.8, safety: 1.0, resource_efficiency: 0.6)
  end

  def composite(%__MODULE__{} = score) do
    values = Enum.map(@dimensions, &Map.fetch!(score, &1))
    if Enum.any?(values, &(&1 <= 0.0)), do: 0.0, else:
      :math.pow(Enum.reduce(values, 1.0, &(&1 * &2)), 1.0 / length(@dimensions))
  end

  def weakest_dimension(%__MODULE__{} = score) do
    @dimensions |> Enum.map(fn dim -> {dim, Map.fetch!(score, dim)} end) |> Enum.min_by(fn {_dim, val} -> val end)
  end

  def weighted_linear(%__MODULE__{} = score, weights \\ nil) do
    dims = @dimensions
    w = weights || Enum.map(dims, fn
      :novelty -> 0.15; :importance -> 0.25; :feasibility -> 0.15
      :expected_information_gain -> 0.20; :reproducibility -> 0.10
      :safety -> 0.05; :resource_efficiency -> 0.10
    end)
    values = Enum.map(dims, &Map.fetch!(score, &1))
    Enum.zip(values, w) |> Enum.reduce(0.0, fn {v, wt}, acc -> acc + v * wt end)
  end

  def explain(%__MODULE__{} = score) do
    comp = composite(score)
    {weakest_dim, weakest_val} = weakest_dimension(score)
    lines = @dimensions |> Enum.map(fn dim -> "  #{String.pad_trailing(Atom.to_string(dim), 28)} #{Float.round(Map.fetch!(score, dim), 3)}" end) |> Enum.join("\n")
    "Discovery Score: #{Float.round(comp, 4)}\n#{lines}\nWeakest dimension: #{weakest_dim} (#{Float.round(weakest_val, 3)})"
  end
end
