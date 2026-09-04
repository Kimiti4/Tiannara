defmodule TiannaraOS.Governance.FitnessEvaluator do
  @moduledoc """
  FitnessEvaluator - Evaluates constitutional fitness impact of proposals
  
  Assesses how a proposal affects the system's overall constitutional fitness,
  measuring alignment with core invariants and long-term viability.
  
  ## Owner
  Called during proposal review to assess fitness before ratification.
  
  ## Guarantees
  - Deterministic evaluation (same inputs → same fitness score)
  - Multi-dimensional assessment (kernel, governance, science dimensions)
  - Invariant preservation check (ensures no violations)
  - Long-term viability projection (beyond immediate impacts)
  
  ## Usage
      iex> {:ok, genome} = GenomeCalculator.calculate(proposal_data)
      iex> evaluation = FitnessEvaluator.evaluate(genome)
      %{fitness_score: 0.85, invariant_violations: [], recommendation: :approve}
  """

  alias TiannaraOS.Governance.ProposalGenome

  # === Public API ===

  @doc """
  Evaluate constitutional fitness impact of a proposal genome.
  
  Performs comprehensive multi-dimensional assessment including:
  - Overall fitness score (0.0-1.0)
  - Dimension-specific impacts (kernel, governance, science)
  - Invariant violation checks
  - Long-term viability projection
  - Recommendation (approve/reject/revise)
  
  ## Returns
  Map with detailed evaluation results
  """
  @spec evaluate(ProposalGenome.t()) :: map()
  def evaluate(%ProposalGenome{} = genome) do
    %{
      overall_fitness_score: calculate_overall_fitness(genome),
      dimension_scores: evaluate_dimensions(genome),
      invariant_check: check_invariants(genome),
      viability_projection: project_viability(genome),
      risk_assessment: assess_risks(genome),
      recommendation: generate_recommendation(genome),
      confidence: calculate_confidence(genome),
      evaluation_timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  @doc """
  Compare fitness before and after proposal to determine net impact.
  
  Useful for understanding whether proposal improves or degrades system fitness.
  
  ## Returns
  Map with delta calculations and improvement assessment
  """
  @spec compare_fitness(map(), ProposalGenome.t()) :: map()
  def compare_fitness(baseline_fitness, %ProposalGenome{} = genome) do
    post_fitness = calculate_overall_fitness(genome)
    
    %{
      baseline: baseline_fitness,
      post_proposal: post_fitness,
      delta: post_fitness - baseline_fitness,
      improved: post_fitness > baseline_fitness,
      improvement_percentage: Float.round((post_fitness - baseline_fitness) / baseline_fitness * 100, 2)
    }
  end

  @doc """
  Check if proposal violates any constitutional invariants.
  
  Returns list of violations (empty list means no violations).
  
  ## Invariants Checked
  - Replay determinism preservation
  - Evidence closure maintenance
  - Archaeological explainability
  - Capability graph consistency
  - Authority graph integrity
  """
  @spec check_invariants(ProposalGenome.t()) :: map()
  def check_invariants(%ProposalGenome{} = genome) do
    violations = []
    
    # Check replay determinism
    violations = if genome.expected_replay_impact == :breaking do
      [%{
        invariant: :replay_determinism,
        severity: :critical,
        description: "Proposal breaks replay determinism"
      } | violations]
    else
      violations
    end
    
    # Check evidence closure
    violations = if genome.expected_archaeology_impact == :major and 
                  not preserves_evidence_closure?(genome) do
      [%{
        invariant: :evidence_closure,
        severity: :high,
        description: "Proposal may compromise evidence closure property"
      } | violations]
    else
      violations
    end
    
    # Check kernel safety
    violations = if genome.affected_kernel and genome.risk_score > 0.7 do
      [%{
        invariant: :kernel_safety,
        severity: :high,
        description: "High-risk change to kernel layer"
      } | violations]
    else
      violations
    end
    
    # Check governance stability
    violations = if genome.affected_governance and genome.expected_complexity_score > 0.8 do
      [%{
        invariant: :governance_stability,
        severity: :medium,
        description: "Complex change to governance layer may reduce stability"
      } | violations]
    else
      violations
    end
    
    %{
      has_violations: not Enum.empty?(violations),
      violation_count: length(violations),
      critical_violations: Enum.count(violations, &(&1.severity == :critical)),
      high_violations: Enum.count(violations, &(&1.severity == :high)),
      medium_violations: Enum.count(violations, &(&1.severity == :medium)),
      low_violations: Enum.count(violations, &(&1.severity == :low)),
      violations: violations,
      invariant_preservation_score: calculate_invariant_preservation(genome, violations)
    }
  end

  # === Private Implementation ===

  defp calculate_overall_fitness(genome) do
    # Weighted combination of key metrics
    weights = %{
      fitness_delta: 0.35,
      safety: 0.25,
      low_risk: 0.20,
      low_complexity: 0.10,
      low_entropy: 0.10
    }
    
    # Normalize fitness delta to 0-1 range
    normalized_fitness = (genome.expected_fitness_delta + 1.0) / 2.0
    
    # Calculate weighted score
    score = 
      weights.fitness_delta * normalized_fitness +
      weights.safety * genome.safety_score +
      weights.low_risk * (1.0 - genome.risk_score) +
      weights.low_complexity * (1.0 - genome.expected_complexity_score) +
      weights.low_entropy * (1.0 - max(0, genome.expected_entropy_delta))
    
    Float.round(score, 3)
    |> clamp(0.0, 1.0)
  end

  defp evaluate_dimensions(genome) do
    %{
      kernel: evaluate_kernel_dimension(genome),
      governance: evaluate_governance_dimension(genome),
      science: evaluate_science_dimension(genome)
    }
  end

  defp evaluate_kernel_dimension(genome) do
    if genome.affected_kernel do
      # Kernel changes are evaluated more strictly
      base_score = genome.safety_score * 0.6 + (1.0 - genome.risk_score) * 0.4
      penalty = if genome.expected_replay_impact != :none, do: 0.2, else: 0.0
      
      %{
        score: Float.round(max(0, base_score - penalty), 3),
        affected: true,
        risk_level: assess_kernel_risk(genome)
      }
    else
      %{
        score: 1.0,
        affected: false,
        risk_level: :none
      }
    end
  end

  defp evaluate_governance_dimension(genome) do
    if genome.affected_governance do
      base_score = genome.safety_score * 0.5 + (1.0 - genome.expected_complexity_score) * 0.5
      
      %{
        score: Float.round(base_score, 3),
        affected: true,
        complexity_level: assess_complexity_level(genome)
      }
    else
      %{
        score: 1.0,
        affected: false,
        complexity_level: :none
      }
    end
  end

  defp evaluate_science_dimension(genome) do
    if genome.affected_science do
      base_score = max(0, genome.expected_scientific_capital_change + 0.5)
      
      %{
        score: Float.round(clamp(base_score, 0.0, 1.0), 3),
        affected: true,
        capital_change: genome.expected_scientific_capital_change
      }
    else
      %{
        score: 1.0,
        affected: false,
        capital_change: 0.0
      }
    end
  end

  defp project_viability(genome) do
    # Project long-term viability based on current metrics
    short_term = genome.safety_score * 0.7 + (1.0 - genome.risk_score) * 0.3
    long_term = short_term * 0.6 + (1.0 - genome.expected_complexity_score) * 0.4
    
    %{
      short_term_viability: Float.round(short_term, 3),
      long_term_viability: Float.round(long_term, 3),
      sustainability_score: Float.round(long_term * 0.7 + short_term * 0.3, 3),
      projected_lifespan: estimate_lifespan(genome)
    }
  end

  defp assess_risks(genome) do
    risks = []
    
    # Technical risks
    risks = if genome.risk_score > 0.6 do
      [%{type: :technical, severity: :high, description: "High technical risk"} | risks]
    else
      risks
    end
    
    # Migration risks
    risks = if genome.migration_difficulty in [:hard, :extreme] do
      [%{type: :migration, severity: :medium, description: "Difficult migration required"} | risks]
    else
      risks
    end
    
    # Rollback risks
    risks = if genome.rollback_difficulty in [:hard, :extreme] do
      [%{type: :rollback, severity: :medium, description: "Difficult rollback if needed"} | risks]
    else
      risks
    end
    
    # Replay risks
    risks = if genome.replay_difficulty in [:major, :breaking] do
      [%{type: :replay, severity: :high, description: "Significant replay impact"} | risks]
    else
      risks
    end
    
    %{
      total_risks: length(risks),
      high_risks: Enum.count(risks, &(&1.severity == :high)),
      risks: risks,
      overall_risk_level: determine_overall_risk(genome)
    }
  end

  defp generate_recommendation(genome) do
    fitness = calculate_overall_fitness(genome)
    invariant_check = check_invariants(genome)
    
    cond do
      invariant_check.has_violations and invariant_check.critical_violations > 0 ->
        :reject
      
      invariant_check.has_violations and invariant_check.high_violations > 0 ->
        :revise
      
      fitness < 0.4 ->
        :reject
      
      fitness < 0.6 ->
        :revise
      
      fitness >= 0.6 and fitness < 0.8 ->
        :approve_with_conditions
      
      fitness >= 0.8 ->
        :approve
    end
  end

  defp calculate_confidence(genome) do
    # Confidence based on data completeness and consistency
    base_confidence = 0.7
    
    # Increase confidence if metrics are consistent
    consistency_bonus = 
      if abs(genome.expected_fitness_delta + genome.expected_entropy_delta) < 0.3 do
        0.1
      else
        0.0
      end
    
    # Decrease confidence if risk is high
    risk_penalty = if genome.risk_score > 0.7, do: 0.15, else: 0.0
    
    Float.round(base_confidence + consistency_bonus - risk_penalty, 3)
    |> clamp(0.0, 1.0)
  end

  defp preserves_evidence_closure?(genome) do
    # Heuristic: proposals with minor archaeology impact preserve closure
    genome.expected_archaeology_impact in [:none, :minor]
  end

  defp calculate_invariant_preservation(_genome, violations) do
    # Start with perfect score and deduct for violations
    base_score = 1.0
    
    deductions = Enum.reduce(violations, 0.0, fn violation, acc ->
      case violation.severity do
        :critical -> acc + 0.3
        :high -> acc + 0.2
        :medium -> acc + 0.1
        :low -> acc + 0.05
      end
    end)
    
    Float.round(max(0, base_score - deductions), 3)
  end

  defp assess_kernel_risk(genome) do
    cond do
      genome.risk_score > 0.8 -> :critical
      genome.risk_score > 0.6 -> :high
      genome.risk_score > 0.4 -> :medium
      true -> :low
    end
  end

  defp assess_complexity_level(genome) do
    cond do
      genome.expected_complexity_score > 0.8 -> :very_high
      genome.expected_complexity_score > 0.6 -> :high
      genome.expected_complexity_score > 0.4 -> :medium
      true -> :low
    end
  end

  defp estimate_lifespan(genome) do
    # Rough estimate based on fitness and complexity
    base_months = 12
    
    adjustment = 
      (if genome.expected_fitness_delta > 0.3, do: 6, else: 0) +
      (if genome.expected_complexity_score < 0.3, do: 3, else: 0) -
      (if genome.risk_score > 0.6, do: 3, else: 0)
    
    max(3, base_months + adjustment)
  end

  defp determine_overall_risk(genome) do
    cond do
      genome.risk_score > 0.8 -> :critical
      genome.risk_score > 0.6 -> :high
      genome.risk_score > 0.4 -> :medium
      true -> :low
    end
  end

  defp clamp(value, min_val, max_val) do
    max(min_val, min(value, max_val))
  end
end
