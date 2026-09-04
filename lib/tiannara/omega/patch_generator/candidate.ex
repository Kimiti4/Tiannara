defmodule Tiannara.Omega.PatchGenerator.Candidate do
  @moduledoc """
  A generated improvement candidate with a strict lifecycle state machine.

  The state machine enforces the sandbox-first rule and the authority boundary:
  the generator can only produce `:generated` candidates, and the ONLY legal
  exit from `:generated` is `:sandboxed`. Deployment is only reachable through
  `:approved`, which only the governance gate can grant.

      :generated → :sandboxed
      :sandboxed → :tested | :rejected
      :tested → :benchmarked | :rejected
      :benchmarked → :certified | :rejected
      :certified → :approved | :rejected     (approved only by human/governance)
      :approved → :deployed                  (deployed only by deployer)
      :deployed → (terminal)
      :rejected → (terminal)

  Constitutional basis: "Capability must never outpace verification",
  Verification First, Safety and Reliability, augmentation clause.
  """

  @enforce_keys [:id, :type, :proposal_id]
  defstruct [
    :id,
    :type,
    :proposal_id,
    :content,
    :lineage,
    :provenance,
    :experiment_id,
    status: :generated,
    history: []
  ]

  @type t :: %__MODULE__{}

  @candidate_types [:code_patch, :config_change, :algorithm_parameter]
  def candidate_types, do: @candidate_types

  @legal_transitions %{
    generated: [:sandboxed],
    sandboxed: [:tested, :rejected],
    tested: [:benchmarked, :rejected],
    benchmarked: [:certified, :rejected],
    certified: [:approved, :rejected],
    approved: [],
    deployed: [],
    rejected: []
  }

  def legal_transitions, do: @legal_transitions

  @doc """
  Creates a candidate. The generator can ONLY create candidates with status
  `:generated`. This is the sole authority the generator holds.
  """
  def new(type, proposal_id, content, opts \\ []) when type in @candidate_types do
    %__MODULE__{
      id: Keyword.get(opts, :id, make_id()),
      type: type,
      proposal_id: proposal_id,
      content: content,
      lineage: Keyword.get(opts, :lineage, []),
      provenance: Keyword.get(opts, :provenance, []),
      experiment_id: Keyword.get(opts, :experiment_id),
      status: :generated,
      history: [{:generated, System.system_time(:second)}]
    }
  end

  @doc """
  Transition a candidate to a new status. Enforces the legal state machine.
  Returns `{:ok, candidate}` or `{:error, reason}`.

  NOTE: Only authorized components (sandbox, certification, governance,
  deployer) should call this. The generator must never call it.

  The `:approved → :deployed` transition is NOT exposed here. Deployment is
  the sole authority of the DeploymentGateway via `deploy_transition/1`.
  """
  def transition(%__MODULE__{} = candidate, new_status) do
    legal = Map.get(@legal_transitions, candidate.status, [])

    if new_status in legal do
      {:ok,
       %{candidate
        | status: new_status,
          history: candidate.history ++ [{new_status, System.system_time(:second)}]}}
    else
      {:error,
       {:illegal_transition, from: candidate.status, to: new_status,
        legal: legal}}
    end
  end

  @doc """
  The ONLY transition into `:deployed`. Called exclusively by
  `DeploymentGateway` after all authorization, certification, lineage, and
  grant checks pass. This is the structural enforcement of the
  single-deployment-gateway authority boundary.
  """
  def deploy_transition(%__MODULE__{status: :approved} = candidate) do
    {:ok,
     %{candidate
      | status: :deployed,
        history: candidate.history ++ [{:deployed, System.system_time(:second)}]}}
  end

  def deploy_transition(%__MODULE__{status: status}) do
    {:error, {:candidate_not_approved, status}}
  end

  @doc """
  Returns true if the candidate has reached the sandbox at least once. This is
  the invariant that no candidate can bypass validation.
  """
  def sandboxed?(%__MODULE__{history: history}) do
    Enum.any?(history, fn {status, _} -> status == :sandboxed end)
  end

  @doc """
  Returns true if the candidate can still be deployed. Only candidates that
  have passed through the full chain and been approved are deployable.
  """
  def deployable?(%__MODULE__{status: status}), do: status == :approved

  defp make_id, do: :"cand-#{System.unique_integer([:monotonic])}"
end