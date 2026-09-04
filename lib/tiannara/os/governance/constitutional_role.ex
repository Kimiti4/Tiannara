defmodule TiannaraOS.Governance.ConstitutionalRole do
  @moduledoc """
  ConstitutionalRole - Defines authority and responsibility boundaries for governance actors.

  Roles are bundles of specific capabilities. No role has universal authority.
  This enforces the principle of least privilege in constitutional governance.

  ## Standard Roles

  1. **Architect** - Maintains architectural integrity
  2. **Scientist** - Ensures scientific validity
  3. **Auditor** - Verifies compliance and detects drift
  4. **Safety Officer** - Assesses risks and ensures rollback viability
  5. **Deployment Officer** - Executes migrations at generation boundaries
  6. **Replay Officer** - Maintains replay integrity across versions
  7. **Migration Officer** - Plans and validates migration paths
  8. **Governance Council Member** - Votes on ratifications

  ## Capabilities

  Each role is granted specific capabilities from this set:
  - `:can_review` - Can review proposals
  - `:can_deploy` - Can execute deployments
  - `:can_rollback` - Can trigger rollbacks
  - `:can_ratify` - Can vote on ratifications
  - `:can_observe` - Can observe governance state (read-only)
  - `:can_simulate` - Can run simulations
  - `:can_propose` - Can submit proposals
  - `:can_migrate` - Can plan migrations
  - `:can_audit` - Can audit compliance

  ## API

      @spec get_standard_roles() :: [t()]
      @spec has_capability?(role :: t(), capability()) :: boolean()
      @spec validate_role(role :: t()) :: :valid | {:invalid, [String.t()]}
  """

  defstruct [
    :role_id,                    # "role_architect", "role_scientist", etc.
    :name,                       # Human-readable name
    :authority,                  # [capability()] - what this role CAN do
    :responsibility,             # [String.t()] - what this role MUST maintain
    :appointment_process,        # String.t() - how role holders are selected
    :term_length_days,           # non_neg_integer() | :indefinite
    :removal_conditions          # [String.t()] - when role can be revoked
  ]

  @type t :: %__MODULE__{
          role_id: String.t(),
          name: String.t(),
          authority: [capability()],
          responsibility: [String.t()],
          appointment_process: String.t(),
          term_length_days: non_neg_integer() | :indefinite,
          removal_conditions: [String.t()]
        }

  @type capability ::
          :can_review |
          :can_deploy |
          :can_rollback |
          :can_ratify |
          :can_observe |
          :can_simulate |
          :can_propose |
          :can_migrate |
          :can_audit

  @doc """
  Get all 8 standard constitutional roles with their capabilities and responsibilities.
  """
  @spec get_standard_roles() :: [t()]
  def get_standard_roles() do
    [
      %__MODULE__{
        role_id: "role_architect",
        name: "Architect",
        authority: [:can_review, :can_propose, :can_audit],
        responsibility: [
          "Maintain architectural integrity across layers",
          "Prevent layer violations (Science ↔ Governance separation)",
          "Ensure kernel immutability is preserved",
          "Review proposals for architectural consistency"
        ],
        appointment_process: "Appointed by Governance Council based on technical expertise",
        term_length_days: 365,
        removal_conditions: [
          "Repeated architectural violations",
          "Failure to detect layer violations",
          "Voluntary resignation"
        ]
      },
      %__MODULE__{
        role_id: "role_scientist",
        name: "Scientist",
        authority: [:can_propose, :can_simulate, :can_observe],
        responsibility: [
          "Ensure scientific validity of proposals",
          "Validate simulation methodology",
          "Assess statistical significance",
          "Verify evidence quality"
        ],
        appointment_process: "Appointed by Review Board based on scientific credentials",
        term_length_days: 365,
        removal_conditions: [
          "Approval of scientifically invalid proposals",
          "Methodological errors in simulations",
          "Voluntary resignation"
        ]
      },
      %__MODULE__{
        role_id: "role_auditor",
        name: "Auditor",
        authority: [:can_audit, :can_observe, :can_review],
        responsibility: [
          "Verify compliance with constitutional invariants",
          "Detect drift in governance processes",
          "Audit trail completeness",
          "Report violations to Governance Council"
        ],
        appointment_process: "Appointed by Observatory Council based on audit expertise",
        term_length_days: 365,
        removal_conditions: [
          "Failure to detect invariant violations",
          "Incomplete audit trails",
          "Voluntary resignation"
        ]
      },
      %__MODULE__{
        role_id: "role_safety_officer",
        name: "Safety Officer",
        authority: [:can_review, :can_rollback],
        responsibility: [
          "Assess risks of proposed changes",
          "Ensure rollback viability before deployment",
          "Monitor deployment safety metrics",
          "Trigger rollback on safety violations"
        ],
        appointment_process: "Appointed by Deployment Authority based on risk assessment expertise",
        term_length_days: 365,
        removal_conditions: [
          "Approval of unsafe deployments",
          "Failure to verify rollback paths",
          "Voluntary resignation"
        ]
      },
      %__MODULE__{
        role_id: "role_deployment_officer",
        name: "Deployment Officer",
        authority: [:can_deploy, :can_migrate],
        responsibility: [
          "Execute migrations at generation boundaries only",
          "Verify deployment prerequisites",
          "Monitor deployment success metrics",
          "Coordinate with Safety Officer on rollback readiness"
        ],
        appointment_process: "Appointed by Deployment Authority based on operational expertise",
        term_length_days: 365,
        removal_conditions: [
          "Deployment outside generation boundary",
          "Failure to verify prerequisites",
          "Voluntary resignation"
        ]
      },
      %__MODULE__{
        role_id: "role_replay_officer",
        name: "Replay Officer",
        authority: [:can_observe, :can_audit],
        responsibility: [
          "Maintain replay integrity across constitutional versions",
          "Verify deterministic reconstruction of historical states",
          "Monitor replay success rates",
          "Report replay failures to Observatory Council"
        ],
        appointment_process: "Appointed by Observatory Council based on reproducibility expertise",
        term_length_days: 365,
        removal_conditions: [
          "Failure to detect replay divergence",
          "Incomplete replay verification",
          "Voluntary resignation"
        ]
      },
      %__MODULE__{
        role_id: "role_migration_officer",
        name: "Migration Officer",
        authority: [:can_migrate, :can_rollback],
        responsibility: [
          "Plan and validate migration paths",
          "Estimate migration complexity and downtime",
          "Create rollback checkpoints",
          "Verify migration compatibility"
        ],
        appointment_process: "Appointed by Deployment Authority based on migration expertise",
        term_length_days: 365,
        removal_conditions: [
          "Failed migration planning",
          "Inadequate rollback preparation",
          "Voluntary resignation"
        ]
      },
      %__MODULE__{
        role_id: "role_governance_council_member",
        name: "Governance Council Member",
        authority: [:can_ratify, :can_review],
        responsibility: [
          "Vote on proposal ratifications",
          "Ensure quorum requirements are met",
          "Apply decision rules correctly (unanimous/supermajority/majority)",
          "Represent institutional interests in governance decisions"
        ],
        appointment_process: "Elected by institutions based on governance experience",
        term_length_days: 730,
        removal_conditions: [
          "Violation of decision rules",
          "Failure to maintain quorum",
          "Loss of institutional support",
          "Voluntary resignation"
        ]
      }
    ]
  end

  @doc """
  Check if a role has a specific capability.
  """
  @spec has_capability?(t(), capability()) :: boolean()
  def has_capability?(%__MODULE__{authority: authority}, capability) do
    capability in authority
  end

  @doc """
  Validate that a role definition is correct.

  Checks:
  1. Role ID follows naming convention
  2. At least one capability is granted
  3. No role has all capabilities (prevents universal authority)
  4. Responsibilities are non-empty
  """
  @spec validate_role(t()) :: :valid | {:invalid, [String.t()]}
  def validate_role(%__MODULE__{} = role) do
    errors = []

    # Check role_id format
    errors =
      if String.starts_with?(role.role_id, "role_") do
        errors
      else
        errors ++ ["Role ID must start with 'role_'"]
      end

    # Check at least one capability
    errors =
      if length(role.authority) > 0 do
        errors
      else
        errors ++ ["Role must have at least one capability"]
      end

    # Check no universal authority (all 9 capabilities)
    all_capabilities = [
      :can_review,
      :can_deploy,
      :can_rollback,
      :can_ratify,
      :can_observe,
      :can_simulate,
      :can_propose,
      :can_migrate,
      :can_audit
    ]

    errors =
      if length(role.authority) < length(all_capabilities) do
        errors
      else
        errors ++ ["No role may have universal authority (all capabilities)"]
      end

    # Check responsibilities non-empty
    errors =
      if length(role.responsibility) > 0 do
        errors
      else
        errors ++ ["Role must have at least one responsibility"]
      end

    if Enum.empty?(errors) do
      :valid
    else
      {:invalid, errors}
    end
  end

  @doc """
  Get role by ID.
  """
  @spec get_role(String.t()) :: t() | nil
  def get_role(role_id) do
    Enum.find(get_standard_roles(), fn role -> role.role_id == role_id end)
  end

  @doc """
  List all available capabilities.
  """
  @spec list_capabilities() :: [capability()]
  def list_capabilities() do
    [
      :can_review,
      :can_deploy,
      :can_rollback,
      :can_ratify,
      :can_observe,
      :can_simulate,
      :can_propose,
      :can_migrate,
      :can_audit
    ]
  end
end
