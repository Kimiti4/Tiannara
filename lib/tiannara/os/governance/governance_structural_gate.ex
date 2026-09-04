defmodule TiannaraOS.Governance.GovernanceStructuralGate do
  @moduledoc """
  GovernanceStructuralGate - Constitutional gatekeeper for all governance operations.

  This is the governance equivalent of StructuralValidationGate from Phase 13.
  It refuses execution if any governance invariant fails, ensuring that governance
  itself obeys constitutional discipline.

  ## Validation Pipeline

  ```
  GovernanceState
        ↓
  GovernanceStructuralGate
        ↓
  Replay Validation (INV-034)
        ↓
  Institution Validation (INV-031)
        ↓
  Appointment Validation (INV-032)
        ↓
  Capability Validation (INV-033)
        ↓
  Authority Validation (INV-035)
        ↓
  Execution (only if all pass)
  ```

  ## No Bypass Policy

  No governance operation may bypass this gate. Every proposal submission, review,
  ratification, deployment, and rollback must first pass structural validation.

  ## API

      @spec validate_governance_state(GovernanceState.t()) :: {:ok, report()} | {:error, violations()}
      @spec validate_before_proposal(map()) :: :authorized | {:unauthorized, String.t()}
      @spec validate_before_deployment(map()) :: :authorized | {:unauthorized, String.t()}
  """

  alias TiannaraOS.Governance.GovernanceState
  alias TiannaraOS.Governance.GovernanceReplayEngine
  alias TiannaraOS.Governance.InstitutionalProvenance
  alias TiannaraOS.Kernel.ConstitutionalInvariantRegistry

  defstruct [
    :validation_id,
    :timestamp,
    :governance_state_hash,
    :invariant_results,
    :replay_verification,
    :provenance_check,
    :authority_separation,
    :overall_status,
    :violations,
    :warnings
  ]

  @type t :: %__MODULE__{
          validation_id: String.t(),
          timestamp: DateTime.t(),
          governance_state_hash: String.t(),
          invariant_results: map(),
          replay_verification: atom(),
          provenance_check: atom(),
          authority_separation: atom(),
          overall_status: :pass | :fail,
          violations: [String.t()],
          warnings: [String.t()]
        }

  @doc """
  Validate entire governance state against all invariants.

  This is the primary structural gate that must pass before any governance operation.
  """
  @spec validate_governance_state(GovernanceState.t()) :: {:ok, t()} | {:error, t()}
  def validate_governance_state(%GovernanceState{} = state) do
    now = DateTime.utc_now()
    validation_id = generate_validation_id()
    state_hash = compute_state_hash(state)

    # Run all governance invariants
    invariant_results = run_all_governance_invariants(state)

    # Verify replay determinism
    replay_verification = verify_replay_determinism(state)

    # Check provenance integrity
    provenance_check = verify_provenance_integrity(state)

    # Verify authority separation
    authority_separation = verify_authority_separation(state)

    # Collect violations and warnings
    violations = collect_violations(invariant_results, replay_verification, provenance_check, authority_separation)
    warnings = collect_warnings(invariant_results)

    overall_status =
      if Enum.empty?(violations) and replay_verification == :match and
         provenance_check == :valid and authority_separation == :valid do
        :pass
      else
        :fail
      end

    report = %__MODULE__{
      validation_id: validation_id,
      timestamp: now,
      governance_state_hash: state_hash,
      invariant_results: invariant_results,
      replay_verification: replay_verification,
      provenance_check: provenance_check,
      authority_separation: authority_separation,
      overall_status: overall_status,
      violations: violations,
      warnings: warnings
    }

    case overall_status do
      :pass -> {:ok, report}
      :fail -> {:error, report}
    end
  end

  @doc """
  Validate before proposal submission.

  Checks that submitting actor has :can_propose capability through valid appointment.
  """
  @spec validate_before_proposal(map()) :: :authorized | {:unauthorized, String.t()}
  def validate_before_proposal(%{actor_id: actor_id, institution_id: inst_id}) do
    state = GovernanceState.capture_state()

    # Check actor membership
    members = GovernanceState.get_active_members(state, inst_id)

    if actor_id not in members do
      {:unauthorized, "Actor '#{actor_id}' is not an active member of institution '#{inst_id}'"}
    else
      # Check capability
      if GovernanceState.member_has_capability?(state, actor_id, :can_propose) do
        :authorized
      else
        {:unauthorized, "Actor '#{actor_id}' lacks :can_propose capability"}
      end
    end
  end

  @doc """
  Validate before deployment execution.

  Checks that Deployment Authority has proper authorization and safety clearance.
  """
  @spec validate_before_deployment(map()) :: :authorized | {:unauthorized, String.t()}
  def validate_before_deployment(%{institution_id: "deploy-auth-001", proposal_id: _proposal_id}) do
    state = GovernanceState.capture_state()

    # Verify Deployment Authority exists and is active
    case GovernanceState.get_institution(state, "deploy-auth-001") do
      nil ->
        {:unauthorized, "Deployment Authority institution not found"}

      inst ->
        if Map.get(inst, :status) != :active do
          {:unauthorized, "Deployment Authority is not active"}
        else
          # Check quorum
          members = GovernanceState.get_active_members(state, "deploy-auth-001")
          if length(members) < 2 do
            {:unauthorized, "Deployment Authority quorum not met (need 2, have #{length(members)})"}
          else
            :authorized
          end
        end
    end
  end

  @doc """
  Validate before ratification vote.

  Checks that Governance Council has quorum and proper authority.
  """
  @spec validate_before_ratification(map()) :: :authorized | {:unauthorized, String.t()}
  def validate_before_ratification(%{institution_id: "gov-council-001"}) do
    state = GovernanceState.capture_state()

    case GovernanceState.get_institution(state, "gov-council-001") do
      nil ->
        {:unauthorized, "Governance Council institution not found"}

      _inst ->
        members = GovernanceState.get_active_members(state, "gov-council-001")
        if length(members) < 5 do
          {:unauthorized, "Governance Council quorum not met (need 5, have #{length(members)})"}
        else
          :authorized
        end
    end
  end

  @doc """
  Get validation statistics.
  """
  @spec get_validation_stats() :: map()
  def get_validation_stats() do
    state = GovernanceState.capture_state()

    %{
      total_institutions: map_size(state.institutions),
      total_appointments: map_size(state.appointments),
      fitness: state.fitness,
      entropy: state.entropy,
      health: state.health,
      timestamp: DateTime.to_iso8601(state.timestamp)
    }
  end

  # Private helpers

  defp generate_validation_id() do
    "gov-validation-#{System.system_time(:millisecond)}-#{:erlang.unique_integer([:positive])}"
  end

  defp compute_state_hash(%GovernanceState{} = state) do
    hash_input = inspect(%{
      institutions: state.institutions,
      appointments: state.appointments,
      roles: state.roles,
      fitness: state.fitness,
      entropy: state.entropy,
      timestamp: state.timestamp
    })

    :crypto.hash(:sha256, hash_input) |> Base.encode16(case: :lower)
  end

  defp run_all_governance_invariants(%GovernanceState{} = state) do
    # Get governance ledger events
    ledger_events = TiannaraOS.Governance.GovernanceLedger.get_events()

    context = %{
      governance_ledger: ledger_events,
      governance_state: state,
      capability_graph: %{} # TODO: Load from CapabilityGraph module
    }

    # Run each governance invariant
    inv_031 = ConstitutionalInvariantRegistry.execute(:inv_031_institution_conservation, context)
    inv_032 = ConstitutionalInvariantRegistry.execute(:inv_032_appointment_conservation, context)
    inv_033 = ConstitutionalInvariantRegistry.execute(:inv_033_capability_provenance, context)
    inv_034 = ConstitutionalInvariantRegistry.execute(:inv_034_institution_replay, context)
    inv_035 = ConstitutionalInvariantRegistry.execute(:inv_035_authority_separation, context)

    %{
      inv_031_institution_conservation: inv_031,
      inv_032_appointment_conservation: inv_032,
      inv_033_capability_provenance: inv_033,
      inv_034_institution_replay: inv_034,
      inv_035_authority_separation: inv_035
    }
  end

  defp verify_replay_determinism(%GovernanceState{} = state) do
    case GovernanceReplayEngine.replay_full() do
      {:ok, replayed_state} ->
        GovernanceReplayEngine.verify_replay(state, replayed_state)

      {:error, _reason} ->
        {:mismatch, %{reason: :replay_failed}}
    end
  end

  defp verify_provenance_integrity(_state) do
    InstitutionalProvenance.verify_provenance_integrity()
  end

  defp verify_authority_separation(%GovernanceState{} = state) do
    GovernanceReplayEngine.verify_authority_separation(state)
  end

  defp collect_violations(invariant_results, replay_verification, provenance_check, authority_separation) do
    violations = []

    # Check invariant failures
    violations =
      invariant_results
      |> Enum.filter(fn {_key, result} -> match?({:fail, _}, result) end)
      |> Enum.map(fn {inv, {:fail, reason}} -> "#{inv}: #{reason}" end)
      |> Kernel.++(violations)

    # Check replay mismatch
    violations =
      if replay_verification != :match do
        violations ++ ["Replay verification failed: #{inspect(replay_verification)}"]
      else
        violations
      end

    # Check provenance
    violations =
      if provenance_check != :valid do
        violations ++ ["Provenance integrity check failed: #{inspect(provenance_check)}"]
      else
        violations
      end

    # Check authority separation
    violations =
      if authority_separation != :valid do
        violations ++ ["Authority separation violated: #{inspect(authority_separation)}"]
      else
        violations
      end

    violations
  end

  defp collect_warnings(_invariant_results) do
    # For now, no warnings - all issues are violations
    # In production, we might have medium-severity issues that warrant warnings
    []
  end
end
