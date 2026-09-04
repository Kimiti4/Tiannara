defmodule TiannaraOS.Governance.CapabilityChecker do
  @moduledoc """
  CapabilityChecker - Verifies institutional authorization for governance actions.

  This module implements capability-based access control (CBAC) for constitutional
  governance. Instead of checking roles directly, it verifies that an institution
  possesses the required capability within the relevant governance domain.

  ## Authorization Flow

  1. Actor (institution member) requests action
  2. System checks institution's capabilities
  3. System verifies domain authority
  4. System checks quorum requirements
  5. Action authorized or denied with reason

  ## Capabilities

  - `:can_review` - Review proposals and evidence
  - `:can_deploy` - Execute migrations
  - `:can_rollback` - Revert deployments
  - `:can_ratify` - Approve constitutional amendments
  - `:can_observe` - Monitor and measure (no governance power)
  - `:can_simulate` - Run simulations
  - `:can_appoint` - Appoint institutional members
  - `:can_remove` - Remove institutional members
  - `:can_amend_meta_constitution` - Modify meta-constitutional rules
  - `:can_approve_budget` - Approve governance budgets

  ## Example

      iex> institution = ConstitutionalInstitution.define_review_board()
      iex> CapabilityChecker.authorize?(institution, :can_review, :science)
      true

      iex> CapabilityChecker.authorize?(institution, :can_deploy, :migration)
      false
  """

  alias TiannaraOS.Governance.ConstitutionalInstitution
  alias TiannaraOS.Governance.ConstitutionalRole

  @doc """
  Check if institution is authorized to perform action in domain.

  Returns `:ok` if authorized, `{:error, reason}` if not.
  """
  @spec authorize?(ConstitutionalInstitution.t(), atom(), atom()) :: :ok | {:error, String.t()}
  def authorize?(%ConstitutionalInstitution{} = institution, capability, domain) do
    cond do
      not ConstitutionalInstitution.has_domain_authority?(institution, domain) ->
        {:error, "Institution '#{institution.name}' has no authority in domain #{inspect(domain)}"}

      not ConstitutionalInstitution.has_capability?(institution, capability) ->
        {:error, "Institution '#{institution.name}' lacks capability #{inspect(capability)}"}

      institution.status != :active ->
        {:error, "Institution '#{institution.name}' is not active (status: #{institution.status})"}

      true ->
        :ok
    end
  end

  @doc """
  Check if institution has quorum for decision-making.
  """
  @spec check_quorum(ConstitutionalInstitution.t(), non_neg_integer()) :: :ok | {:error, String.t()}
  def check_quorum(%ConstitutionalInstitution{} = institution, present_count) do
    if ConstitutionalInstitution.quorum_met?(institution, present_count) do
      :ok
    else
      {:error, "Quorum not met: need #{institution.quorum_size}, have #{present_count}"}
    end
  end

  @doc """
  Verify actor (member) belongs to institution and institution has capability.

  This is the primary authorization check for governance actions.
  """
  @spec verify_actor_authorization(String.t(), ConstitutionalInstitution.t(), atom(), atom()) ::
          :ok | {:error, String.t()}
  def verify_actor_authorization(actor_id, %ConstitutionalInstitution{} = institution, capability, domain) do
    case find_member(institution, actor_id) do
      nil ->
        {:error, "Actor '#{actor_id}' is not a member of institution '#{institution.name}'"}

      _member ->
        authorize?(institution, capability, domain)
    end
  end

  @doc """
  List all capabilities an institution possesses.
  """
  @spec list_capabilities(ConstitutionalInstitution.t()) :: [atom()]
  def list_capabilities(%ConstitutionalInstitution{authority_capabilities: caps}) do
    caps
  end

  @doc """
  List all domains an institution has authority in.
  """
  @spec list_domains(ConstitutionalInstitution.t()) :: [atom()]
  def list_domains(%ConstitutionalInstitution{governance_domains: domains}) do
    domains
  end

  @doc """
  Get institution's authority summary.
  """
  @spec authority_summary(ConstitutionalInstitution.t()) :: map()
  def authority_summary(%ConstitutionalInstitution{} = institution) do
    %{
      institution_id: institution.institution_id,
      name: institution.name,
      capabilities: list_capabilities(institution),
      domains: list_domains(institution),
      quorum_size: institution.quorum_size,
      member_count: length(institution.members),
      status: institution.status
    }
  end

  @doc """
  Check if multiple institutions collectively have required capabilities.

  Useful for cross-institutional actions requiring multiple authorities.
  """
  @spec collective_authorization?([ConstitutionalInstitution.t()], [atom()], atom()) ::
          :ok | {:error, String.t()}
  def collective_authorization?(institutions, required_capabilities, domain) when is_list(institutions) do
    all_capabilities =
      institutions
      |> Enum.flat_map(&list_capabilities/1)
      |> Enum.uniq()

    missing_caps = Enum.reject(required_capabilities, fn cap -> cap in all_capabilities end)

    cond do
      missing_caps != [] ->
        {:error, "Collective missing capabilities: #{inspect(missing_caps)}"}

      not Enum.any?(institutions, fn inst -> ConstitutionalInstitution.has_domain_authority?(inst, domain) end) ->
        {:error, "No institution has authority in domain #{inspect(domain)}"}

      true ->
        :ok
    end
  end

  @doc """
  Validate that role assignment to institution is valid.

  Checks that role capabilities are subset of institution capabilities.
  """
  @spec validate_role_assignment(ConstitutionalRole.t(), ConstitutionalInstitution.t()) ::
          :ok | {:error, String.t()}
  def validate_role_assignment(%ConstitutionalRole{} = role, %ConstitutionalInstitution{} = institution) do
    role_caps = Map.get(role, :capabilities, [])
    inst_caps = institution.authority_capabilities

    invalid_caps = Enum.reject(role_caps, fn cap -> cap in inst_caps end)

    if invalid_caps == [] do
      :ok
    else
      {:error, "Role '#{role.role_id}' has capabilities not granted to institution: #{inspect(invalid_caps)}"}
    end
  end

  # Private helpers

  defp find_member(%ConstitutionalInstitution{members: members}, actor_id) do
    Enum.find(members, fn member ->
      Map.get(member, :member_id) == actor_id or Map.get(member, :role_id) == actor_id
    end)
  end
end
