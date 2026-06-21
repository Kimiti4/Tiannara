defmodule Tiannara.ASC.Observatory.Metrics do
  @moduledoc """
  The core measurement struct for the ASC Project Observatory.

  Captures every dimension of engineering performance across a project's
  lifetime. These measurements are the raw material from which the
  `ASC.Laws.Discoverer` extracts software engineering laws.

  ## Fields

    * `architecture_fitness`   — composite fitness of the selected architecture genome (0.0–1.0)
    * `bug_discovery_rate`     — bugs found per test run cycle
    * `repair_success_rate`    — fraction of self-repair attempts that resolved the issue
    * `test_effectiveness`     — ratio of tests that found real defects vs total tests generated
    * `api_fitness`            — composite API genome fitness across all project APIs
    * `deployment_readiness`   — fraction of deployment checklist items satisfied
    * `long_term_stability`    — rolling stability score from Operations (0.0–1.0)
    * `architecture_style`     — style atom of the selected architecture (for law discovery)
    * `team_size_proxy`        — number of sub-civilization agents active (proxy for team size)
    * `phase_durations`        — map of phase → milliseconds taken
    * `crucible_iterations`    — number of Builder/Breaker/Attacker/Validator loops required
    * `meta_learning_applied`  — number of meta-learning insights applied to this project
  """

  @derive Jason.Encoder
  defstruct [
    project_id: nil,
    # Tier 0 — Bootstrap metrics (from Requirements/Testing/Implementation)
    requirements_completeness: 0.0,
    invariant_count: 0,
    capability_count: 0,
    constraint_count: 0,
    test_contract_count: 0,
    source_file_count: 0,
    # Phase 3 — Implementation Planning metrics
    component_count: 0,
    dependency_count: 0,
    validation_rule_count: 0,
    workflow_count: 0,
    implementation_complexity: 0.0,
    architecture_style: nil,
    # Phase 3.5 — Executable Generation metrics
    compile_success_rate: 0.0,
    compile_iterations: 0,
    compile_error_count: 0,
    test_pass_rate: 0.0,
    generation_duration_ms: 0,
    # Phase 3.6 — Interface Evolution metrics
    interface_contract_count: 0,
    interface_event_count: 0,
    interface_protocol_count: 0,
    interface_fitness: 0.0,
    interface_complexity: 0.0,
    contract_reuse_rate: 0.0,
    schema_reuse_rate: 0.0,
    compatibility_score: 0.0,
    evolution_generation: 0,
    interface_mutation_count: 0,
    contract_mutation_count: 0,
    event_mutation_count: 0,
    protocol_mutation_count: 0,
    successful_mutations: 0,
    reverted_mutations: 0,
    mutation_diversity: 0.0,
    # Phase 3.6C — Population & Ecology metrics
    species_count: 0,
    extinction_rate: 0.0,
    diversity_index: 0.0,
    lineage_depth: 0,
    dominant_species: nil,
    cross_species_transfer_rate: 0.0,
    knowledge_reuse_rate: 0.0,
    # Phase 4 — Crucible Civilization metrics
    failure_count: 0,
    failure_density: 0.0,
    failure_recurrence_rate: 0.0,
    critical_failure_count: 0,
    recoverable_failure_count: 0,
    invariant_breach_count: 0,
    constraint_breach_count: 0,
    survivability_score: 0.0,
    mean_time_to_failure: 0.0,
    mean_time_to_recovery: 0.0,
    resilience_score: 0.0,
    adaptation_rate: 0.0,
    # Tier 1+ — Operational metrics (from Crucible/Operations/MetaLearning)
    architecture_fitness: 0.0,
    bug_discovery_rate: 0.0,
    repair_success_rate: 0.0,
    test_effectiveness: 0.0,
    api_fitness: 0.0,
    deployment_readiness: 0.0,
    long_term_stability: 0.0,
    team_size_proxy: 0,
    phase_durations: %{},
    crucible_iterations: 0,
    meta_learning_applied: 0,
    recorded_at: nil
  ]

  @type t :: %__MODULE__{
    project_id: String.t() | nil,
    # Tier 0
    requirements_completeness: float(),
    invariant_count: non_neg_integer(),
    capability_count: non_neg_integer(),
    constraint_count: non_neg_integer(),
    test_contract_count: non_neg_integer(),
    source_file_count: non_neg_integer(),
    # Phase 3
    component_count: non_neg_integer(),
    dependency_count: non_neg_integer(),
    validation_rule_count: non_neg_integer(),
    workflow_count: non_neg_integer(),
    implementation_complexity: float(),
    architecture_style: atom() | nil,
    # Phase 3.5
    compile_success_rate: float(),
    compile_iterations: non_neg_integer(),
    compile_error_count: non_neg_integer(),
    test_pass_rate: float(),
    generation_duration_ms: non_neg_integer(),
    # Phase 3.6
    interface_contract_count: non_neg_integer(),
    interface_event_count: non_neg_integer(),
    interface_protocol_count: non_neg_integer(),
    interface_fitness: float(),
    interface_complexity: float(),
    contract_reuse_rate: float(),
    schema_reuse_rate: float(),
    compatibility_score: float(),
    evolution_generation: non_neg_integer(),
    interface_mutation_count: non_neg_integer(),
    contract_mutation_count: non_neg_integer(),
    event_mutation_count: non_neg_integer(),
    protocol_mutation_count: non_neg_integer(),
    successful_mutations: non_neg_integer(),
    reverted_mutations: non_neg_integer(),
    mutation_diversity: float(),
    # Phase 3.6C
    species_count: non_neg_integer(),
    extinction_rate: float(),
    diversity_index: float(),
    lineage_depth: non_neg_integer(),
    dominant_species: String.t() | nil,
    cross_species_transfer_rate: float(),
    knowledge_reuse_rate: float(),
    # Phase 4
    failure_count: non_neg_integer(),
    failure_density: float(),
    failure_recurrence_rate: float(),
    critical_failure_count: non_neg_integer(),
    recoverable_failure_count: non_neg_integer(),
    invariant_breach_count: non_neg_integer(),
    constraint_breach_count: non_neg_integer(),
    survivability_score: float(),
    mean_time_to_failure: float(),
    mean_time_to_recovery: float(),
    resilience_score: float(),
    adaptation_rate: float(),
    # Tier 1+
    architecture_fitness: float(),
    bug_discovery_rate: float(),
    repair_success_rate: float(),
    test_effectiveness: float(),
    api_fitness: float(),
    deployment_readiness: float(),
    long_term_stability: float(),
    team_size_proxy: non_neg_integer(),
    phase_durations: map(),
    crucible_iterations: non_neg_integer(),
    meta_learning_applied: non_neg_integer(),
    recorded_at: DateTime.t() | nil
  }

  @doc "Return a blank metrics struct for a project."
  @spec new(String.t()) :: t()
  def new(project_id) do
    %__MODULE__{project_id: project_id, recorded_at: DateTime.utc_now()}
  end

  @doc "Compute a single-number composite observatory score (0.0–1.0)."
  @spec composite_score(t()) :: float()
  def composite_score(%__MODULE__{} = m) do
    weights = [
      {m.architecture_fitness, 0.20},
      {m.test_effectiveness,    0.20},
      {m.long_term_stability,   0.20},
      {m.api_fitness,           0.15},
      {m.repair_success_rate,   0.15},
      {m.deployment_readiness,  0.10}
    ]

    Enum.reduce(weights, 0.0, fn {val, w}, acc -> acc + val * w end)
    |> Float.round(4)
  end
end
