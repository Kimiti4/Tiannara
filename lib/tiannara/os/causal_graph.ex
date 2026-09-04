defmodule TiannaraOS.CausalGraph do
  @moduledoc """
  CausalGraph - Constitutional artifact defining the complete causal dependency graph
  for all civilization metrics.

  This module is the SINGLE SOURCE OF TRUTH for metric definitions. No other component
  should embed its own understanding of metric relationships. All validators, dashboards,
  statistical analyses, and governance mechanisms must query this graph.

  ## Constitutional Role

  Every measurable quantity in Tiannara must have an explicit dependency chain terminating
  in canonical transactions (ResearchEpisode, TheoryFormationResult, etc.) or immutable
  scientific history. No metric may depend on:
  - adaptation_enabled flags
  - random seeds
  - simulation configuration
  - generation numbers

  Those are parameters—not scientific evidence.

  ## Usage

      # Build the complete causal graph
      graph = CausalGraph.build()

      # Get dependencies for a specific metric
      deps = CausalGraph.get_dependencies(graph, :scientific_capital)

      # Detect cycles (should return {:ok} if valid)
      case CausalValidator.detect_cycles(graph) do
        {:ok} -> IO.puts("No circular dependencies")
        {:error, cycles} -> IO.inspect(cycles, label: "Circular dependencies found")
      end

      # Verify reward leakage
      violations = CausalValidator.check_reward_leakage(graph)

  ## Architecture

  The causal graph consists of:
  - Nodes: Metrics, canonical transactions, research episodes
  - Edges: Dependency relationships with constitutional provenance
  - Root nodes: ResearchEpisode and other frozen canonical primitives
  - Leaf nodes: High-level composite metrics (CAI, Scientific Capital, etc.)

  Every path from leaf to root represents a complete causal chain.
  """

  @type node_id :: atom() | String.t()
  @type dependency_type :: :direct | :derived | :aggregated | :composite

  @type graph_node :: %{
    id: node_id(),
    type: :metric | :canonical_transaction | :research_episode | :raw_data,
    description: String.t(),
    constitutional_principle: String.t() | nil
  }

  @type graph_edge :: %{
    source: node_id(),
    destination: node_id(),
    dependency_type: dependency_type(),
    canonical_transaction: atom() | nil,
    constitutional_principle: String.t() | nil
  }

  @type graph :: %{
    nodes: [graph_node()],
    edges: [graph_edge()]
  }

  @doc """
  Build the complete causal dependency graph for all civilization metrics.

  Returns a graph structure with nodes (metrics, transactions, episodes) and edges
  (dependency relationships).

  ## Returns

  %{nodes: [...], edges: [...]}
  """
  def build() do
    nodes = build_nodes()
    edges = build_edges()

    %{nodes: nodes, edges: edges}
  end

  @doc """
  Get all dependencies for a specific metric.

  Returns the complete dependency chain from the metric down to canonical transactions.

  ## Parameters
  - `graph`: CausalGraph result from build/0
  - `metric_id`: Atom identifying the metric (e.g., :scientific_capital)

  ## Returns

  List of dependency chains, each chain is a list of node IDs from metric to root.
  """
  def get_dependencies(graph, metric_id) do
    find_all_paths(graph, metric_id, :root_nodes)
  end

  @doc """
  Get immediate dependencies for a metric (one level only).

  ## Parameters
  - `graph`: CausalGraph result from build/0
  - `metric_id`: Atom identifying the metric

  ## Returns

  List of immediate dependency node IDs.
  """
  def get_immediate_dependencies(graph, metric_id) do
    graph.edges
    |> Enum.filter(fn edge -> edge.destination == metric_id end)
    |> Enum.map(fn edge -> edge.source end)
  end

  @doc """
  Check if a metric depends (directly or indirectly) on another node.

  ## Parameters
  - `graph`: CausalGraph result from build/0
  - `metric_id`: The metric to check
  - `dependency_id`: The potential dependency

  ## Returns

  true if metric depends on dependency, false otherwise.
  """
  def depends_on?(graph, metric_id, dependency_id) do
    paths = find_all_paths(graph, metric_id, dependency_id)
    length(paths) > 0
  end

  @doc """
  Get all root nodes (canonical transactions and research episodes) in the graph.

  Root nodes are the foundational evidence sources—all metrics must ultimately trace
  back to these.

  ## Returns

  List of root node IDs.
  """
  def get_root_nodes(graph) do
    graph.nodes
    |> Enum.filter(fn node ->
      node.type in [:canonical_transaction, :research_episode]
    end)
    |> Enum.map(fn node -> node.id end)
  end

  @doc """
  Get all leaf nodes (high-level composite metrics) in the graph.

  Leaf nodes have no dependents—they are final outputs of the causal chain.

  ## Returns

  List of leaf node IDs.
  """
  def get_leaf_nodes(graph) do
    # Leaf nodes are metrics that don't appear as sources in any edge
    source_ids = Enum.map(graph.edges, fn edge -> edge.source end) |> MapSet.new()

    graph.nodes
    |> Enum.filter(fn node ->
      node.type == :metric and not MapSet.member?(source_ids, node.id)
    end)
    |> Enum.map(fn node -> node.id end)
  end

  @doc """
  Validate that every metric has a complete causal chain to a root node.

  ## Parameters
  - `graph`: CausalGraph result from build/0

  ## Returns

  {:ok} if all metrics have complete chains,
  {:error, incomplete_metrics} if some metrics lack root connections.
  """
  def validate_completeness(graph) do
    metric_nodes = Enum.filter(graph.nodes, fn node -> node.type == :metric end)

    incomplete = Enum.reject(metric_nodes, fn metric ->
      has_path_to_root?(graph, metric.id)
    end)

    if length(incomplete) == 0 do
      {:ok}
    else
      {:error, Enum.map(incomplete, fn node -> node.id end)}
    end
  end

  # ──────────────────────────────────────────────
  # Private: Node Definitions
  # ──────────────────────────────────────────────

  defp build_nodes() do
    # Canonical Transaction Nodes (ROOTS - immutable evidence sources)
    canonical_transactions = [
      %{id: :research_episode, type: :canonical_transaction,
        description: "Fundamental unit of institutional memory - groups related transactions into coherent investigations",
        constitutional_principle: "Principle 12 - Episodic Integrity"},

      %{id: :theory_formation_result, type: :canonical_transaction,
        description: "Result of theory formation process - creates/updates theoretical frameworks",
        constitutional_principle: "Theory Formation Protocol"},

      %{id: :distributed_validation_result, type: :canonical_transaction,
        description: "Result of distributed validation - validates theories across institutions",
        constitutional_principle: "Distributed Validation Protocol"},

      %{id: :institution_adaptation_result, type: :canonical_transaction,
        description: "Result of institution adaptation - proposes/adopts institutional changes",
        constitutional_principle: "Institution Adaptation Protocol"},

      %{id: :method_evolution_result, type: :canonical_transaction,
        description: "Result of method evolution - evolves research methods based on performance",
        constitutional_principle: "Method Evolution Protocol"},

      %{id: :civilization_adaptation_result, type: :canonical_transaction,
        description: "Result of civilization adaptation - adopts civilizational improvements",
        constitutional_principle: "Civilization Adaptation Protocol"},

      %{id: :belief_revision_result, type: :canonical_transaction,
        description: "Result of belief revision - updates epistemic beliefs based on evidence",
        constitutional_principle: "Belief Revision Protocol"},

      %{id: :research_cycle_result, type: :canonical_transaction,
        description: "Result of research cycle - executes hypothesis testing cycle",
        constitutional_principle: "Research Cycle Protocol"}
    ]

    # Raw Data Nodes (intermediate evidence)
    raw_data = [
      %{id: :episodes_created, type: :raw_data,
        description: "Count of research episodes generated in generation G",
        constitutional_principle: nil},

      %{id: :discoveries_made, type: :raw_data,
        description: "Count of discoveries produced through validated theories",
        constitutional_principle: nil},

      %{id: :theories_formed, type: :raw_data,
        description: "Count of theories created/updated in generation G",
        constitutional_principle: nil},

      %{id: :unknowns_resolved, type: :raw_data,
        description: "Count of unknown dependencies resolved through research",
        constitutional_principle: nil},

      %{id: :adaptations_evaluated, type: :raw_data,
        description: "Count of adaptations considered for adoption",
        constitutional_principle: nil},

      %{id: :adaptations_adopted, type: :raw_data,
        description: "Count of adaptations approved and adopted",
        constitutional_principle: nil},

      %{id: :credits_spent, type: :raw_data,
        description: "Total credits spent on research activities",
        constitutional_principle: nil},

      %{id: :budget_remaining, type: :raw_data,
        description: "Remaining budget after generation G",
        constitutional_principle: nil}
    ]

    # Metric Nodes (derived quantities)
    metrics = [
      # Scientific Capital - composite measure of accumulated knowledge
      %{id: :scientific_capital, type: :metric,
        description: "Accumulated value of validated scientific knowledge",
        constitutional_principle: "Scientific Capital Accumulation"},

      # Research Debt - unresolved unknowns
      %{id: :research_debt, type: :metric,
        description: "Level of unresolved unknown dependencies",
        constitutional_principle: "Research Debt Management"},

      # Research Velocity - discoveries per unit time
      %{id: :research_velocity, type: :metric,
        description: "Rate of discovery production (discoveries/generation)",
        constitutional_principle: nil},

      # Replication Success Rate
      %{id: :replication_success_rate, type: :metric,
        description: "Success rate of replication attempts",
        constitutional_principle: "Replication Protocol"},

      # Prediction Calibration
      %{id: :prediction_calibration, type: :metric,
        description: "Accuracy of predictions vs actual outcomes",
        constitutional_principle: "Prediction Assessment Protocol"},

      # Theory Stability
      %{id: :theory_stability, type: :metric,
        description: "Stability of theories over time (low variance = stable)",
        constitutional_principle: nil},

      # Innovation Velocity
      %{id: :innovation_velocity, type: :metric,
        description: "Rate of novel theory/method introduction",
        constitutional_principle: nil},

      # Discovery Rate
      %{id: :discovery_rate, type: :metric,
        description: "Discoveries per episode (efficiency metric)",
        constitutional_principle: nil},

      # Resource Efficiency
      %{id: :resource_efficiency, type: :metric,
        description: "Discoveries per credit spent (economic efficiency)",
        constitutional_principle: nil},

      # Budget Consumption
      %{id: :budget_consumption, type: :metric,
        description: "Rate of budget utilization over time",
        constitutional_principle: nil},

      # Civilization Adaptation Index (CAI)
      %{id: :civilization_adaptation_index, type: :metric,
        description: "Composite measure of civilizational health and improvement capacity",
        constitutional_principle: "Civilization Adaptation Index Calculation"},

      # Institution Diversity
      %{id: :institution_diversity, type: :metric,
        description: "Diversity of institutional specializations",
        constitutional_principle: "Institutional Diversity Principle"},

      # Method Diversity
      %{id: :method_diversity, type: :metric,
        description: "Diversity of research methods employed",
        constitutional_principle: "Methodological Diversity Principle"},

      # Collaboration Density
      %{id: :collaboration_density, type: :metric,
        description: "Network density of inter-institution collaboration",
        constitutional_principle: nil},

      # Transferability
      %{id: :transferability, type: :metric,
        description: "Success rate of cross-domain knowledge transfer",
        constitutional_principle: nil},

      # Robustness
      %{id: :robustness, type: :metric,
        description: "System resilience to perturbations",
        constitutional_principle: nil},

      # Knowledge Density
      %{id: :knowledge_density, type: :metric,
        description: "Knowledge per episode (compression metric)",
        constitutional_principle: nil},

      # Theory Compression
      %{id: :theory_compression, type: :metric,
        description: "Ratio of theories to observations (explanatory power)",
        constitutional_principle: nil},

      # Validation Success
      %{id: :validation_success, type: :metric,
        description: "Success rate of validation attempts",
        constitutional_principle: nil},

      # Unknown Resolution Rate
      %{id: :unknown_resolution_rate, type: :metric,
        description: "Rate at which unknowns are resolved",
        constitutional_principle: nil},

      # Adaptation Success Rate
      %{id: :adaptation_success_rate, type: :metric,
        description: "Success rate of adopted adaptations",
        constitutional_principle: nil},

      # Prediction Reliability
      %{id: :prediction_reliability, type: :metric,
        description: "Reliability of prediction assessments over time",
        constitutional_principle: nil},

      # Constitutional Violations
      %{id: :constitutional_violations, type: :metric,
        description: "Count of constitutional principle violations",
        constitutional_principle: "Constitutional Compliance Monitoring"},

      # Lifecycle Completeness
      %{id: :lifecycle_completeness_pct, type: :metric,
        description: "Percentage of lifecycle events completed",
        constitutional_principle: "Lifecycle Completeness Principle"},

      # Rollback Frequency
      %{id: :rollback_frequency, type: :metric,
        description: "Frequency of rollback operations (lower = more stable)",
        constitutional_principle: nil}
    ]

    canonical_transactions ++ raw_data ++ metrics
  end

  # ──────────────────────────────────────────────
  # Private: Edge Definitions (Dependency Relationships)
  # ──────────────────────────────────────────────

  defp build_edges() do
    # Scientific Capital causal chain
    scientific_capital_edges = [
      # scientific_capital <- discoveries_made + theories_formed + unknowns_resolved
      %{source: :discoveries_made, destination: :scientific_capital,
        dependency_type: :direct, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Validated discoveries contribute to capital"},

      %{source: :theories_formed, destination: :scientific_capital,
        dependency_type: :direct, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Validated theories contribute to capital"},

      %{source: :unknowns_resolved, destination: :scientific_capital,
        dependency_type: :direct, canonical_transaction: :distributed_validation_result,
        constitutional_principle: "Resolved unknowns contribute to capital"},

      # discoveries_made <- theory_formation_result <- research_episode
      %{source: :theory_formation_result, destination: :discoveries_made,
        dependency_type: :derived, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Discoveries emerge from theory formation"},

      # theories_formed <- theory_formation_result <- research_episode
      %{source: :theory_formation_result, destination: :theories_formed,
        dependency_type: :derived, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Theories emerge from theory formation"},

      # unknowns_resolved <- distributed_validation_result <- research_episode
      %{source: :distributed_validation_result, destination: :unknowns_resolved,
        dependency_type: :derived, canonical_transaction: :distributed_validation_result,
        constitutional_principle: "Unknown resolution emerges from validation"},

      # theory_formation_result <- research_episode
      %{source: :research_episode, destination: :theory_formation_result,
        dependency_type: :direct, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Theory formation belongs to research episode"},

      # distributed_validation_result <- research_episode
      %{source: :research_episode, destination: :distributed_validation_result,
        dependency_type: :direct, canonical_transaction: :distributed_validation_result,
        constitutional_principle: "Validation belongs to research episode"}
    ]

    # Research Debt causal chain
    research_debt_edges = [
      # research_debt <- unknowns_resolved (inversely related)
      %{source: :unknowns_resolved, destination: :research_debt,
        dependency_type: :derived, canonical_transaction: :distributed_validation_result,
        constitutional_principle: "Research debt decreases as unknowns are resolved"},

      # unknowns_resolved <- distributed_validation_result <- research_episode
      %{source: :distributed_validation_result, destination: :unknowns_resolved,
        dependency_type: :derived, canonical_transaction: :distributed_validation_result,
        constitutional_principle: "Unknown resolution emerges from validation"}
    ]

    # Research Velocity causal chain
    research_velocity_edges = [
      # research_velocity <- discoveries_made / episodes_created
      %{source: :discoveries_made, destination: :research_velocity,
        dependency_type: :derived, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Velocity depends on discovery rate"},

      %{source: :episodes_created, destination: :research_velocity,
        dependency_type: :derived, canonical_transaction: :research_episode,
        constitutional_principle: "Velocity normalized by episode count"}
    ]

    # Replication Success Rate causal chain
    replication_success_edges = [
      # replication_success_rate <- distributed_validation_result
      %{source: :distributed_validation_result, destination: :replication_success_rate,
        dependency_type: :derived, canonical_transaction: :distributed_validation_result,
        constitutional_principle: "Replication success measured through validation"},

      # distributed_validation_result <- research_episode
      %{source: :research_episode, destination: :distributed_validation_result,
        dependency_type: :direct, canonical_transaction: :distributed_validation_result,
        constitutional_principle: "Validation belongs to research episode"}
    ]

    # Prediction Calibration causal chain
    prediction_calibration_edges = [
      # prediction_calibration <- belief_revision_result
      %{source: :belief_revision_result, destination: :prediction_calibration,
        dependency_type: :derived, canonical_transaction: :belief_revision_result,
        constitutional_principle: "Prediction calibration assessed through belief revision"},

      # belief_revision_result <- research_episode
      %{source: :research_episode, destination: :belief_revision_result,
        dependency_type: :direct, canonical_transaction: :belief_revision_result,
        constitutional_principle: "Belief revision belongs to research episode"}
    ]

    # Theory Stability causal chain
    theory_stability_edges = [
      # theory_stability <- theories_formed (variance over time)
      %{source: :theories_formed, destination: :theory_stability,
        dependency_type: :aggregated, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Theory stability measured through temporal variance"},

      # theories_formed <- theory_formation_result <- research_episode
      %{source: :theory_formation_result, destination: :theories_formed,
        dependency_type: :derived, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Theories emerge from theory formation"}
    ]

    # Innovation Velocity causal chain
    innovation_velocity_edges = [
      # innovation_velocity <- method_evolution_result
      %{source: :method_evolution_result, destination: :innovation_velocity,
        dependency_type: :derived, canonical_transaction: :method_evolution_result,
        constitutional_principle: "Innovation velocity tracked through method evolution"},

      # method_evolution_result <- research_episode
      %{source: :research_episode, destination: :method_evolution_result,
        dependency_type: :direct, canonical_transaction: :method_evolution_result,
        constitutional_principle: "Method evolution belongs to research episode"}
    ]

    # Discovery Rate causal chain
    discovery_rate_edges = [
      # discovery_rate <- discoveries_made / episodes_created
      %{source: :discoveries_made, destination: :discovery_rate,
        dependency_type: :derived, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Discovery rate depends on total discoveries"},

      %{source: :episodes_created, destination: :discovery_rate,
        dependency_type: :derived, canonical_transaction: :research_episode,
        constitutional_principle: "Discovery rate normalized by episodes"}
    ]

    # Resource Efficiency causal chain
    resource_efficiency_edges = [
      # resource_efficiency <- discoveries_made / credits_spent
      %{source: :discoveries_made, destination: :resource_efficiency,
        dependency_type: :derived, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Efficiency depends on discoveries produced"},

      %{source: :credits_spent, destination: :resource_efficiency,
        dependency_type: :derived, canonical_transaction: :research_episode,
        constitutional_principle: "Efficiency normalized by resources consumed"}
    ]

    # Budget Consumption causal chain
    budget_consumption_edges = [
      # budget_consumption <- credits_spent
      %{source: :credits_spent, destination: :budget_consumption,
        dependency_type: :direct, canonical_transaction: :research_episode,
        constitutional_principle: "Budget consumption tracks spending"},

      # credits_spent <- research_episode
      %{source: :research_episode, destination: :credits_spent,
        dependency_type: :derived, canonical_transaction: :research_episode,
        constitutional_principle: "Spending emerges from research activities"}
    ]

    # CAI (Civilization Adaptation Index) causal chain
    cai_edges = [
      # CAI <- adaptation_success_rate * prediction_reliability * transferability *
      #        rollback_readiness * constitutional_compliance * scientific_diversity
      %{source: :adaptation_success_rate, destination: :civilization_adaptation_index,
        dependency_type: :composite, canonical_transaction: :institution_adaptation_result,
        constitutional_principle: "CAI includes observed improvement component"},

      %{source: :prediction_reliability, destination: :civilization_adaptation_index,
        dependency_type: :composite, canonical_transaction: :belief_revision_result,
        constitutional_principle: "CAI includes prediction reliability component"},

      %{source: :constitutional_violations, destination: :civilization_adaptation_index,
        dependency_type: :composite, canonical_transaction: :civilization_adaptation_result,
        constitutional_principle: "CAI includes constitutional compliance component"},

      %{source: :rollback_frequency, destination: :civilization_adaptation_index,
        dependency_type: :composite, canonical_transaction: :civilization_adaptation_result,
        constitutional_principle: "CAI includes rollback readiness component"},

      %{source: :institution_diversity, destination: :civilization_adaptation_index,
        dependency_type: :composite, canonical_transaction: :institution_adaptation_result,
        constitutional_principle: "CAI includes scientific diversity component"},

      %{source: :method_diversity, destination: :civilization_adaptation_index,
        dependency_type: :composite, canonical_transaction: :method_evolution_result,
        constitutional_principle: "CAI includes methodological diversity component"},

      # adaptation_success_rate <- adaptations_adopted / adaptations_evaluated
      %{source: :adaptations_adopted, destination: :adaptation_success_rate,
        dependency_type: :derived, canonical_transaction: :institution_adaptation_result,
        constitutional_principle: "Success rate calculated from adoption decisions"},

      %{source: :adaptations_evaluated, destination: :adaptation_success_rate,
        dependency_type: :derived, canonical_transaction: :institution_adaptation_result,
        constitutional_principle: "Success rate calculated from evaluation count"},

      # adaptations_adopted <- institution_adaptation_result
      %{source: :institution_adaptation_result, destination: :adaptations_adopted,
        dependency_type: :derived, canonical_transaction: :institution_adaptation_result,
        constitutional_principle: "Adoptions emerge from institution adaptation"},

      # adaptations_evaluated <- institution_adaptation_result
      %{source: :institution_adaptation_result, destination: :adaptations_evaluated,
        dependency_type: :derived, canonical_transaction: :institution_adaptation_result,
        constitutional_principle: "Evaluations emerge from institution adaptation"},

      # prediction_reliability <- belief_revision_result <- research_episode
      %{source: :belief_revision_result, destination: :prediction_reliability,
        dependency_type: :derived, canonical_transaction: :belief_revision_result,
        constitutional_principle: "Reliability assessed through belief revision"},

      # institution_diversity <- institution_adaptation_result <- research_episode
      %{source: :institution_adaptation_result, destination: :institution_diversity,
        dependency_type: :derived, canonical_transaction: :institution_adaptation_result,
        constitutional_principle: "Diversity tracked through institution adaptation"},

      # method_diversity <- method_evolution_result <- research_episode
      %{source: :method_evolution_result, destination: :method_diversity,
        dependency_type: :derived, canonical_transaction: :method_evolution_result,
        constitutional_principle: "Diversity tracked through method evolution"}
    ]

    # Institution Diversity causal chain
    institution_diversity_edges = [
      # institution_diversity <- institution_adaptation_result <- research_episode
      %{source: :institution_adaptation_result, destination: :institution_diversity,
        dependency_type: :derived, canonical_transaction: :institution_adaptation_result,
        constitutional_principle: "Institution diversity tracked through adaptation"}
    ]

    # Method Diversity causal chain
    method_diversity_edges = [
      # method_diversity <- method_evolution_result <- research_episode
      %{source: :method_evolution_result, destination: :method_diversity,
        dependency_type: :derived, canonical_transaction: :method_evolution_result,
        constitutional_principle: "Method diversity tracked through evolution"}
    ]

    # Collaboration Density (no direct canonical transaction - network property)
    collaboration_density_edges = [
      %{source: :research_episode, destination: :collaboration_density,
        dependency_type: :aggregated, canonical_transaction: :research_episode,
        constitutional_principle: "Collaboration density derived from episode contributor patterns"}
    ]

    # Transferability (cross-domain success)
    transferability_edges = [
      %{source: :institution_adaptation_result, destination: :transferability,
        dependency_type: :derived, canonical_transaction: :institution_adaptation_result,
        constitutional_principle: "Transferability measured through cross-domain adaptation success"}
    ]

    # Robustness (system resilience)
    robustness_edges = [
      %{source: :rollback_frequency, destination: :robustness,
        dependency_type: :derived, canonical_transaction: :civilization_adaptation_result,
        constitutional_principle: "Robustness inversely related to rollback frequency"},

      %{source: :constitutional_violations, destination: :robustness,
        dependency_type: :derived, canonical_transaction: :civilization_adaptation_result,
        constitutional_principle: "Robustness inversely related to violation count"}
    ]

    # Knowledge Density (knowledge per episode)
    knowledge_density_edges = [
      %{source: :theories_formed, destination: :knowledge_density,
        dependency_type: :derived, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Knowledge density depends on theory count"},

      %{source: :episodes_created, destination: :knowledge_density,
        dependency_type: :derived, canonical_transaction: :research_episode,
        constitutional_principle: "Knowledge density normalized by episode count"}
    ]

    # Theory Compression (explanatory power)
    theory_compression_edges = [
      %{source: :theories_formed, destination: :theory_compression,
        dependency_type: :derived, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Compression ratio depends on theory count"},

      %{source: :discoveries_made, destination: :theory_compression,
        dependency_type: :derived, canonical_transaction: :theory_formation_result,
        constitutional_principle: "Compression ratio depends on observation count"}
    ]

    # Validation Success
    validation_success_edges = [
      %{source: :distributed_validation_result, destination: :validation_success,
        dependency_type: :derived, canonical_transaction: :distributed_validation_result,
        constitutional_principle: "Validation success tracked through validation results"}
    ]

    # Unknown Resolution Rate
    unknown_resolution_rate_edges = [
      %{source: :unknowns_resolved, destination: :unknown_resolution_rate,
        dependency_type: :derived, canonical_transaction: :distributed_validation_result,
        constitutional_principle: "Resolution rate depends on unknowns resolved"},

      %{source: :episodes_created, destination: :unknown_resolution_rate,
        dependency_type: :derived, canonical_transaction: :research_episode,
        constitutional_principle: "Resolution rate normalized by episode count"}
    ]

    # Constitutional Violations
    constitutional_violations_edges = [
      %{source: :civilization_adaptation_result, destination: :constitutional_violations,
        dependency_type: :direct, canonical_transaction: :civilization_adaptation_result,
        constitutional_principle: "Violations detected during civilization adaptation"}
    ]

    # Lifecycle Completeness
    lifecycle_completeness_edges = [
      %{source: :research_episode, destination: :lifecycle_completeness_pct,
        dependency_type: :aggregated, canonical_transaction: :research_episode,
        constitutional_principle: "Completeness measured through episode lifecycle events"}
    ]

    # Rollback Frequency
    rollback_frequency_edges = [
      %{source: :civilization_adaptation_result, destination: :rollback_frequency,
        dependency_type: :direct, canonical_transaction: :civilization_adaptation_result,
        constitutional_principle: "Rollbacks tracked during civilization adaptation"}
    ]

    # Combine all edges
    scientific_capital_edges ++
    research_debt_edges ++
    research_velocity_edges ++
    replication_success_edges ++
    prediction_calibration_edges ++
    theory_stability_edges ++
    innovation_velocity_edges ++
    discovery_rate_edges ++
    resource_efficiency_edges ++
    budget_consumption_edges ++
    cai_edges ++
    institution_diversity_edges ++
    method_diversity_edges ++
    collaboration_density_edges ++
    transferability_edges ++
    robustness_edges ++
    knowledge_density_edges ++
    theory_compression_edges ++
    validation_success_edges ++
    unknown_resolution_rate_edges ++
    constitutional_violations_edges ++
    lifecycle_completeness_edges ++
    rollback_frequency_edges
  end

  # ──────────────────────────────────────────────
  # Private: Graph Traversal Helpers
  # ──────────────────────────────────────────────

  defp find_all_paths(graph, start_node, target_node) when target_node == :root_nodes do
    root_nodes = get_root_nodes(graph)
    Enum.flat_map(root_nodes, fn root ->
      find_paths(graph, start_node, root, [])
    end)
  end

  defp find_all_paths(graph, start_node, target_node) do
    find_paths(graph, start_node, target_node, [])
  end

  defp find_paths(_graph, current, target, path) when current == target do
    [Enum.reverse([current | path])]
  end

  defp find_paths(graph, current, target, visited) do
    if Enum.member?(visited, current) do
      []  # Avoid cycles
    else
      new_visited = [current | visited]

      # Find outgoing edges from current node
      outgoing_edges = Enum.filter(graph.edges, fn edge -> edge.destination == current end)

      Enum.flat_map(outgoing_edges, fn edge ->
        find_paths(graph, edge.source, target, new_visited)
      end)
    end
  end

  defp has_path_to_root?(graph, node_id) do
    root_nodes = get_root_nodes(graph)
    Enum.any?(root_nodes, fn root ->
      length(find_paths(graph, node_id, root, [])) > 0
    end)
  end
end
