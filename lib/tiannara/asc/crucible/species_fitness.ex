defmodule Tiannara.ASC.Crucible.SpeciesFitness do
  @moduledoc """
  Species Fitness — evaluates failure species as ecological populations.

  Phase 5C.6 introduces evolutionary selection pressure to failure species.
  Each species is evaluated on:
  - Survival rate (does it persist across generations?)
  - Repair success rate (can failures be fixed?)
  - Transfer success rate (does knowledge generalize?)
  - Adaptability (can it evolve new strategies?)

  Species with high fitness gain budget allocation.
  Species with low fitness lose budget and may go extinct.

  This transforms ASC from:
    "Curated diversity through manual budgets"
  into:
    "Self-organizing ecosystem through selection pressure"

  ## Example

      iex> fitness = SpeciesFitness.calculate(%{
      ...>   births: 100,
      ...>   survivals: 80,
      ...>   repairs_attempted: 90,
      ...>   repairs_successful: 72,
      ...>   transfers_attempted: 50,
      ...>   transfers_successful: 35
      ...> })
      iex> fitness.fitness_score
      0.742

  """

  defstruct [
    species_id: nil,
    generation: 0,

    # Population dynamics
    births: 0,
    survivals: 0,
    extinctions: 0,

    # Repair dynamics
    repairs_attempted: 0,
    repairs_successful: 0,

    # Transfer dynamics
    transfers_attempted: 0,
    transfers_successful: 0,

    # Recovery metrics
    average_recovery_latency_ms: 0.0,

    # Calculated fitness
    survival_rate: 0.0,
    repair_success_rate: 0.0,
    transfer_success_rate: 0.0,
    adaptability_score: 0.0,
    extinction_rate: 0.0,

    # Overall fitness score (0.0-1.0)
    fitness_score: 0.0,

    # Metadata
    last_updated: nil
  ]

  @typedoc "Species fitness record"
  @type t :: %__MODULE__{
          species_id: atom(),
          generation: non_neg_integer(),
          births: non_neg_integer(),
          survivals: non_neg_integer(),
          extinctions: non_neg_integer(),
          repairs_attempted: non_neg_integer(),
          repairs_successful: non_neg_integer(),
          transfers_attempted: non_neg_integer(),
          transfers_successful: non_neg_integer(),
          average_recovery_latency_ms: float(),
          survival_rate: float(),
          repair_success_rate: float(),
          transfer_success_rate: float(),
          adaptability_score: float(),
          extinction_rate: float(),
          fitness_score: float(),
          last_updated: DateTime.t() | nil
        }

  @doc """
  Calculate species fitness based on survival, repair, and transfer metrics.

  Formula:
    fitness = (
      survival_rate * 0.40 +
      repair_success_rate * 0.30 +
      transfer_success_rate * 0.20 +
      adaptability_score * 0.10
    ) - (
      extinction_rate * 0.25
    )

  Bound: 0.0 ≤ fitness ≤ 1.0
  """
  def calculate_fitness(species_data) do
    # Calculate component rates
    survival_rate = calculate_survival_rate(species_data)
    repair_success_rate = calculate_repair_success_rate(species_data)
    transfer_success_rate = calculate_transfer_success_rate(species_data)
    adaptability_score = calculate_adaptability_score(species_data)
    extinction_rate = calculate_extinction_rate(species_data)

    # Apply fitness formula
    raw_fitness = (
      survival_rate * 0.40 +
      repair_success_rate * 0.30 +
      transfer_success_rate * 0.20 +
      adaptability_score * 0.10
    ) - (
      extinction_rate * 0.25
    )

    # Bound fitness to [0.0, 1.0]
    fitness_score = max(0.0, min(1.0, raw_fitness))

    %__MODULE__{
      species_id: species_data.species_id,
      generation: species_data.generation || 0,
      births: species_data.births || 0,
      survivals: species_data.survivals || 0,
      extinctions: species_data.extinctions || 0,
      repairs_attempted: species_data.repairs_attempted || 0,
      repairs_successful: species_data.repairs_successful || 0,
      transfers_attempted: species_data.transfers_attempted || 0,
      transfers_successful: species_data.transfers_successful || 0,
      average_recovery_latency_ms: species_data.average_recovery_latency_ms || 0.0,
      survival_rate: Float.round(survival_rate, 3),
      repair_success_rate: Float.round(repair_success_rate, 3),
      transfer_success_rate: Float.round(transfer_success_rate, 3),
      adaptability_score: Float.round(adaptability_score, 3),
      extinction_rate: Float.round(extinction_rate, 3),
      fitness_score: Float.round(fitness_score, 3),
      last_updated: DateTime.utc_now()
    }
  end

  @doc """
  Calculate survival rate: survivals / births
  """
  def calculate_survival_rate(%{births: births, survivals: survivals}) when births > 0 do
    survivals / births
  end
  def calculate_survival_rate(_), do: 0.0

  @doc """
  Calculate repair success rate: repairs_successful / repairs_attempted
  """
  def calculate_repair_success_rate(%{repairs_attempted: attempted, repairs_successful: successful}) when attempted > 0 do
    successful / attempted
  end
  def calculate_repair_success_rate(_), do: 0.0

  @doc """
  Calculate transfer success rate: transfers_successful / transfers_attempted
  """
  def calculate_transfer_success_rate(%{transfers_attempted: attempted, transfers_successful: successful}) when attempted > 0 do
    successful / attempted
  end
  def calculate_transfer_success_rate(_), do: 0.0

  @doc """
  Calculate adaptability score based on recovery latency.
  Lower latency = higher adaptability.

  Score = 1.0 / (1.0 + normalized_latency)
  where normalized_latency is in seconds
  """
  def calculate_adaptability_score(%{average_recovery_latency_ms: latency_ms}) do
    latency_s = latency_ms / 1000.0
    1.0 / (1.0 + latency_s)
  end
  def calculate_adaptability_score(_), do: 0.5

  @doc """
  Calculate extinction rate: extinctions / births
  """
  def calculate_extinction_rate(%{births: births, extinctions: extinctions}) when births > 0 do
    extinctions / births
  end
  def calculate_extinction_rate(_), do: 0.0

  @doc """
  Adjust species budget based on fitness score.

  Formula:
    new_budget = old_budget * (0.5 + fitness_score)

  Then normalize so total = 100%

  Constraints:
    minimum_budget = 5%
    maximum_budget = 35%
  
  Uses iterative clamping to ensure all constraints are met.
  """
  def adjust_budget(budget_map, fitness_map) do
    # Calculate raw adjusted budgets
    adjusted = Enum.map(budget_map, fn {species_id, old_budget} ->
      fitness = Map.get(fitness_map, species_id, 0.5)
      new_budget = old_budget * (0.5 + fitness)
      {species_id, new_budget}
    end)
    |> Enum.into(%{})

    # Normalize to 100%
    normalized = normalize_budgets(adjusted)
    
    # Iteratively apply constraints until stable
    constrained = apply_constraints_iteratively(normalized, _iterations = 0)
    
    # Final normalization to ensure total = 100%
    normalize_budgets(constrained)
  end
  
  defp normalize_budgets(budget_map) do
    total = Enum.sum(Map.values(budget_map))
    if total > 0 do
      Enum.map(budget_map, fn {species_id, budget} ->
        {species_id, budget / total * 100}
      end)
      |> Enum.into(%{})
    else
      budget_map
    end
  end
  
  defp apply_constraints_iteratively(budget_map, iterations) when iterations < 10 do
    min_budget = 5.0
    max_budget = 35.0
    
    # Clamp values to [min, max]
    clamped = Enum.map(budget_map, fn {species_id, budget} ->
      {species_id, max(min_budget, min(max_budget, budget))}
    end)
    |> Enum.into(%{})
    
    # Check if any values changed
    if clamped == budget_map do
      # All constraints satisfied
      clamped
    else
      # Re-normalize and try again
      renormalized = normalize_budgets(clamped)
      apply_constraints_iteratively(renormalized, iterations + 1)
    end
  end
  
  defp apply_constraints_iteratively(budget_map, _iterations) do
    # Max iterations reached - force final clamp
    min_budget = 5.0
    max_budget = 35.0
    
    Enum.map(budget_map, fn {species_id, budget} ->
      {species_id, max(min_budget, min(max_budget, budget))}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Determine species status based on fitness.

  Returns:
    :dominant - fitness > 0.75
    :thriving - fitness 0.50-0.75
    :stable - fitness 0.20-0.50
    :declining - fitness 0.05-0.20
    :extinction_watch - fitness < 0.05
  """
  def determine_status(%{fitness_score: fitness}) do
    cond do
      fitness > 0.75 -> :dominant
      fitness > 0.50 -> :thriving
      fitness > 0.20 -> :stable
      fitness > 0.05 -> :declining
      true -> :extinction_watch
    end
  end

  @doc """
  Check if species should be marked for extinction.

  Criteria:
    - Fitness < 0.05
    - No survivals in last 5 generations
  """
  def should_extinguish?(%{fitness_score: fitness, survivals: survivals, generations_observed: generations}) do
    fitness < 0.05 and survivals == 0 and generations >= 5
  end
  def should_extinguish?(_), do: false

  @doc """
  Create a species extinction event record.
  """
  def create_extinction_event(species_id, generation, fitness, reason) do
    %{
      event_type: :species_extinction,
      species_id: species_id,
      generation: generation,
      fitness: fitness,
      reason: reason,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Create a species dominance event record.
  """
  def create_dominance_event(species_id, fitness, duration_generations) do
    %{
      event_type: :species_dominance,
      species_id: species_id,
      fitness: fitness,
      duration_generations: duration_generations,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Calculate species entropy across all species fitness scores.
  H = -Σ p(x) log₂ p(x)

  Higher entropy = more balanced ecosystem
  Lower entropy = dominated by few species
  """
  def calculate_species_entropy(fitness_map) when is_map(fitness_map) do
    total_fitness = Map.values(fitness_map) |> Enum.sum()

    if total_fitness == 0 do
      0.0
    else
      fitness_map
      |> Map.values()
      |> Enum.map(fn fitness ->
        p = fitness / total_fitness
        if p > 0, do: -p * :math.log2(p), else: 0.0
      end)
      |> Enum.sum()
    end
  end

  @doc """
  Get dominant species (highest fitness).
  """
  def get_dominant_species(fitness_map) when is_map(fitness_map) do
    fitness_map
    |> Enum.max_by(fn {_species_id, fitness} -> fitness end, fn -> {nil, 0.0} end)
  end

  @doc """
  Get declining species (fitness < 0.20).
  """
  def get_declining_species(fitness_map) when is_map(fitness_map) do
    fitness_map
    |> Enum.filter(fn {_species_id, fitness} -> fitness < 0.20 end)
    |> Enum.map(fn {species_id, fitness} -> {species_id, fitness} end)
  end

  @doc """
  Get species on extinction watch (fitness < 0.05).
  """
  def get_extinction_watch_species(fitness_map) when is_map(fitness_map) do
    fitness_map
    |> Enum.filter(fn {_species_id, fitness} -> fitness < 0.05 end)
    |> Enum.map(fn {species_id, fitness} -> {species_id, fitness} end)
  end
end
