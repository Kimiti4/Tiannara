defmodule Tiannara.SelfImprovement.DryRun.Observation do
  @moduledoc "The triggering observation for an improvement dry-run."
  @enforce_keys [:id, :description]
  defstruct [:id, :description, :bottleneck, evidence: []]
end

defmodule Tiannara.SelfImprovement.DryRun.Run do
  @moduledoc "The result of an end-to-end Ω.4 improvement dry-run."
  @enforce_keys [:observation, :proposal, :patch, :steps, :deployment_decision, :certificate]
  defstruct [:observation, :proposal, :patch, :steps, :deployment_decision,
             :certificate, :lineage, deployed?: false]
end

defmodule Tiannara.SelfImprovement.DryRun do
  @moduledoc """
  End-to-end Ω.4 improvement DRY-RUN. Supports two sandbox modes:
    * Abstract — a `Patch` with a state `transform`, evaluated by `Harness`.
    * Real-code — a `CodePatch` evaluated by `RealHarness` against a pluggable
      `Backend` (Local / Container / CI).

  Both modes run: observation → proposal → code analysis → patch → sandbox
  (tests + benchmark) → adversarial validation → constitutional review → human
  approval → multi-dimensional certificate. The run EVALUATES but NEVER
  deploys; `deployed?` is always false.

  Constitutional basis: "Capability must never outpace verification",
  Verification First, Evolution Framework ("Generate → Evaluate → Benchmark →
  Compare → Validate → ... Preserve lineage"), "Every architectural decision
  should remain traceable", and the augmentation clause (humans approve).
  """

  alias Tiannara.SelfImprovement.{Pipeline, Proposal, GateResult, ProtectedCore}
  alias Tiannara.SelfImprovement.Sandbox.{Harness, RealHarness, Patch, CodePatch}
  alias Tiannara.SelfImprovement.DryRun.{Observation, Run}
  alias Tiannara.Certification.Pipeline, as: CertPipeline

  defp run_sandbox(%CodePatch{} = patch, config) do
    # Defense-in-depth: block protected-core real patches lacking independent
    # verification BEFORE any sandbox execution.
    if patch.targets != [] and ProtectedCore.touches_protected?(patch.targets) and
         not Map.get(config, :independent_verification, false) do
      {:error, :protected_core_requires_independent_verification}
    else
      backend = Map.fetch!(config, :backend)
      baseline = Map.fetch!(config, :baseline)
      specs = Map.fetch!(config, :specs)
      RealHarness.run(backend, baseline, patch, specs)
    end
  end

  defp run_sandbox(%Patch{} = patch, config) do
    baseline = Map.get(config, :baseline_state, %{})
    tests = Map.get(config, :tests, [])
    benchmark = Map.fetch!(config, :benchmark)

    Harness.run(baseline, patch, tests, benchmark,
      independent_verification: Map.get(config, :independent_verification, false)
    )
  end

  @improvement_policy %{
    tests: :critical,
    benchmark: :critical,
    adversarial_validation: :critical,
    constitutional_review: :critical,
    human_approval: :critical
  }

  @gaming_targets [:tests, :benchmark, :harness, :evaluator, :measurement]

  def execute(%Observation{} = observation, config) do
    patch = Map.fetch!(config, :patch)
    proposal = generate_proposal(observation, patch)

    sandbox_outcome = run_sandbox(patch, config)

    # Adversarial validation: static anti-gaming checks on the patch.
    adversarial = adversarial_validation(patch, config)

    # Constitutional review: protected-core governance.
    const_review = constitutional_review(patch, config)

    # Human approval attestation.
    human_passed =
      case Map.get(config, :human_approval) do
        %GateResult{passed: p} -> p
        _ -> false
      end

    # Gate results for the self-improvement pipeline.
    gate_results =
      build_gate_results(sandbox_outcome, adversarial, const_review, human_passed, config)

    # Deployment authorization. DRY-RUN: evaluated with deployment_enabled: true
    # purely to surface the gate decision; NO deployment is ever executed here.
    deployment_decision =
      Pipeline.request_deployment(proposal, gate_results, deployment_enabled: true)

    # Multi-dimensional certificate.
    certificate =
      issue_certificate(sandbox_outcome, adversarial, const_review, human_passed, config)

    steps =
      build_steps(proposal, patch, sandbox_outcome, adversarial, const_review,
        human_passed, deployment_decision)

    run = %Run{
      observation: observation,
      proposal: proposal,
      patch: patch,
      steps: steps,
      deployment_decision: deployment_decision,
      certificate: certificate,
      lineage: [observation.id, proposal.id, patch.id],
      deployed?: false
    }

    {:ok, run}
  end

  # --- helpers ------------------------------------------------------------

  defp generate_proposal(%Observation{} = obs, patch) do
    %Proposal{
      id: :"prop-#{obs.id}",
      observation: obs.description,
      description: "Improvement proposal derived from observation #{inspect(obs.id)}",
      targets: patch.targets,
      provenance: [obs.id]
    }
  end

  defp adversarial_validation(%Patch{} = patch, config),
    do: adversarial_validation(patch, patch.targets, config)

  defp adversarial_validation(%CodePatch{} = patch, config),
    do: adversarial_validation(patch, patch.targets, config)

  defp adversarial_validation(patch, targets, config) do
    targets_evaluator = Enum.any?(targets, &(&1 in @gaming_targets))

    built_in =
      if targets_evaluator,
        do: [{:anti_gaming, false, :patch_targets_evaluator}],
        else: [{:anti_gaming, true, :ok}]

    custom =
      config
      |> Map.get(:adversarial_checks, [])
      |> Enum.with_index(1)
      |> Enum.map(fn {check, i} ->
        outcome =
          try do
            check.(patch)
          rescue
            e -> {:error, {:raised, Exception.message(e)}}
          end

        {:"check_#{i}", outcome == :ok, detail(outcome)}
      end)

    results = built_in ++ custom
    failed = for {id, false, _} <- results, do: id
    %{passed: failed == [], results: results, failed: failed}
  end

  defp constitutional_review(%Patch{} = patch, config),
    do: constitutional_review(patch, patch.targets, config)

  defp constitutional_review(%CodePatch{} = patch, config),
    do: constitutional_review(patch, patch.targets, config)

  defp constitutional_review(patch, targets, config) do
    touches_protected = targets != [] and ProtectedCore.touches_protected?(targets)
    has_independent = Map.get(config, :independent_verification, false)

    if touches_protected and not has_independent do
      %{status: :fail, reason: :protected_core_requires_independent_verification,
        touches_protected: true}
    else
      %{status: :ok, reason: :ok, touches_protected: touches_protected}
    end
  end

  defp build_gate_results(sandbox_outcome, adversarial, const_review, human_passed, config) do
    {tests_passed, benchmark_passed} =
      case sandbox_outcome do
        {:ok, result} -> {result.tests.all_passed, result.benchmark.no_regression}
        {:error, _} -> {false, false}
      end

    base = %{
      tests: gr(:tests, tests_passed, :sandbox),
      benchmark: gr(:benchmark, benchmark_passed, :sandbox),
      adversarial_validation: gr(:adversarial_validation, adversarial.passed, :adversarial_lab),
      constitutional_review: gr(:constitutional_review, const_review.status == :ok, :constitutional_reviewer),
      human_approval: gr(:human_approval, human_passed, :human)
    }

    if Map.get(config, :independent_verification) do
      Map.put(base, :independent_verification,
        gr(:independent_verification, true, :external_auditor))
    else
      base
    end
  end

  defp issue_certificate(sandbox_outcome, adversarial, const_review, human_passed, config) do
    {tests_gate, benchmark_gate} =
      case sandbox_outcome do
        {:ok, result} ->
          {gate_from_bool(result.tests.all_passed, :tests_failed),
           gate_from_bool(result.benchmark.no_regression, :benchmark_regression)}

        {:error, _} ->
          {:unevaluated, :unevaluated}
      end

    cert_gates = %{
      tests: tests_gate,
      benchmark: benchmark_gate,
      adversarial_validation: gate_from_bool(adversarial.passed, :adversarial_failed),
      constitutional_review: gate_from_bool(const_review.status == :ok, :constitutional_review_failed),
      human_approval: gate_from_bool(human_passed, :human_approval_missing)
    }

    policy = Map.get(config, :certification_policy, @improvement_policy)
    CertPipeline.evaluate(cert_gates, subsystem: :omega4_improvement, policy: policy)
  end

  defp build_steps(proposal, patch, sandbox_outcome, adversarial, const_review,
                   human_passed, deployment_decision) do
    analysis = code_analysis(patch)

    sandbox_status =
      case sandbox_outcome do
        {:ok, %{verdict: :pass}} -> :pass
        {:ok, %{verdict: {:fail, reason}}} -> {:fail, reason}
        {:error, reason} -> {:blocked, reason}
      end

    [
      %{step: :observation, status: :ok, detail: :received},
      %{step: :proposal_generated, status: :ok, detail: proposal.id},
      %{step: :code_analysis, status: :ok, detail: analysis},
      %{step: :patch_generated, status: :ok, detail: patch.id},
      %{step: :sandbox, status: sandbox_status, detail: nil},
      %{step: :adversarial_validation,
        status: if(adversarial.passed, do: :pass, else: :fail), detail: adversarial.failed},
      %{step: :constitutional_review, status: const_review.status, detail: const_review.reason},
      %{step: :human_approval, status: if(human_passed, do: :pass, else: :fail), detail: nil},
      %{step: :deployment_decision, status: deployment_status(deployment_decision), detail: nil}
    ]
  end

  defp code_analysis(patch) do
    %{targets: patch.targets,
      touches_protected: patch.targets != [] and ProtectedCore.touches_protected?(patch.targets)}
  end

  defp deployment_status({:ok, :deployment_authorized}), do: :authorized_not_executed
  defp deployment_status({:error, reason}), do: {:not_authorized, reason}

  defp gate_from_bool(true, _reason), do: :gate_open
  defp gate_from_bool(false, reason), do: {:gate_closed, [reason]}

  defp gr(gate, passed, source),
    do: %GateResult{gate: gate, passed: passed, source: source, evidence: []}

  defp detail(:ok), do: :ok
  defp detail({:error, reason}), do: reason
  defp detail(other), do: {:unexpected, other}
end