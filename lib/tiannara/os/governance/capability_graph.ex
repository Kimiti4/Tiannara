defmodule TiannaraOS.Governance.CapabilityGraph do
  @moduledoc """
  CapabilityGraph - Graph-based capability structure for institutional governance.

  Instead of hardcoding capabilities in roles, this module maintains a graph
  where capabilities are nodes that can evolve independently. Roles reference
  capability nodes, enabling capability evolution without modifying every role.

  ## Graph Structure

  ```
  Capability Nodes:
    :can_review ──┐
    :can_deploy ──┼── Role: Deployment Officer
    :can_rollback ─┘
    
    :can_ratify ────────── Role: Governance Council Member
    :can_observe ───────── Role: Observatory (read-only)
  ```

  ## Evolution Pattern

  When a capability needs to change:
  1. Update capability node definition
  2. All roles referencing that node automatically inherit the change
  3. No need to modify individual role definitions

  ## API

      @spec add_capability(atom(), map()) :: {:ok, t()} | {:error, term()}
      @spec remove_capability(atom()) :: {:ok, t()} | {:error, term()}
      @spec assign_capability_to_role(atom(), String.t()) :: {:ok, t()} | {:error, term()}
      @spec get_role_capabilities(String.t()) :: [atom()]
  """

  defstruct [
    :capabilities,
    :role_assignments,
    :capability_dependencies,
    :timestamp
  ]

  @type t :: %__MODULE__{
          capabilities: map(),
          role_assignments: map(),
          capability_dependencies: map(),
          timestamp: DateTime.t()
        }

  @type capability_node :: %{
          id: atom(),
          name: String.t(),
          description: String.t(),
          category: atom(),
          metadata: map()
        }

  @doc """
  Initialize capability graph with standard capabilities.
  """
  @spec init_standard_graph() :: t()
  def init_standard_graph() do
    now = DateTime.utc_now()

    capabilities = %{
      can_review: %{
        id: :can_review,
        name: "Review",
        description: "Review proposals and evidence",
        category: :governance,
        metadata: %{requires_quorum: true}
      },
      can_deploy: %{
        id: :can_deploy,
        name: "Deploy",
        description: "Execute migrations at generation boundaries",
        category: :operational,
        metadata: %{safety_critical: true}
      },
      can_rollback: %{
        id: :can_rollback,
        name: "Rollback",
        description: "Revert deployments on safety violations",
        category: :operational,
        metadata: %{safety_critical: true}
      },
      can_ratify: %{
        id: :can_ratify,
        name: "Ratify",
        description: "Vote on constitutional amendments",
        category: :governance,
        metadata: %{requires_unanimous: false}
      },
      can_observe: %{
        id: :can_observe,
        name: "Observe",
        description: "Monitor system state (read-only)",
        category: :observational,
        metadata: %{no_governance_power: true}
      },
      can_simulate: %{
        id: :can_simulate,
        name: "Simulate",
        description: "Run constitutional simulations",
        category: :scientific,
        metadata: %{resource_intensive: true}
      },
      can_propose: %{
        id: :can_propose,
        name: "Propose",
        description: "Submit constitutional amendment proposals",
        category: :governance,
        metadata: %{requires_institutional_membership: true}
      },
      can_migrate: %{
        id: :can_migrate,
        name: "Migrate",
        description: "Plan and validate migration paths",
        category: :operational,
        metadata: %{requires_migration_plan: true}
      },
      can_audit: %{
        id: :can_audit,
        name: "Audit",
        description: "Audit compliance with constitutional invariants",
        category: :observational,
        metadata: %{full_access_required: true}
      },
      can_appoint_institutional_members: %{
        id: :can_appoint_institutional_members,
        name: "Appoint Members",
        description: "Appoint or remove institutional members",
        category: :governance,
        metadata: %{requires_supermajority: true}
      },
      can_remove_institutional_members: %{
        id: :can_remove_institutional_members,
        name: "Remove Members",
        description: "Remove institutional members",
        category: :governance,
        metadata: %{requires_supermajority: true}
      },
      can_amend_meta_constitution: %{
        id: :can_amend_meta_constitution,
        name: "Amend Meta-Constitution",
        description: "Modify meta-constitutional rules",
        category: :governance,
        metadata: %{requires_unanimous: true}
      },
      can_approve_budget: %{
        id: :can_approve_budget,
        name: "Approve Budget",
        description: "Approve governance budget allocations",
        category: :governance,
        metadata: %{financial_authority: true}
      },
      can_validate_theory: %{
        id: :can_validate_theory,
        name: "Validate Theory",
        description: "Validate scientific theories",
        category: :scientific,
        metadata: %{scientific_only: true}
      },
      can_assess_evidence: %{
        id: :can_assess_evidence,
        name: "Assess Evidence",
        description: "Assess quality of empirical evidence",
        category: :scientific,
        metadata: %{scientific_only: true}
      },
      can_certify_methodology: %{
        id: :can_certify_methodology,
        name: "Certify Methodology",
        description: "Certify research methodologies",
        category: :scientific,
        metadata: %{scientific_only: true}
      },
      can_reject_pseudoscience: %{
        id: :can_reject_pseudoscience,
        name: "Reject Pseudoscience",
        description: "Reject pseudoscientific claims",
        category: :scientific,
        metadata: %{scientific_only: true}
      },
      can_require_reproducibility: %{
        id: :can_require_reproducibility,
        name: "Require Reproducibility",
        description: "Require reproducible research results",
        category: :scientific,
        metadata: %{scientific_only: true}
      },
      can_request_simulation: %{
        id: :can_request_simulation,
        name: "Request Simulation",
        description: "Request additional simulations for proposals",
        category: :scientific,
        metadata: {}
      },
      can_recommend_approval: %{
        id: :can_recommend_approval,
        name: "Recommend Approval",
        description: "Recommend proposal approval to Governance Council",
        category: :governance,
        metadata: {}
      },
      can_recommend_rejection: %{
        id: :can_recommend_rejection,
        name: "Recommend Rejection",
        description: "Recommend proposal rejection",
        category: :governance,
        metadata: {}
      },
      can_request_revision: %{
        id: :can_request_revision,
        name: "Request Revision",
        description: "Request proposal revisions",
        category: :governance,
        metadata: {}
      },
      can_schedule_migration: %{
        id: :can_schedule_migration,
        name: "Schedule Migration",
        description: "Schedule deployment timing",
        category: :operational,
        metadata: {}
      },
      can_verify_deployment: %{
        id: :can_verify_deployment,
        name: "Verify Deployment",
        description: "Verify deployment success",
        category: :operational,
        metadata: {}
      },
      can_report_deployment_status: %{
        id: :can_report_deployment_status,
        name: "Report Deployment Status",
        description: "Report deployment outcomes to Observatory",
        category: :operational,
        metadata: {}
      },
      can_measure: %{
        id: :can_measure,
        name: "Measure",
        description: "Measure governance metrics",
        category: :observational,
        metadata: {}
      },
      can_report: %{
        id: :can_report,
        name: "Report",
        description: "Publish governance reports",
        category: :observational,
        metadata: {}
      },
      can_alert: %{
        id: :can_alert,
        name: "Alert",
        description: "Trigger alerts on anomalies",
        category: :observational,
        metadata: {}
      },
      can_publish_dashboards: %{
        id: :can_publish_dashboards,
        name: "Publish Dashboards",
        description: "Update observatory dashboards",
        category: :observational,
        metadata: {}
      }
    }

    %__MODULE__{
      capabilities: capabilities,
      role_assignments: %{},
      capability_dependencies: %{},
      timestamp: now
    }
  end

  @doc """
  Add new capability to graph.
  """
  @spec add_capability(t(), atom(), map()) :: {:ok, t()} | {:error, term()}
  def add_capability(%__MODULE__{} = graph, cap_id, metadata) when is_atom(cap_id) do
    if Map.has_key?(graph.capabilities, cap_id) do
      {:error, {:capability_exists, cap_id}}
    else
      capability = %{
        id: cap_id,
        name: metadata[:name] || Atom.to_string(cap_id),
        description: metadata[:description] || "",
        category: metadata[:category] || :general,
        metadata: Map.get(metadata, :metadata, %{})
      }

      updated = put_in(graph, [:capabilities, cap_id], capability)
      {:ok, %{updated | timestamp: DateTime.utc_now()}}
    end
  end

  @doc """
  Remove capability from graph.

  WARNING: This affects all roles referencing this capability.
  """
  @spec remove_capability(t(), atom()) :: {:ok, t()} | {:error, term()}
  def remove_capability(%__MODULE__{} = graph, cap_id) do
    if not Map.has_key?(graph.capabilities, cap_id) do
      {:error, {:capability_not_found, cap_id}}
    else
      # Check if any roles still reference this capability
      referencing_roles = find_roles_with_capability(graph, cap_id)

      if Enum.empty?(referencing_roles) do
        updated = update_in(graph, [:capabilities], &Map.delete(&1, cap_id))
        {:ok, %{updated | timestamp: DateTime.utc_now()}}
      else
        {:error, {:capability_in_use, %{cap_id: cap_id, roles: referencing_roles}}}
      end
    end
  end

  @doc """
  Assign capability to role.
  """
  @spec assign_capability_to_role(t(), atom(), String.t()) :: {:ok, t()} | {:error, term()}
  def assign_capability_to_role(%__MODULE__{} = graph, cap_id, role_id) do
    if not Map.has_key?(graph.capabilities, cap_id) do
      {:error, {:capability_not_found, cap_id}}
    else
      updated = update_in(graph, [:role_assignments, role_id], fn
        nil -> [cap_id]
        caps -> Enum.uniq(caps ++ [cap_id])
      end)

      {:ok, %{updated | timestamp: DateTime.utc_now()}}
    end
  end

  @doc """
  Remove capability from role.
  """
  @spec remove_capability_from_role(t(), atom(), String.t()) :: {:ok, t()} | {:error, term()}
  def remove_capability_from_role(%__MODULE__{} = graph, cap_id, role_id) do
    updated = update_in(graph, [:role_assignments, role_id], fn
      nil -> []
      caps -> List.delete(caps, cap_id)
    end)

    {:ok, %{updated | timestamp: DateTime.utc_now()}}
  end

  @doc """
  Get all capabilities assigned to a role.
  """
  @spec get_role_capabilities(t(), String.t()) :: [atom()]
  def get_role_capabilities(%__MODULE__{role_assignments: assignments}, role_id) do
    Map.get(assignments, role_id, [])
  end

  @doc """
  Get all roles that have a specific capability.
  """
  @spec get_roles_with_capability(t(), atom()) :: [String.t()]
  def get_roles_with_capability(%__MODULE__{role_assignments: assignments}, cap_id) do
    assignments
    |> Enum.filter(fn {_role, caps} -> cap_id in caps end)
    |> Enum.map(fn {role, _caps} -> role end)
  end

  @doc """
  Get capability details by ID.
  """
  @spec get_capability(t(), atom()) :: capability_node() | nil
  def get_capability(%__MODULE__{capabilities: caps}, cap_id) do
    Map.get(caps, cap_id)
  end

  @doc """
  List all capabilities in a category.
  """
  @spec list_capabilities_by_category(t(), atom()) :: [capability_node()]
  def list_capabilities_by_category(%__MODULE__{capabilities: caps}, category) do
    caps
    |> Map.values()
    |> Enum.filter(fn cap -> cap.category == category end)
  end

  @doc """
  Get graph statistics.
  """
  @spec get_stats(t()) :: map()
  def get_stats(%__MODULE__{} = graph) do
    %{
      total_capabilities: map_size(graph.capabilities),
      total_role_assignments: map_size(graph.role_assignments),
      capabilities_by_category: count_by_category(graph.capabilities),
      most_assigned_capability: find_most_assigned(graph.role_assignments)
    }
  end

  @doc """
  Export graph to JSON-serializable format.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = graph) do
    %{
      capabilities: graph.capabilities,
      role_assignments: graph.role_assignments,
      capability_dependencies: graph.capability_dependencies,
      timestamp: DateTime.to_iso8601(graph.timestamp)
    }
  end

  # Private helpers

  defp find_roles_with_capability(%__MODULE__{role_assignments: assignments}, cap_id) do
    assignments
    |> Enum.filter(fn {_role, caps} -> cap_id in caps end)
    |> Enum.map(fn {role, _caps} -> role end)
  end

  defp count_by_category(capabilities) do
    capabilities
    |> Map.values()
    |> Enum.group_by(fn cap -> cap.category end)
    |> Enum.map(fn {cat, list} -> {cat, length(list)} end)
    |> Enum.into(%{})
  end

  defp find_most_assigned(role_assignments) do
    all_caps = role_assignments |> Map.values() |> List.flatten()

    all_caps
    |> Enum.frequencies()
    |> Enum.max_by(fn {_cap, count} -> count end, fn -> {:none, 0} end)
  end
end
