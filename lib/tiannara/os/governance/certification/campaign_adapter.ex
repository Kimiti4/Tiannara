defmodule TiannaraOS.Governance.Certification.CampaignAdapter do
  @moduledoc """
  CampaignAdapter - Behaviour defining the contract for all 30 constitutional certification campaigns.

  Every certification campaign must implement this behaviour to be executable by the
  `CampaignOrchestrator` and `CampaignExecutor`. This enforces a uniform interface
  across radically different types of validation (e.g., from causal graph checks to
  extreme scale simulation).

  ## Constitutional Principle

  Campaigns are independent verifiers. They do not share state with the runtime they
  are verifying, other than the parameters explicitly passed to them. They must return
  evidence artifacts that can be cryptographically signed.
  """

  @type execution_params :: %{
    campaign_id: String.t(),
    threshold: term(),
    seed: integer(),
    config: map(),
    scale: :quick | :standard | :full,
    context: TiannaraOS.Governance.DeterministicContext.t() | nil
  }

  @type success_evidence :: %{
    status: :passed,
    metrics: map(),
    artifacts: [map()],
    lineage: [String.t()]
  }

  @type failure_evidence :: %{
    status: :failed,
    reason: String.t(),
    failing_metrics: map(),
    context: map()
  }

  @doc """
  Executes the campaign with the provided parameters.

  Returns `{:ok, evidence}` on constitutional pass, or `{:error, evidence}` on failure.
  The orchestrator treats any `{:error, _}` as a hard halt for the certification process.
  """
  @callback execute(params :: execution_params()) :: {:ok, success_evidence()} | {:error, failure_evidence()}
end
