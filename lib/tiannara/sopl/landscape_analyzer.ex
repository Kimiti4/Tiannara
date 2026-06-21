defmodule Tiannara.SOPL.LandscapeAnalyzer do
  @moduledoc """
  SOPL-1.5: Landscape Analyzer
  
  Evaluates regions of law-space, mapping fitness against constitutional pressure.
  Ensures that SOPL-2 will mutate toward "high fitness + low pressure" rather than
  blindly chasing the highest fitness score into dangerous edge zones.
  """
  
  def analyze_region(law, fitness_eval) do
    pressure = calculate_constitutional_pressure(law)
    
    %{
      law_id: law.id,
      fitness: fitness_eval.total_fitness,
      pressure: pressure,
      viability: calculate_viability(fitness_eval.total_fitness, pressure)
    }
  end

  @doc """
  Constitutional Pressure measures the distance to invariant failure.
  A pressure of 1.0 means imminent constitutional collapse.
  A pressure of 0.0 means complete safety.
  """
  def calculate_constitutional_pressure(law) do
    # law.constitutional_margin goes from 0.0 (failure) to 1.0 (safe)
    # Pressure is the inverse of margin. High pressure = close to failure.
    1.0 - Map.get(law, :constitutional_margin, 1.0)
  end

  defp calculate_viability(fitness, pressure) do
    # High fitness + Low pressure = High viability
    fitness * (1.0 - pressure)
  end
end

defmodule Tiannara.SOPL.LawGradientTracker do
  @moduledoc """
  SOPL-1.5: Law Gradient Tracker
  
  Calculates fitness gradients and safe mutation radius for future SOPL-2 evolution.
  """
  
  @doc """
  Calculates how far a %LawGenome{} can be mutated without immediately 
  triggering a Constitutional failure.
  """
  def calculate_safe_mutation_radius(pressure) do
    base_radius = 0.25
    
    # If pressure is high (close to violation), shrink the radius drastically
    # If pressure is low (safe), allow wider exploration
    safety_factor = 1.0 - pressure
    
    # Radius scales non-linearly with safety to punish edge-hugging
    radius = base_radius * :math.pow(safety_factor, 2)
    
    # Minimum exploration floor
    max(0.01, radius)
  end

  def compute_gradients(_evaluations) do
    # In a full simulation, this performs a multi-dimensional derivative 
    # of fitness across law parameters based on historical %LawRuin{} footprints.
    %{
      novelty_gradient: +0.05,
      stability_gradient: -0.02,
      truth_gradient: +0.01
    }
  end
end
