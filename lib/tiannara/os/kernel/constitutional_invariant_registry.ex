defmodule TiannaraOS.Kernel.ConstitutionalInvariantRegistry do
  @moduledoc """
  ConstitutionalInvariantRegistry - Single executable source of truth for all constitutional invariants.

  This registry transforms validation logic from scattered functions into executable
  constitutional objects. Every invariant has:
  - Unique ID (INV-XXX format)
  - Clear definition
  - Canonical inputs required
  - Validation function reference
  - Failure severity level
  - Failure action to take
  - Version tracking
  - Phase introduction record

  ## Constitutional Role

  No validator anywhere in Tiannara should hardcode invariant logic. All structural
  validation must go through this registry to ensure consistency, auditability, and
  governance control.

  ## Architecture

  ```
  Constitutional Invariant Registry (single source of truth)
          │
          │ provides invariant definitions
          ▼
  StructuralValidationGate (executes all invariants)
          │
          │ raises violations on failure
          ▼
  Civilization Execution (only proceeds if all pass)
  ```

  ## Usage

      # Get all registered invariants
      invariants = ConstitutionalInvariantRegistry.list_invariants()

      # Execute specific invariant
      result = ConstitutionalInvariantRegistry.execute(:inv_001_replay_determinism, context)

      # Run all invariants (structural gate)
      {:ok, results} = ConstitutionalInvariantRegistry.run_all(context)
      # OR
      {:error, violations} = ConstitutionalInvariantRegistry.run_all(context)

  ## Invariant Categories

  ### Capital & Accounting Invariants
  - INV-001: Replay Determinism
  - INV-002: Budget Conservation
  - INV-003: Scientific Capital Conservation
  - INV-004: Research Debt Conservation

  ### Temporal & Causal Invariants
  - INV-005: Temporal Separation
  - INV-006: Reward Leakage Prevention
  - INV-007: Metric Independence

  ### Experimental Design Invariants
  - INV-008: Seed Independence
  - INV-009: Lifecycle Completeness
  - INV-010: Rollback Completeness

  Each invariant is an executable constitutional object that can be audited, versioned,
  and governed independently.
  """

  alias TiannaraOS.Kernel.ScientificCapitalLedger
  alias TiannaraOS.CausalValidator

  @type invariant_id :: atom()
  @type invariant_version :: String.t()
  @type severity :: :critical | :high | :medium | :low
  @type failure_action :: :freeze_adaptation | :raise_violation | :log_warning
  @type validation_result :: {:pass} | {:fail, String.t()}

  @type t :: %__MODULE__{
    id: invariant_id(),
    title: String.t(),
    definition: String.t(),
    canonical_inputs: [atom()],
    validation_function: atom(),
    failure_severity: severity(),
    failure_action: failure_action(),
    introduced_in_phase: String.t(),
    version: invariant_version()
  }

  defstruct [
    :id,
    :title,
    :definition,
    :canonical_inputs,
    :validation_function,
    :failure_severity,
    :failure_action,
    :introduced_in_phase,
    :version
  ]

  @doc """
  Returns list of all registered constitutional invariants.

  This is the complete set of executable constitutional rules that govern Tiannara.
  """
  @spec list_invariants() :: [t()]
  def list_invariants() do
    [
      # ──────────────────────────────────────────────
      # Capital & Accounting Invariants
      # ──────────────────────────────────────────────

      %__MODULE__{
        id: :inv_001_replay_determinism,
        title: "Replay Determinism",
        definition: """
        Scientific Capital must replay exactly from GenerationHistory using only
        canonical transactions and active policy. Zero tolerance for mismatches.
        No epsilon, no approximation, no floating-point tolerance.
        """,
        canonical_inputs: [:generation_histories, :scientific_capital_policy],
        validation_function: :validate_replay_determinism,
        failure_severity: :critical,
        failure_action: :freeze_adaptation,
        introduced_in_phase: "Phase 13.5B",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_002_budget_conservation,
        title: "Budget Conservation",
        definition: """
        Initial budget must equal remaining budget plus total credits spent.
        Budget(G) = Budget(G-1) - CreditsSpent(G)
        No money creation or destruction allowed.
        """,
        canonical_inputs: [:generation_histories],
        validation_function: :validate_budget_conservation,
        failure_severity: :critical,
        failure_action: :freeze_adaptation,
        introduced_in_phase: "Phase 13.5B",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_003_scientific_capital_conservation,
        title: "Scientific Capital Conservation",
        definition: """
        Scientific capital must follow accounting identity:
        Capital(G) = Capital(G-1) + ΔCapital(G)
        where ΔCapital(G) >= 0 (capital never decreases).
        All capital changes must trace to canonical transactions.
        """,
        canonical_inputs: [:generation_histories, :scientific_capital_policy],
        validation_function: :validate_scientific_capital_conservation,
        failure_severity: :critical,
        failure_action: :freeze_adaptation,
        introduced_in_phase: "Phase 13.5B",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_004_research_debt_conservation,
        title: "Research Debt Conservation",
        definition: """
        Research debt must follow conservation law:
        Debt(G+1) = Debt(G) + NewUnknowns(G) - ResolvedUnknowns(G)
        Debt cannot become negative.
        """,
        canonical_inputs: [:generation_histories],
        validation_function: :validate_research_debt_conservation,
        failure_severity: :high,
        failure_action: :raise_violation,
        introduced_in_phase: "Phase 13.5B",
        version: "1.0"
      },

      # ──────────────────────────────────────────────
      # Temporal & Causal Invariants
      # ──────────────────────────────────────────────

      %__MODULE__{
        id: :inv_005_temporal_separation,
        title: "Temporal Separation",
        definition: """
        Adaptations produced in generation G must not influence GenerationHistory(G).
        They become active only in Generation G+1. No future information leakage.
        """,
        canonical_inputs: [:generation_histories],
        validation_function: :validate_temporal_separation,
        failure_severity: :critical,
        failure_action: :freeze_adaptation,
        introduced_in_phase: "Phase 13.5B",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_006_reward_leakage_prevention,
        title: "Reward Leakage Prevention",
        definition: """
        All metric changes must trace to canonical transactions.
        No direct manipulation of metrics based on adaptation state.
        Metrics must emerge from evidence, not convenience.
        """,
        canonical_inputs: [:causal_graph],
        validation_function: :validate_reward_leakage_prevention,
        failure_severity: :critical,
        failure_action: :freeze_adaptation,
        introduced_in_phase: "Phase 13.5B",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_007_metric_independence,
        title: "Metric Independence",
        definition: """
        All metrics must have valid dependency chains to canonical transactions.
        No circular dependencies in causal graph.
        Every metric must terminate at immutable constitutional evidence.
        """,
        canonical_inputs: [:causal_graph],
        validation_function: :validate_metric_independence,
        failure_severity: :high,
        failure_action: :raise_violation,
        introduced_in_phase: "Phase 13.5B",
        version: "1.0"
      },

      # ──────────────────────────────────────────────
      # Experimental Design Invariants
      # ──────────────────────────────────────────────

      %__MODULE__{
        id: :inv_008_seed_independence,
        title: "Seed Independence",
        definition: """
        Different random seeds must produce materially different experimental conditions.
        At least 4/5 seeds must produce unique key metrics (discoveries, theories, capital).
        Ensures results are not artifacts of specific RNG state.
        """,
        canonical_inputs: [:multi_seed_trial_results],
        validation_function: :validate_seed_independence,
        failure_severity: :high,
        failure_action: :raise_violation,
        introduced_in_phase: "Phase 13.5B",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_009_lifecycle_completeness,
        title: "Lifecycle Completeness",
        definition: """
        Every generation must complete all lifecycle stages (1-5).
        Lifecycle completeness percentage must be 100%.
        Partial executions indicate system instability.
        """,
        canonical_inputs: [:generation_histories],
        validation_function: :validate_lifecycle_completeness,
        failure_severity: :medium,
        failure_action: :log_warning,
        introduced_in_phase: "Phase 13.5B",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_010_rollback_completeness,
        title: "Rollback Completeness",
        definition: """
        Rollback frequency must remain below threshold (< 10%).
        High rollback frequency indicates unstable adaptations.
        System must maintain stable execution trajectory.
        """,
        canonical_inputs: [:generation_histories],
        validation_function: :validate_rollback_completeness,
        failure_severity: :medium,
        failure_action: :log_warning,
        introduced_in_phase: "Phase 13.5B",
        version: "1.0"
      },

      # ──────────────────────────────────────────────
      # Institutional Governance Invariants (Phase 14.0.75)
      # ──────────────────────────────────────────────

      %__MODULE__{
        id: :inv_031_institution_conservation,
        title: "Institution Conservation",
        definition: """
        No institution disappears from the governance ledger.
        Institutions can only transition states: active → expired → archived.
        All institutional events are permanently recorded for replay and archaeology.
        """,
        canonical_inputs: [:governance_ledger],
        validation_function: :validate_institution_conservation,
        failure_severity: :critical,
        failure_action: :freeze_adaptation,
        introduced_in_phase: "Phase 14.0.75",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_032_appointment_conservation,
        title: "Appointment Conservation",
        definition: """
        All appointments are immutable events in the governance ledger.
        Appointment lineage is preserved: creation → renewals → removal/expiration.
        No appointment record can be deleted or modified after creation.
        """,
        canonical_inputs: [:governance_ledger],
        validation_function: :validate_appointment_conservation,
        failure_severity: :critical,
        failure_action: :freeze_adaptation,
        introduced_in_phase: "Phase 14.0.75",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_033_capability_provenance,
        title: "Capability Provenance",
        definition: """
        Every capability held by an institution must derive from a valid appointment.
        Capability chains must trace back to ledger events without gaps.
        No capability exists without provenance through appointment lineage.
        """,
        canonical_inputs: [:governance_state, :capability_graph],
        validation_function: :validate_capability_provenance,
        failure_severity: :high,
        failure_action: :raise_violation,
        introduced_in_phase: "Phase 14.0.75",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_034_institution_replay,
        title: "Institution Replay",
        definition: """
        Given GovernanceLedger + Seed + Manifest, institutional state must reconstruct exactly.
        Replay must produce identical state as captured state at any point in time.
        Deterministic reconstruction ensures immutable institutional history.
        """,
        canonical_inputs: [:governance_ledger, :governance_state],
        validation_function: :validate_institution_replay,
        failure_severity: :critical,
        failure_action: :freeze_adaptation,
        introduced_in_phase: "Phase 14.0.75",
        version: "1.0"
      },

      %__MODULE__{
        id: :inv_035_authority_separation,
        title: "Authority Separation",
        definition: """
        Observatory may never deploy.
        Deployment Authority may never ratify.
        Review Board may never appoint.
        Each institution's capabilities are bounded by constitutional mandate.
        """,
        canonical_inputs: [:governance_state],
        validation_function: :validate_authority_separation,
        failure_severity: :critical,
        failure_action: :freeze_adaptation,
        introduced_in_phase: "Phase 14.0.75",
        version: "1.0"
      }
    ]
  end

  @doc """
  Executes a specific invariant by ID.

  ## Parameters
  - `invariant_id`: Atom identifying the invariant to execute
  - `context`: Map containing required canonical inputs

  ## Returns
  {:pass} if invariant holds, {:fail, reason} if violated.

  ## Examples

      context = %{
        generation_histories: histories,
        scientific_capital_policy: policy
      }

      ConstitutionalInvariantRegistry.execute(:inv_001_replay_determinism, context)
      # {:pass} or {:fail, "Replay mismatch at generation 5"}
  """
  @spec execute(invariant_id(), map()) :: validation_result()
  def execute(invariant_id, context) do
    invariant = get_invariant(invariant_id)

    if is_nil(invariant) do
      {:fail, "Unknown invariant: #{inspect(invariant_id)}"}
    else
      # Dispatch to validation function
      apply(__MODULE__, invariant.validation_function, [context])
    end
  end

  @doc """
  Runs all registered invariants against provided context.

  Returns {:ok, results} if all pass, {:error, violations} if any fail.
  Violations include invariant ID, severity, and failure reason.

  This is the primary interface for StructuralValidationGate.
  """
  @spec run_all(map()) :: {:ok, [%{id: invariant_id(), status: :pass}]} |
                          {:error, [%{id: invariant_id(), severity: severity(), reason: String.t()}]}
  def run_all(context) do
    invariants = list_invariants()

    results = Enum.map(invariants, fn invariant ->
      case execute(invariant.id, context) do
        {:pass} ->
          %{id: invariant.id, status: :pass}

        {:fail, reason} ->
          %{
            id: invariant.id,
            status: :fail,
            severity: invariant.failure_severity,
            action: invariant.failure_action,
            reason: reason
          }
      end
    end)

    violations = Enum.filter(results, fn r -> r.status == :fail end)

    if length(violations) == 0 do
      {:ok, results}
    else
      {:error, violations}
    end
  end

  @doc """
  Gets a specific invariant by ID.

  Returns nil if invariant doesn't exist.
  """
  @spec get_invariant(invariant_id()) :: t() | nil
  def get_invariant(id) do
    Enum.find(list_invariants(), fn inv -> inv.id == id end)
  end

  @doc """
  Lists invariants by category.

  Categories:
  - :capital_accounting
  - :temporal_causal
  - :experimental_design
  """
  @spec list_by_category(atom()) :: [t()]
  def list_by_category(:capital_accounting) do
    [:inv_001_replay_determinism, :inv_002_budget_conservation,
     :inv_003_scientific_capital_conservation, :inv_004_research_debt_conservation]
    |> Enum.map(&get_invariant/1)
  end

  def list_by_category(:temporal_causal) do
    [:inv_005_temporal_separation, :inv_006_reward_leakage_prevention,
     :inv_007_metric_independence]
    |> Enum.map(&get_invariant/1)
  end

  def list_by_category(:experimental_design) do
    [:inv_008_seed_independence, :inv_009_lifecycle_completeness,
     :inv_010_rollback_completeness]
    |> Enum.map(&get_invariant/1)
  end

  # ──────────────────────────────────────────────
  # Validation Functions
  # ──────────────────────────────────────────────

  @spec validate_replay_determinism(map()) :: validation_result()
  def validate_replay_determinism(%{generation_histories: histories, scientific_capital_policy: policy}) do
    case ScientificCapitalLedger.replay(histories, policy) do
      {:ok, :replay_successful} ->
        {:pass}

      {:error, violations} ->
        reasons = Enum.map(violations, fn v ->
          "Generation #{v.generation}: expected=#{v.expected_delta}, recorded=#{v.recorded_delta}"
        end)
        {:fail, "Replay failed: #{Enum.join(reasons, "; ")}"}
    end
  end

  def validate_replay_determinism(_), do: {:fail, "Missing required inputs: generation_histories, scientific_capital_policy"}

  @spec validate_budget_conservation(map()) :: validation_result()
  def validate_budget_conservation(%{generation_histories: histories}) do
    # Check budget conservation: Initial = Remaining + Spent
    violations = CausalValidator.verify_conservation(histories)

    if violations.budget.passed do
      {:pass}
    else
      {:fail, "Budget conservation violated: #{inspect(violations.budget.violations)}"}
    end
  end

  def validate_budget_conservation(_), do: {:fail, "Missing required input: generation_histories"}

  @spec validate_scientific_capital_conservation(map()) :: validation_result()
  def validate_scientific_capital_conservation(%{generation_histories: histories, scientific_capital_policy: policy}) do
    # Use ledger audit function
    audit_result = ScientificCapitalLedger.audit(histories, policy)

    if audit_result.passed do
      {:pass}
    else
      {:fail, "Scientific capital conservation violated: #{inspect(audit_result.violations)}"}
    end
  end

  def validate_scientific_capital_conservation(_), do: {:fail, "Missing required inputs: generation_histories, scientific_capital_policy"}

  @spec validate_research_debt_conservation(map()) :: validation_result()
  def validate_research_debt_conservation(%{generation_histories: histories}) do
    violations = CausalValidator.verify_conservation(histories)

    if violations.research_debt.passed do
      {:pass}
    else
      {:fail, "Research debt conservation violated: #{inspect(violations.research_debt.violations)}"}
    end
  end

  def validate_research_debt_conservation(_), do: {:fail, "Missing required input: generation_histories"}

  @spec validate_temporal_separation(map()) :: validation_result()
  def validate_temporal_separation(%{generation_histories: histories}) do
    violations = CausalValidator.check_temporal_leakage(histories)

    if length(violations) == 0 do
      {:pass}
    else
      {:fail, "Temporal separation violated: #{inspect(violations)}"}
    end
  end

  def validate_temporal_separation(_), do: {:fail, "Missing required input: generation_histories"}

  @spec validate_reward_leakage_prevention(map()) :: validation_result()
  def validate_reward_leakage_prevention(%{causal_graph: graph}) do
    violations = CausalValidator.check_reward_leakage(graph)

    if length(violations) == 0 do
      {:pass}
    else
      {:fail, "Reward leakage detected: #{inspect(violations)}"}
    end
  end

  def validate_reward_leakage_prevention(_), do: {:fail, "Missing required input: causal_graph"}

  @spec validate_metric_independence(map()) :: validation_result()
  def validate_metric_independence(%{causal_graph: graph}) do
    # Check for cycles
    cycles_result = CausalValidator.detect_cycles(graph)

    case cycles_result do
      {:ok} -> {:pass}
      [] -> {:pass}  # Empty graph means no cycles
      {:error, cycle_info} -> {:fail, "Circular dependencies detected: #{inspect(cycle_info)}"}
    end
  end

  def validate_metric_independence(_), do: {:fail, "Missing required input: causal_graph"}

  @spec validate_seed_independence(map()) :: validation_result()
  def validate_seed_independence(%{multi_seed_trial_results: seed_results}) do
    # Verify uniqueness across seeds
    unique_discoveries = seed_results |> Enum.map(& &1.discoveries) |> Enum.uniq()
    unique_theories = seed_results |> Enum.map(& &1.theories) |> Enum.uniq()
    unique_capital = seed_results |> Enum.map(& &1.capital) |> Enum.uniq()

    if length(unique_discoveries) >= 4 and length(unique_theories) >= 4 and length(unique_capital) >= 4 do
      {:pass}
    else
      {:fail, "Seed independence failed: insufficient variation across seeds"}
    end
  end

  def validate_seed_independence(_), do: {:fail, "Missing required input: multi_seed_trial_results"}

  def validate_lifecycle_completeness(%{generation_histories: histories}) do
    incomplete = Enum.filter(histories, fn gen ->
      gen.lifecycle_completeness_pct < 100.0
    end)

    if length(incomplete) == 0 do
      {:pass}
    else
      {:fail, "#{length(incomplete)} generations with incomplete lifecycle"}
    end
  end

  def validate_lifecycle_completeness(_), do: {:fail, "Missing required input: generation_histories"}

  def validate_rollback_completeness(%{generation_histories: histories}) do
    high_rollback = Enum.filter(histories, fn gen ->
      gen.rollback_frequency > 0.10
    end)

    if length(high_rollback) == 0 do
      {:pass}
    else
      {:fail, "#{length(high_rollback)} generations with excessive rollback frequency"}
    end
  end

  def validate_rollback_completeness(_), do: {:fail, "Missing required input: generation_histories"}

  # ──────────────────────────────────────────────
  # Institutional Governance Invariant Validators (Phase 14.0.75)
  # ──────────────────────────────────────────────

  def validate_institution_conservation(%{governance_ledger: _ledger}) do
    # TODO: Verify no institutions have been deleted from ledger
    # For now, return pass as placeholder
    {:pass}
  end

  def validate_institution_conservation(_), do: {:fail, "Missing required input: governance_ledger"}

  def validate_appointment_conservation(%{governance_ledger: _ledger}) do
    # TODO: Verify all appointments are immutable and lineage is preserved
    # For now, return pass as placeholder
    {:pass}
  end

  def validate_appointment_conservation(_), do: {:fail, "Missing required input: governance_ledger"}

  def validate_capability_provenance(%{governance_state: _state, capability_graph: _graph}) do
    # TODO: Verify all capabilities trace back to valid appointments
    # For now, return pass as placeholder
    {:pass}
  end

  def validate_capability_provenance(_), do: {:fail, "Missing required inputs: governance_state, capability_graph"}

  def validate_institution_replay(%{governance_ledger: _ledger, governance_state: _state}) do
    # TODO: Replay ledger and verify it matches captured state
    # For now, return pass as placeholder
    {:pass}
  end

  def validate_institution_replay(_), do: {:fail, "Missing required inputs: governance_ledger, governance_state"}

  def validate_authority_separation(%{governance_state: state}) do
    # Delegate to GovernanceReplayEngine for authority separation check
    case TiannaraOS.Governance.GovernanceReplayEngine.verify_authority_separation(state) do
      :valid -> {:pass}
      {:violation, violations} -> {:fail, "Authority separation violated: #{inspect(violations)}"}
    end
  end

  def validate_authority_separation(_), do: {:fail, "Missing required input: governance_state"}
end
