defmodule Tiannara.Omega.DryRun do
  @moduledoc """
  End-to-end Ω dry-run capstone. Exercises the full autonomy chain as ONE
  scenario WITHOUT deploying anything:

      Contradiction engine (detect)
        ↓  :contradiction_detected epistemic event
      Ω.2 evidence-driven Research Director (investigate → rank → propose)
        ↓  top experiment proposal
      Ω.4 sandbox (apply patch → tests → benchmark, isolated)
        ↓  sandbox verdict
      Certification Pipeline (multi-dimensional certificate)
        ↓
      Dry-run verdict + lineage

  AUTHORITY BOUNDARY: this is a DRY RUN. It investigates, proposes, evaluates
  in an isolated sandbox, and certifies — but it NEVER deploys. Deployment
  remains under Ω.4 governance and human judgment (augmentation clause).

  Constitutional basis: Scientific Method, Evolution Framework, Verification
  First ("No feature is complete until it is validated"), "Capability must
  never outpace verification", "Every architectural decision should remain
  traceable."
  """

  alias Tiannara.Contradiction.Engine, as: ContradictionEngine
  alias Tiannara.Research.Director.EvidenceDriven
  alias Tiannara.SelfImprovement.Sandbox.{RealHarness, CodePatch}
  alias Tiannara.SelfImprovement.Sandbox.Backend.Local
  alias Tiannara.Certification.{Pipeline, MultiCertificate}

  defstruct [:contradiction, :event, :investigation, :top_proposal,
             :sandbox_outcome, :certificate, :verdict, :lineage]

  @dry_run_policy %{
    contradiction_detected: :critical,
    evidence_assessed: :critical,
    hypothesis_generated: :critical,
    experiment_evaluated: :critical,
    tests_passed: :critical,
    benchmark_ok: :critical
  }

  def policy, do: @dry_run_policy

  @doc "Run the end-to-end Ω dry-run for a scenario."
  def run(scenario) do
    with {:ok, contradiction} <- detect_contradiction(scenario) do
      event = ContradictionEngine.to_epistemic_event(contradiction)
      investigation = EvidenceDriven.investigate(event)

      with {:ok, top_proposal} <- select_top_proposal(investigation) do
        {sandbox_outcome, baseline_dir} = run_sandbox(scenario, top_proposal)
        certificate = certify(sandbox_outcome, investigation)
        verdict = derive_verdict(sandbox_outcome, certificate)

        File.rm_rf!(baseline_dir)

        {:ok,
         %__MODULE__{
           contradiction: contradiction,
           event: event,
           investigation: investigation,
           top_proposal: top_proposal,
           sandbox_outcome: sandbox_outcome,
           certificate: certificate,
           verdict: verdict,
           lineage: [contradiction.id, top_proposal.id]
         }}
      end
    end
  end

  # --- steps --------------------------------------------------------------

  defp detect_contradiction(scenario) do
    case ContradictionEngine.detect(scenario.claims) do
      [contradiction | _] -> {:ok, contradiction}
      [] -> {:error, :no_contradiction_detected}
    end
  end

  defp select_top_proposal(investigation) do
    case investigation.proposals do
      [top | _] -> {:ok, top}
      [] -> {:error, :no_proposals_generated}
    end
  end

  defp run_sandbox(scenario, top_proposal) do
    baseline_dir = setup_baseline(scenario)

    patch = %CodePatch{
      id: :"patch-#{top_proposal.id}",
      description: "embodies experiment for: #{top_proposal.statement}",
      targets: Map.get(scenario, :targets, [:compute]),
      files: scenario.patch_files,
      provenance: [top_proposal.id]
    }

    specs = %{tests: scenario.test_spec, benchmark: scenario.benchmark_spec}
    outcome = RealHarness.run(Local, baseline_dir, patch, specs)
    {outcome, baseline_dir}
  end

  defp setup_baseline(scenario) do
    dir = Path.join(System.tmp_dir!(), "omega_dryrun_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    Enum.each(scenario.baseline_files, fn {name, content} ->
      File.write!(Path.join(dir, name), content)
    end)

    dir
  end

  defp certify(sandbox_outcome, investigation) do
    gate_results = build_gate_results(sandbox_outcome, investigation)
    Pipeline.evaluate(gate_results, subsystem: :omega_dry_run, policy: @dry_run_policy)
  end

  defp build_gate_results(sandbox_outcome, investigation) do
    {tests_gate, benchmark_gate, experiment_gate} =
      case sandbox_outcome do
        {:ok, result} ->
          {gate_from_bool(result.tests.all_passed),
           gate_from_bool(result.benchmark.no_regression),
           :gate_open}

        {:error, _} ->
          {{:gate_closed, [:sandbox_failed]},
           {:gate_closed, [:sandbox_failed]},
           {:gate_closed, [:sandbox_failed]}}
      end

    %{
      contradiction_detected: :gate_open,
      evidence_assessed: gate_from_bool(investigation.evidence_assessment != nil),
      hypothesis_generated: gate_from_bool(length(investigation.hypotheses) > 0),
      experiment_evaluated: experiment_gate,
      tests_passed: tests_gate,
      benchmark_ok: benchmark_gate
    }
  end

  defp gate_from_bool(true), do: :gate_open
  defp gate_from_bool(false), do: {:gate_closed, [:requirement_not_met]}

  defp derive_verdict(sandbox_outcome, certificate) do
    case sandbox_outcome do
      {:ok, %{verdict: :pass}} ->
        if MultiCertificate.certified?(certificate),
          do: :hypothesis_supported_and_certified,
          else: :hypothesis_supported_not_certified

      {:ok, %{verdict: {:fail, reason}}} ->
        {:hypothesis_not_supported, reason}


      {:error, reason} ->
        {:sandbox_error, reason}
    end
  end

  # --- reporting ----------------------------------------------------------

  @doc "Render a human-readable report of the dry-run."
  def render(%__MODULE__{} = dry_run) do
    """
    ════════ Ω END-TO-END DRY-RUN ════════
    Contradiction: #{inspect(dry_run.contradiction.id)} (#{dry_run.contradiction.type})
      claim_a: #{inspect(dry_run.contradiction.claim_a.value)}
      claim_b: #{inspect(dry_run.contradiction.claim_b.value)}

    Investigation:
      evidence sufficiency: #{dry_run.investigation.evidence_assessment.sufficiency}
      hypotheses: #{length(dry_run.investigation.hypotheses)}
      uncertainty: #{dry_run.investigation.uncertainty}

    Top proposal: #{inspect(dry_run.top_proposal.id)} (rank #{dry_run.top_proposal.rank})
      #{dry_run.top_proposal.statement}

    Sandbox verdict: #{inspect(sandbox_verdict(dry_run.sandbox_outcome))}
    Certificate: #{inspect(dry_run.certificate.verdict)}
    OVERALL VERDICT: #{inspect(dry_run.verdict)}
    Lineage: #{inspect(dry_run.lineage)}
    ════════ end dry-run (nothing deployed) ════════
    """
  end

  defp sandbox_verdict({:ok, %{verdict: v}}), do: v
  defp sandbox_verdict({:error, reason}), do: {:error, reason}
end