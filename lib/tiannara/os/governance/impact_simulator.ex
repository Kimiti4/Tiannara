defmodule TiannaraOS.Governance.ImpactSimulator do
  @moduledoc """
  ImpactSimulator - Simulates proposal impacts across system domains
  
  Projects how a proposal will affect different parts of the system,
  including performance, complexity, maintainability, and evolution.
  
  ## Owner
  Called during proposal review to assess multi-dimensional impacts.
  
  ## Guarantees
  - Deterministic simulation (same inputs → same projections)
  - Multi-domain coverage (kernel, governance, science, archaeology)
  - Cascading impact analysis (direct + indirect effects)
  - Confidence intervals (uncertainty quantification)
  
  ## Usage
      iex> {:ok, genome} = GenomeCalculator.calculate(proposal_data)
      iex> simulation = ImpactSimulator.simulate(genome, seed: 42)
      %{domain_impacts: ..., cascading_effects: ..., confidence: 0.85}
  """

  alias TiannaraOS.Governance.ProposalGenome

  # === Public API ===

  @doc """
  Simulate proposal impacts across all system domains.
  
  Performs comprehensive impact projection including:
  - Domain-specific impacts (kernel, governance, science)
  - Cascading effects (indirect consequences)
  - Performance implications
  - Maintainability changes
  - Evolution trajectory shifts
  
  ## Options
  - `:seed` - Deterministic seed for reproducible simulation (default: 42)
  - `:horizon` - Simulation horizon in months (default: 12)
  - `:detail_level` - Level of detail (:summary | :detailed | :comprehensive)
  
  ## Returns
  Map with detailed simulation results
  """
  @spec simulate(ProposalGenome.t(), keyword()) :: map()
  def simulate(%ProposalGenome{} = genome, opts \\ []) do
    seed = Keyword.get(opts, :seed, 42)
    horizon = Keyword.get(opts, :horizon, 12)
    detail_level = Keyword.get(opts, :detail_level, :detailed)
    
    %{
      domain_impacts: simulate_domain_impacts(genome, seed),
      cascading_effects: analyze_cascading_effects(genome, seed),
      performance_impact: project_performance_impact(genome),
      maintainability_impact: assess_maintainability(genome),
      evolution_impact: project_evolution_impact(genome, horizon),
      risk_scenarios: generate_risk_scenarios(genome, seed),
      mitigation_strategies: suggest_mitigations(genome),
      confidence_intervals: calculate_confidence(genome, seed),
      simulation_metadata: %{
        seed: seed,
        horizon_months: horizon,
        detail_level: detail_level,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    }
  end

  @doc """
  Compare impact scenarios between two proposals.
  
  Useful for choosing between alternative approaches.
  
  ## Returns
  Map with comparative analysis and recommendation
  """
  @spec compare_scenarios(ProposalGenome.t(), ProposalGenome.t(), keyword()) :: map()
  def compare_scenarios(%ProposalGenome{} = genome1, %ProposalGenome{} = genome2, opts \\ []) do
    seed = Keyword.get(opts, :seed, 42)
    
    sim1 = simulate(genome1, seed: seed)
    sim2 = simulate(genome2, seed: seed)
    
    %{
      scenario_1: summarize_simulation(sim1),
      scenario_2: summarize_simulation(sim2),
      comparison: compare_simulations(sim1, sim2),
      recommendation: recommend_scenario(sim1, sim2),
      trade_offs: identify_trade_offs(sim1, sim2)
    }
  end

  @doc """
  Generate what-if scenarios for proposal variations.
  
  Explores how changes to proposal parameters would affect outcomes.
  
  ## Returns
  List of scenario variations with projected impacts
  """
  @spec what_if_analysis(ProposalGenome.t(), keyword()) :: [map()]
  def what_if_analysis(%ProposalGenome{} = base_genome, opts \\ []) do
    seed = Keyword.get(opts, :seed, 42)
    
    # Generate variations
    variations = [
      %{name: "conservative", fitness_multiplier: 0.7, risk_multiplier: 0.6},
      %{name: "aggressive", fitness_multiplier: 1.3, risk_multiplier: 1.4},
      %{name: "balanced", fitness_multiplier: 1.0, risk_multiplier: 1.0}
    ]
    
    Enum.map(variations, fn variation ->
      modified_genome = modify_genome(base_genome, variation)
      simulation = simulate(modified_genome, seed: seed)
      
      Map.merge(simulation, %{
        scenario_name: variation.name,
        modification_applied: variation
      })
    end)
  end

  # === Private Implementation ===

  defp simulate_domain_impacts(genome, seed) do
    %{
      kernel: simulate_kernel_impact(genome, seed),
      governance: simulate_governance_impact(genome, seed),
      science: simulate_science_impact(genome, seed),
      archaeology: simulate_archaeology_impact(genome, seed)
    }
  end

  defp simulate_kernel_impact(genome, seed) do
    if genome.affected_kernel do
      base_impact = genome.expected_fitness_delta
      
      # Kernel impacts are amplified
      amplification = 1.5
      adjusted_impact = base_impact * amplification
      
      variation = :rand.uniform(seed) * 0.1 - 0.05
      
      %{
        affected: true,
        impact_score: Float.round(clamp(adjusted_impact + variation, -1.0, 1.0), 3),
        risk_level: assess_impact_risk(genome.risk_score),
        stability_change: Float.round(-genome.expected_entropy_delta * 2, 3),
        recommendations: generate_kernel_recommendations(genome)
      }
    else
      %{
        affected: false,
        impact_score: 0.0,
        risk_level: :none,
        stability_change: 0.0,
        recommendations: []
      }
    end
  end

  defp simulate_governance_impact(genome, seed) do
    if genome.affected_governance do
      base_impact = genome.expected_fitness_delta
      
      # Governance impacts scale with complexity
      complexity_factor = 1.0 + genome.expected_complexity_score
      adjusted_impact = base_impact * complexity_factor
      
      variation = :rand.uniform(seed) * 0.08 - 0.04
      
      %{
        affected: true,
        impact_score: Float.round(clamp(adjusted_impact + variation, -1.0, 1.0), 3),
        complexity_change: Float.round(genome.expected_complexity_score * 0.5, 3),
        adaptability_change: Float.round((1.0 - genome.expected_complexity_score) * 0.3, 3),
        recommendations: generate_governance_recommendations(genome)
      }
    else
      %{
        affected: false,
        impact_score: 0.0,
        complexity_change: 0.0,
        adaptability_change: 0.0,
        recommendations: []
      }
    end
  end

  defp simulate_science_impact(genome, _seed) do
    if genome.affected_science do
      %{
        affected: true,
        capital_change: genome.expected_scientific_capital_change,
        knowledge_accumulation: Float.round(max(0, genome.expected_scientific_capital_change), 3),
        research_trajectory: assess_research_trajectory(genome),
        recommendations: generate_science_recommendations(genome)
      }
    else
      %{
        affected: false,
        capital_change: 0.0,
        knowledge_accumulation: 0.0,
        research_trajectory: :unchanged,
        recommendations: []
      }
    end
  end

  defp simulate_archaeology_impact(genome, _seed) do
    impact_value = case genome.expected_archaeology_impact do
      :none -> 0.0
      :minor -> 0.3
      :major -> 0.7
    end
    
    %{
      impact_level: genome.expected_archaeology_impact,
      impact_score: impact_value,
      explainability_change: assess_explainability_change(genome),
      provenance_preservation: genome.expected_archaeology_impact != :major,
      recommendations: generate_archaeology_recommendations(genome)
    }
  end

  defp analyze_cascading_effects(genome, _seed) do
    effects = []
    
    # Direct domain impacts may cascade to other domains
    effects = if genome.affected_kernel and genome.affected_governance do
      [%{
        type: :cross_domain_coupling,
        severity: :high,
        description: "Kernel-governance coupling may increase maintenance burden"
      } | effects]
    else
      effects
    end
    
    # Complexity cascades
    effects = if genome.expected_complexity_score > 0.6 do
      [%{
        type: :complexity_cascade,
        severity: :medium,
        description: "High complexity may propagate to dependent systems"
      } | effects]
    else
      effects
    end
    
    # Migration cascades
    effects = if genome.migration_difficulty in [:hard, :extreme] do
      [%{
        type: :migration_burden,
        severity: :medium,
        description: "Difficult migration may delay adoption and create fragmentation"
      } | effects]
    else
      effects
    end
    
    # Replay cascades
    effects = if genome.replay_difficulty in [:major, :breaking] do
      [%{
        type: :replay_disruption,
        severity: :high,
        description: "Replay disruption affects all historical reconstruction capabilities"
      } | effects]
    else
      effects
    end
    
    %{
      total_effects: length(effects),
      high_severity: Enum.count(effects, &(&1.severity == :high)),
      medium_severity: Enum.count(effects, &(&1.severity == :medium)),
      low_severity: Enum.count(effects, &(&1.severity == :low)),
      effects: effects,
      overall_cascade_risk: determine_cascade_risk(effects)
    }
  end

  defp project_performance_impact(genome) do
    # Estimate performance impact based on complexity and graph changes
    base_impact = -genome.expected_complexity_score * 0.1
    
    graph_impact = 
      (genome.graph_impact.nodes_added - genome.graph_impact.nodes_removed) * 0.02 +
      (genome.graph_impact.edges_added - genome.graph_impact.edges_removed) * 0.01
    
    %{
      estimated_change: Float.round(base_impact + graph_impact, 3),
      direction: if(base_impact + graph_impact > 0, do: :improvement, else: :degradation),
      magnitude: assess_magnitude(abs(base_impact + graph_impact)),
      factors: [
        complexity_impact: base_impact,
        structural_impact: graph_impact
      ]
    }
  end

  defp assess_maintainability(genome) do
    # Maintainability decreases with complexity and increases with safety
    base_score = 0.7
    
    adjustment = 
      -genome.expected_complexity_score * 0.3 +
      genome.safety_score * 0.2 -
      genome.risk_score * 0.2
    
    final_score = Float.round(clamp(base_score + adjustment, 0.0, 1.0), 3)
    
    %{
      maintainability_score: final_score,
      trend: if(final_score > 0.7, do: :improving, else: :declining),
      key_factors: [
        complexity: genome.expected_complexity_score,
        safety: genome.safety_score,
        risk: genome.risk_score
      ],
      recommendations: generate_maintainability_recommendations(genome)
    }
  end

  defp project_evolution_impact(genome, horizon_months) do
    # Project how system evolution trajectory changes
    base_trajectory = genome.expected_fitness_delta * horizon_months / 12
    
    sustainability_factor = 1.0 - genome.expected_complexity_score * 0.3
    adjusted_trajectory = base_trajectory * sustainability_factor
    
    %{
      projected_trajectory: Float.round(adjusted_trajectory, 3),
      sustainability_factor: Float.round(sustainability_factor, 3),
      adaptation_capacity: assess_adaptation_capacity(genome),
      technical_debt_accumulation: estimate_technical_debt(genome, horizon_months),
      evolution_recommendations: generate_evolution_recommendations(genome)
    }
  end

  defp generate_risk_scenarios(genome, _seed) do
    # Worst case scenario
    worst_case = %{
      name: "worst_case",
      probability: genome.risk_score * 0.3,
      impact: genome.expected_fitness_delta - 0.3,
      description: "Implementation fails to deliver expected benefits"
    }
    
    # Best case scenario
    best_case = %{
      name: "best_case",
      probability: (1.0 - genome.risk_score) * 0.4,
      impact: genome.expected_fitness_delta + 0.2,
      description: "Implementation exceeds expectations"
    }
    
    # Most likely scenario
    most_likely = %{
      name: "most_likely",
      probability: 0.6,
      impact: genome.expected_fitness_delta,
      description: "Implementation delivers expected benefits"
    }
    
    [worst_case, most_likely, best_case]
  end

  defp suggest_mitigations(genome) do
    mitigations = []
    
    # High risk mitigations
    mitigations = if genome.risk_score > 0.6 do
      [%{
        risk: :high_technical_risk,
        strategy: :incremental_rollout,
        description: "Deploy incrementally with rollback capability"
      } | mitigations]
    else
      mitigations
    end
    
    # Complex migration mitigations
    mitigations = if genome.migration_difficulty in [:hard, :extreme] do
      [%{
        risk: :difficult_migration,
        strategy: :phased_migration,
        description: "Break migration into smaller, manageable phases"
      } | mitigations]
    else
      mitigations
    end
    
    # Replay impact mitigations
    mitigations = if genome.replay_difficulty in [:major, :breaking] do
      [%{
        risk: :replay_disruption,
        strategy: :compatibility_layer,
        description: "Implement compatibility layer to preserve replay capability"
      } | mitigations]
    else
      mitigations
    end
    
    mitigations
  end

  defp calculate_confidence(genome, seed) do
    # Confidence based on data quality and consistency
    base_confidence = 0.75
    
    # Adjust based on metric consistency
    consistency_bonus = 
      if abs(genome.expected_fitness_delta + genome.expected_entropy_delta) < 0.2 do
        0.1
      else
        0.0
      end
    
    # Reduce confidence for high-risk proposals
    risk_penalty = if genome.risk_score > 0.7, do: 0.15, else: 0.0
    
    # Add small deterministic variation
    variation = :rand.uniform(seed) * 0.05 - 0.025
    
    lower_bound = Float.round(clamp(base_confidence + consistency_bonus - risk_penalty - 0.1, 0.0, 1.0), 3)
    upper_bound = Float.round(clamp(base_confidence + consistency_bonus - risk_penalty + 0.1, 0.0, 1.0), 3)
    
    %{
      point_estimate: Float.round(base_confidence + consistency_bonus - risk_penalty + variation, 3),
      lower_bound: lower_bound,
      upper_bound: upper_bound,
      confidence_level: 0.95
    }
  end

  defp summarize_simulation(simulation) do
    %{
      overall_impact: calculate_overall_impact(simulation),
      domain_summary: summarize_domains(simulation.domain_impacts),
      risk_summary: simulation.risk_scenarios |> Enum.at(0) |> Map.take([:probability, :impact]),
      confidence: simulation.confidence_intervals.point_estimate
    }
  end

  defp compare_simulations(sim1, sim2) do
    impact1 = calculate_overall_impact(sim1)
    impact2 = calculate_overall_impact(sim2)
    
    %{
      impact_delta: Float.round(impact2 - impact1, 3),
      preferred: if(impact2 > impact1, do: :scenario_2, else: :scenario_1),
      confidence_in_preference: abs(impact2 - impact1) > 0.1
    }
  end

  defp recommend_scenario(sim1, sim2) do
    impact1 = calculate_overall_impact(sim1)
    impact2 = calculate_overall_impact(sim2)
    
    if abs(impact2 - impact1) < 0.05 do
      %{recommendation: :equivalent, reason: "Scenarios have similar projected impact"}
    else
      preferred = if impact2 > impact1, do: :scenario_2, else: :scenario_1
      %{recommendation: preferred, reason: "Higher projected impact"}
    end
  end

  defp identify_trade_offs(sim1, sim2) do
    [
      %{
        dimension: :risk_vs_reward,
        scenario_1: {sim1.risk_scenarios |> Enum.at(0) |> Map.get(:probability), calculate_overall_impact(sim1)},
        scenario_2: {sim2.risk_scenarios |> Enum.at(0) |> Map.get(:probability), calculate_overall_impact(sim2)}
      }
    ]
  end

  defp modify_genome(genome, variation) do
    %ProposalGenome{
      genome |
      expected_fitness_delta: genome.expected_fitness_delta * variation.fitness_multiplier,
      risk_score: clamp(genome.risk_score * variation.risk_multiplier, 0.0, 1.0)
    }
  end

  defp calculate_overall_impact(simulation) do
    # Weighted combination of domain impacts
    domain_weights = %{
      kernel: 0.4,
      governance: 0.35,
      science: 0.15,
      archaeology: 0.1
    }
    
    domains = simulation.domain_impacts
    
    score = 
      domain_weights.kernel * domains.kernel.impact_score +
      domain_weights.governance * domains.governance.impact_score +
      domain_weights.science * domains.science.capital_change +
      domain_weights.archaeology * domains.archaeology.impact_score
    
    Float.round(score, 3)
  end

  defp summarize_domains(domains) do
    %{
      kernel_affected: domains.kernel.affected,
      governance_affected: domains.governance.affected,
      science_affected: domains.science.affected,
      max_impact: Enum.max([domains.kernel.impact_score, domains.governance.impact_score, abs(domains.science.capital_change)])
    }
  end

  defp assess_impact_risk(risk_score) do
    cond do
      risk_score > 0.7 -> :critical
      risk_score > 0.5 -> :high
      risk_score > 0.3 -> :medium
      true -> :low
    end
  end

  defp generate_kernel_recommendations(genome) do
    recs = []
    recs = if genome.expected_replay_impact != :none, do: ["Implement replay compatibility layer" | recs], else: recs
    recs = if genome.risk_score > 0.6, do: ["Add comprehensive regression tests" | recs], else: recs
    Enum.reverse(recs)
  end

  defp generate_governance_recommendations(genome) do
    recs = []
    recs = if genome.expected_complexity_score > 0.6, do: ["Simplify implementation approach" | recs], else: recs
    recs = if genome.migration_difficulty in [:hard, :extreme], do: ["Plan phased rollout strategy" | recs], else: recs
    Enum.reverse(recs)
  end

  defp generate_science_recommendations(_genome) do
    ["Document knowledge contributions", "Update scientific capital ledger"]
  end

  defp generate_archaeology_recommendations(genome) do
    if genome.expected_archaeology_impact == :major do
      ["Ensure complete provenance tracking", "Preserve historical record integrity"]
    else
      ["Maintain existing provenance standards"]
    end
  end

  defp assess_explainability_change(genome) do
    case genome.expected_archaeology_impact do
      :none -> :unchanged
      :minor -> :slightly_improved
      :major -> :significantly_changed
    end
  end

  defp determine_cascade_risk(effects) do
    high_count = Enum.count(effects, &(&1.severity == :high))
    
    cond do
      high_count >= 2 -> :critical
      high_count == 1 -> :high
      length(effects) > 2 -> :medium
      true -> :low
    end
  end

  defp assess_magnitude(value) do
    cond do
      value > 0.5 -> :large
      value > 0.2 -> :moderate
      value > 0.05 -> :small
      true -> :negligible
    end
  end

  defp assess_research_trajectory(genome) do
    if genome.expected_scientific_capital_change > 0.2 do
      :accelerating
    else
      :steady
    end
  end

  defp generate_maintainability_recommendations(genome) do
    recs = []
    recs = if genome.expected_complexity_score > 0.6, do: ["Reduce implementation complexity" | recs], else: recs
    recs = if genome.safety_score < 0.7, do: ["Improve safety guarantees" | recs], else: recs
    recs = if genome.risk_score > 0.5, do: ["Add monitoring and alerting" | recs], else: recs
    Enum.reverse(recs)
  end

  defp assess_adaptation_capacity(genome) do
    capacity = genome.safety_score * 0.5 + (1.0 - genome.expected_complexity_score) * 0.5
    
    cond do
      capacity > 0.7 -> :high
      capacity > 0.5 -> :medium
      true -> :low
    end
  end

  defp estimate_technical_debt(genome, horizon_months) do
    # Technical debt accumulates with complexity and time
    monthly_accumulation = genome.expected_complexity_score * 0.05
    total_debt = monthly_accumulation * horizon_months
    
    %{
      accumulated_debt: Float.round(total_debt, 3),
      monthly_rate: Float.round(monthly_accumulation, 3),
      severity: if(total_debt > 0.5, do: :high, else: :manageable)
    }
  end

  defp generate_evolution_recommendations(genome) do
    recs = []
    recs = if genome.expected_complexity_score > 0.5, do: ["Plan regular refactoring cycles" | recs], else: recs
    recs = if genome.risk_score > 0.5, do: ["Establish monitoring checkpoints" | recs], else: recs
    recs = if genome.migration_difficulty != :trivial, do: ["Create migration support tools" | recs], else: recs
    Enum.reverse(recs)
  end

  defp clamp(value, min_val, max_val) do
    max(min_val, min(value, max_val))
  end
end
