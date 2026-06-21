defmodule Tiannara.Metrics.DomainAnalytics do
  @moduledoc """
  Calculates epistemic health metrics for Capability-Complete Civilizations.
  Prevents hidden monoculture and tracks interdisciplinary discovery.
  """

  @type aptitudes :: %{atom() => float()}

  @doc """
  Calculates Shannon Entropy of the domain aptitudes.
  High entropy = balanced, diverse capabilities.
  Low entropy = specialized, potential monoculture risk.
  """
  @spec calculate_entropy(aptitudes()) :: float()
  def calculate_entropy(aptitudes) do
    total = Map.values(aptitudes) |> Enum.sum()
    
    if total == 0.0 do
      0.0
    else
      probs = Map.new(aptitudes, fn {k, v} -> {k, v / total} end)
      
      Enum.reduce(probs, 0.0, fn {_domain, p}, acc ->
        if p > 0.0, do: acc - p * :math.log2(p), else: acc
      end)
    end
  end

  @doc """
  Returns the Monoculture Index (0.0 to 1.0).
  Values > 0.75 indicate a high risk of capability collapse in other domains.
  """
  @spec calculate_monoculture_index(aptitudes()) :: float()
  def calculate_monoculture_index(aptitudes) do
    case Map.values(aptitudes) |> Enum.max(fn -> 0.0 end) do
      max_val when max_val > 1.0 -> 1.0
      max_val -> max_val
    end
  end

  @doc """
  Calculates the Euclidean distance between two aptitude maps.
  Used to measure Domain Drift Velocity over epochs.
  """
  @spec calculate_drift_velocity(old_aptitudes :: aptitudes(), new_aptitudes :: aptitudes()) :: float()
  def calculate_drift_velocity(old_aptitudes, new_aptitudes) do
    domains = Map.keys(old_aptitudes)
    
    sum_squared_diff = 
      Enum.reduce(domains, 0.0, fn domain, acc ->
        old_val = Map.get(old_aptitudes, domain, 0.0)
        new_val = Map.get(new_aptitudes, domain, 0.0)
        acc + :math.pow(new_val - old_val, 2)
      end)
      
    :math.sqrt(sum_squared_diff)
  end

  @doc """
  Counts domains above a viability threshold (e.g., 0.4).
  Serves as a proxy for Cross-Domain Discovery Rate (interdisciplinary breadth).
  """
  @spec calculate_breadth(aptitudes(), threshold :: float()) :: integer()
  def calculate_breadth(aptitudes, threshold \\ 0.4) do
    Enum.count(aptitudes, fn {_domain, aptitude} -> aptitude >= threshold end)
  end
end
