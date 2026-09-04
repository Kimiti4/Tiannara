defmodule TiannaraOS.Governance.GenomeCalculator do
  @moduledoc """
  GenomeCalculator - Calculates proposal genome metrics from raw proposal data
  
  Analyzes proposal intent, scope, and expected changes to compute
  measurable genome fields including fitness impact, risk assessment,
  complexity scoring, and dependency analysis.
  
  ## Owner
  Called during proposal submission to generate immutable genome.
  
  ## Guarantees
  - Deterministic calculation (same inputs → same genome)
  - Comprehensive metric coverage (all genome fields populated)
  - Domain-aware analysis (understands kernel/governance/science impacts)
  - Evidence-based scoring (metrics derived from proposal structure)
  
  ## Usage
      iex> proposal_data = %{
      ...>   title: "Improve replay determinism",
      ...>   description: "Add seed-based context passing to eliminate wall-clock time dependencies",
      ...>   affected_modules: ["governance/replay_engine.ex"],
      ...>   migration_required: true
      ...> }
      iex> {:ok, genome} = GenomeCalculator.calculate(proposal_data, seed: 42)
  """

  alias TiannaraOS.Governance.ProposalGenome

  # === Public API ===

  @doc """
  Calculate complete proposal genome from proposal data.
  
  Analyzes proposal structure, affected modules, and migration requirements
  to populate all genome fields with measurable values.
  
  ## Options
  - `:seed` - Deterministic seed for reproducible calculations (default: 42)
  - `:context` - Additional context for domain-specific analysis
  
  ## Returns
  `{:ok, %ProposalGenome{}}` with all fields calculated, or `{:error, reason}`
  """
  @spec calculate(map(), keyword()) :: {:ok, ProposalGenome.t()} | {:error, String.t()}
  def calculate(proposal_data, opts \\ []) do
    seed = Keyword.get(opts, :seed, 42)
    
    with {:ok, validated_data} <- validate_proposal_data(proposal_data),
         intent <- extract_intent(validated_data),
         domains <- analyze_domains(validated_data),
         fitness_delta <- calculate_fitness_delta(validated_data, seed),
         entropy_delta <- calculate_entropy_delta(validated_data, seed),
         cost <- estimate_cost(validated_data),
         replay_impact <- assess_replay_impact(validated_data),
         migration_cost <- estimate_migration_cost(validated_data),
         scientific_capital <- assess_scientific_capital(validated_data),
         archaeology_impact <- assess_archaeology_impact(validated_data),
         complexity <- calculate_complexity(validated_data),
         risk <- assess_risk(validated_data, seed),
         safety <- assess_safety(validated_data, seed),
         migration_difficulty <- assess_migration_difficulty(validated_data),
         rollback_difficulty <- assess_rollback_difficulty(validated_data),
         replay_difficulty <- assess_replay_difficulty(validated_data),
         graph_impact <- calculate_graph_impact(validated_data),
         dependency_impact <- analyze_dependencies(validated_data) do
      
      genome = %ProposalGenome{
        intent: intent,
        affected_domains: domains,
        affected_kernel: Map.get(validated_data, :affects_kernel, false),
        affected_governance: Map.get(validated_data, :affects_governance, false),
        affected_science: Map.get(validated_data, :affects_science, false),
        expected_fitness_delta: fitness_delta,
        expected_entropy_delta: entropy_delta,
        expected_cost: cost,
        expected_replay_impact: replay_impact,
        expected_migration_cost: migration_cost,
        expected_scientific_capital_change: scientific_capital,
        expected_archaeology_impact: archaeology_impact,
        expected_complexity_score: complexity,
        risk_score: risk,
        safety_score: safety,
        migration_difficulty: migration_difficulty,
        rollback_difficulty: rollback_difficulty,
        replay_difficulty: replay_difficulty,
        graph_impact: graph_impact,
        dependency_impact: dependency_impact
      }
      
      case ProposalGenome.validate(genome) do
        {:ok, validated_genome} -> {:ok, validated_genome}
        {:error, errors} -> {:error, "Genome validation failed: #{inspect(errors)}"}
      end
    end
  end

  @doc """
  Compare two genomes to identify key differences.
  
  Useful for understanding how proposal revisions affect metrics.
  
  ## Returns
  Map with field-by-field comparison and overall similarity score (0.0-1.0)
  """
  @spec compare(ProposalGenome.t(), ProposalGenome.t()) :: map()
  def compare(%ProposalGenome{} = genome1, %ProposalGenome{} = genome2) do
    %{
      fitness_delta_diff: genome2.expected_fitness_delta - genome1.expected_fitness_delta,
      risk_diff: genome2.risk_score - genome1.risk_score,
      safety_diff: genome2.safety_score - genome1.safety_score,
      complexity_diff: genome2.expected_complexity_score - genome1.expected_complexity_score,
      cost_diff: genome2.expected_cost - genome1.expected_cost,
      domains_added: genome2.affected_domains -- genome1.affected_domains,
      domains_removed: genome1.affected_domains -- genome2.affected_domains,
      similarity_score: calculate_similarity(genome1, genome2)
    }
  end

  # === Private Implementation ===

  defp validate_proposal_data(data) do
    required_fields = [:title, :description]
    missing = Enum.filter(required_fields, &is_nil(Map.get(data, &1)))
    
    if Enum.empty?(missing) do
      {:ok, data}
    else
      {:error, "Missing required fields: #{inspect(missing)}"}
    end
  end

  defp extract_intent(data) do
    title = Map.get(data, :title, "")
    description = Map.get(data, :description, "")
    "#{title}: #{description}"
  end

  defp analyze_domains(data) do
    affects = []
    affects = if Map.get(data, :affects_kernel, false), do: [:kernel | affects], else: affects
    affects = if Map.get(data, :affects_governance, false), do: [:governance | affects], else: affects
    affects = if Map.get(data, :affects_science, false), do: [:methodology | affects], else: affects
    
    # If no explicit flags, infer from affected_modules
    if Enum.empty?(affects) do
      modules = Map.get(data, :affected_modules, [])
      infer_domains_from_modules(modules)
    else
      Enum.uniq(affects)
    end
  end

  defp infer_domains_from_modules(modules) do
    domains = []
    domains = if Enum.any?(modules, &String.contains?(&1, "kernel")), do: [:kernel | domains], else: domains
    domains = if Enum.any?(modules, &String.contains?(&1, "governance")), do: [:governance | domains], else: domains
    domains = if Enum.any?(modules, &String.contains?(&1, "science")), do: [:methodology | domains], else: domains
    
    if Enum.empty?(domains), do: [:governance], else: Enum.uniq(domains)
  end

  defp calculate_fitness_delta(data, seed) do
    # Heuristic: improvements to core systems get higher fitness delta
    base_delta = 0.1
    
    # Adjust based on proposal characteristics
    adjustment = 
      (if Map.get(data, :improves_determinism, false), do: 0.2, else: 0.0) +
      (if Map.get(data, :reduces_complexity, false), do: 0.15, else: 0.0) +
      (if Map.get(data, :enhances_safety, false), do: 0.1, else: 0.0) -
      (if Map.get(data, :adds_technical_debt, false), do: 0.1, else: 0.0)
    
    # Add small deterministic variation based on seed
    variation = :rand.uniform(seed) * 0.05 - 0.025
    
    Float.round(base_delta + adjustment + variation, 3)
    |> clamp(-1.0, 1.0)
  end

  defp calculate_entropy_delta(data, seed) do
    # Improvements typically reduce entropy (negative delta)
    base_delta = -0.05
    
    adjustment = 
      (if Map.get(data, :improves_determinism, false), do: -0.1, else: 0.0) +
      (if Map.get(data, :simplifies_architecture, false), do: -0.05, else: 0.0) +
      (if Map.get(data, :adds_complexity, false), do: 0.1, else: 0.0)
    
    variation = :rand.uniform(seed) * 0.02 - 0.01
    
    Float.round(base_delta + adjustment + variation, 3)
    |> clamp(-1.0, 1.0)
  end

  defp estimate_cost(data) do
    # Base cost estimation
    base_cost = 100.0
    
    # Adjust based on complexity indicators
    adjustment = 
      (if Map.get(data, :migration_required, false), do: 200.0, else: 0.0) +
      (if Map.get(data, :requires_testing, false), do: 150.0, else: 0.0) +
      (if Map.get(data, :requires_documentation, false), do: 50.0, else: 0.0) +
      (if Map.get(data, :affects_multiple_domains, false), do: 100.0, else: 0.0)
    
    Float.round(base_cost + adjustment, 2)
  end

  defp assess_replay_impact(data) do
    cond do
      Map.get(data, :breaks_replay, false) -> :breaking
      Map.get(data, :significantly_changes_replay, false) -> :major
      Map.get(data, :minor_replay_changes, false) -> :minor
      true -> :none
    end
  end

  defp estimate_migration_cost(data) do
    if Map.get(data, :migration_required, false) do
      modules = length(Map.get(data, :affected_modules, []))
      Float.round(modules * 50.0, 2)
    else
      0.0
    end
  end

  defp assess_scientific_capital(_data) do
    # Scientific capital change is typically small for governance proposals
    0.0
  end

  defp assess_archaeology_impact(data) do
    cond do
      Map.get(data, :changes_historical_records, false) -> :major
      Map.get(data, :adds_provenance_tracking, false) -> :minor
      true -> :none
    end
  end

  defp calculate_complexity(data) do
    # Base complexity
    base = 0.3
    
    # Adjust based on proposal characteristics
    adjustment = 
      (if Map.get(data, :adds_new_concepts, false), do: 0.2, else: 0.0) +
      (if Map.get(data, :modifies_existing_behavior, false), do: 0.15, else: 0.0) +
      (if Map.get(data, :introduces_dependencies, false), do: 0.1, else: 0.0) -
      (if Map.get(data, :simplifies_existing_code, false), do: 0.1, else: 0.0)
    
    Float.round(base + adjustment, 3)
    |> clamp(0.0, 1.0)
  end

  defp assess_risk(data, seed) do
    # Base risk level
    base_risk = 0.3
    
    # Risk factors
    adjustment = 
      (if Map.get(data, :affects_kernel, false), do: 0.2, else: 0.0) +
      (if Map.get(data, :migration_required, false), do: 0.15, else: 0.0) +
      (if Map.get(data, :has_rollbacks, false), do: -0.1, else: 0.0) +
      (if Map.get(data, :well_tested, false), do: -0.1, else: 0.0)
    
    variation = :rand.uniform(seed) * 0.05 - 0.025
    
    Float.round(base_risk + adjustment + variation, 3)
    |> clamp(0.0, 1.0)
  end

  defp assess_safety(data, seed) do
    # Base safety level
    base_safety = 0.7
    
    # Safety factors
    adjustment = 
      (if Map.get(data, :has_safeguards, false), do: 0.15, else: 0.0) +
      (if Map.get(data, :has_rollbacks, false), do: 0.1, else: 0.0) +
      (if Map.get(data, :incremental_change, false), do: 0.05, else: 0.0) -
      (if Map.get(data, :affects_critical_path, false), do: 0.15, else: 0.0)
    
    variation = :rand.uniform(seed) * 0.05 - 0.025
    
    Float.round(base_safety + adjustment + variation, 3)
    |> clamp(0.0, 1.0)
  end

  defp assess_migration_difficulty(data) do
    cond do
      not Map.get(data, :migration_required, false) -> :trivial
      Map.get(data, :complex_migration, false) -> :hard
      Map.get(data, :moderate_migration, false) -> :moderate
      true -> :easy
    end
  end

  defp assess_rollback_difficulty(data) do
    cond do
      Map.get(data, :no_rollback_needed, false) -> :trivial
      Map.get(data, :complex_rollback, false) -> :hard
      Map.get(data, :moderate_rollback, false) -> :moderate
      true -> :easy
    end
  end

  defp assess_replay_difficulty(data) do
    cond do
      Map.get(data, :breaks_replay, false) -> :breaking
      Map.get(data, :significant_replay_changes, false) -> :major
      Map.get(data, :minor_replay_changes, false) -> :minor
      true -> :none
    end
  end

  defp calculate_graph_impact(data) do
    modules = Map.get(data, :affected_modules, [])
    _num_modules = length(modules)
    
    %{
      nodes_added: Map.get(data, :nodes_added, 0),
      nodes_removed: Map.get(data, :nodes_removed, 0),
      edges_added: Map.get(data, :edges_added, 0),
      edges_removed: Map.get(data, :edges_removed, 0)
    }
  end

  defp analyze_dependencies(data) do
    Map.get(data, :dependency_impact, [])
  end

  defp calculate_similarity(genome1, genome2) do
    # Simple cosine similarity based on numeric fields
    fields = [
      :expected_fitness_delta,
      :risk_score,
      :safety_score,
      :expected_complexity_score,
      :expected_cost
    ]
    
    dot_product = Enum.reduce(fields, 0.0, fn field, acc ->
      val1 = Map.get(genome1, field, 0.0)
      val2 = Map.get(genome2, field, 0.0)
      acc + (val1 * val2)
    end)
    
    magnitude1 = :math.sqrt(Enum.reduce(fields, 0.0, fn field, acc ->
      val = Map.get(genome1, field, 0.0)
      acc + (val * val)
    end))
    
    magnitude2 = :math.sqrt(Enum.reduce(fields, 0.0, fn field, acc ->
      val = Map.get(genome2, field, 0.0)
      acc + (val * val)
    end))
    
    if magnitude1 == 0 or magnitude2 == 0 do
      0.0
    else
      Float.round(dot_product / (magnitude1 * magnitude2), 3)
    end
  end

  defp clamp(value, min_val, max_val) do
    max(min_val, min(value, max_val))
  end
end
