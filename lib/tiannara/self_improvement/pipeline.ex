defmodule Tiannara.SelfImprovement.Proposal do
  defstruct [:id, :observation, :description, :patch, :targets, :provenance,
             :independent_verification, stage: :observation,
             gate_results: %{}, attestations: []]
end

defmodule Tiannara.SelfImprovement.GateResult do
  defstruct [:gate, :passed, :source, :evidence, :reason]
end

defmodule Tiannara.SelfImprovement.Contract do
  @moduledoc "Ω.4 contract: deployment authorization is gated, never autonomous."
  @callback request_deployment(proposal :: term(), gate_results :: map(), opts :: keyword()) ::
              {:ok, term()} | {:error, term()}
end

defmodule Tiannara.SelfImprovement.Pipeline do
  @moduledoc """
  The self-improvement pipeline state machine (Ω.4). Contracts + validation
  model only — autonomous deployment is DISABLED by default. Deployment
  requires every gate to pass AND human approval AND, for protected-core
  changes, INDEPENDENT verification from an external source (never
  self-attested).

  Constitutional basis: "Capability must never outpace verification",
  "Constitutional Authority is Supreme", Verification First, augmentation
  clause (humans approve), "No constitutional rule is modified by the subsystem
  it governs."
  """
  @behaviour Tiannara.SelfImprovement.Contract

  alias Tiannara.SelfImprovement.{ProtectedCore, Proposal, GateResult}

  @stages [:observation, :improvement_candidate, :proposal, :code_analysis,
           :patch_generation, :sandbox, :tests, :benchmark,
           :adversarial_validation, :constitutional_review, :human_approval,
           :deployment, :canary, :monitoring, :rollback]

  @required_gates [:tests, :benchmark, :adversarial_validation,
                   :constitutional_review, :human_approval]

  def stages, do: @stages
  def required_gates, do: @required_gates

  @impl true
  def request_deployment(%Proposal{} = proposal, gate_results, opts \\ []) do
    deployment_enabled? = Keyword.get(opts, :deployment_enabled, false)

    with :ok <- check_required_gates(gate_results),
         :ok <- check_protected_core(proposal, gate_results) do
      if deployment_enabled?,
        do: {:ok, :deployment_authorized},
        else: {:error, :deployment_disabled}
    end
  end

  defp check_required_gates(gate_results) do
    failed = Enum.filter(@required_gates, &(not gate_passed?(gate_results, &1)))
    if failed == [], do: :ok, else: {:error, {:gates_failed, failed}}
  end

  defp check_protected_core(proposal, gate_results) do
    if ProtectedCore.touches_protected?(proposal.targets || []) do
      if independent_verified?(gate_results),
        do: :ok,
        else: {:error, :protected_core_requires_independent_verification}
    else
      :ok
    end
  end

  defp gate_passed?(gate_results, gate) do
    case Map.get(gate_results, gate) do
      %GateResult{passed: true} -> true
      _ -> false
    end
  end

  # Independent verification must come from OUTSIDE the self-improvement
  # system. Self-attestation is rejected by construction.
  defp independent_verified?(gate_results) do
    case Map.get(gate_results, :independent_verification) do
      %GateResult{passed: true, source: source}
      when source != nil and source != :self_improvement -> true

      _ -> false
    end
  end
end