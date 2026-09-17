defmodule Tiannara.Engineering.ProposalTest do
  use ExUnit.Case, async: false

  alias Tiannara.Engineering.{Proposal, RootCauseAnalyzer, ProposalRegistry, ProposalGenerator}
  alias Tiannara.VerificationAuthority

  setup do
    for mod <- [
      RootCauseAnalyzer,
      ProposalRegistry,
      ProposalGenerator,
      VerificationAuthority
    ] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end
    :ok
  end

  defp t48h_keyerror_failure do
    %{
      exception: %KeyError{key: :uncertainty_level, term: %{name: "load_test_1", version: "1.0", payload: %{data: "test_1"}}},
      stacktrace_ref: "load_spike_task_1",
      task_id: 1,
      phase: :t_plus_48h_load_spike,
      timestamp: DateTime.utc_now(),
      soak_run_id: "soak-cert-72h-patched"
    }
  end

  # 1. The exact T+48h crash is classified as a KNOWN pattern, not novel.
  test "RootCauseAnalyzer classifies T+48h KeyError as :missing_uncertainty_key pattern" do
    failure = t48h_keyerror_failure()
    {:ok, proposal, hypothesis} = RootCauseAnalyzer.analyze(failure)

    assert proposal.affected_module != :unknown
    assert proposal.status == :observed
    assert hypothesis.confidence > 0.7
    assert hypothesis[:pattern_id] == :missing_uncertainty_key
  end

  # 2. Proposal lifecycle enforces strict ordering (governance).
  test "Proposal transitions follow strict lifecycle order" do
    failure = t48h_keyerror_failure()
    {:ok, proposal, _hypothesis} = RootCauseAnalyzer.analyze(failure)

    assert proposal.status == :observed
    assert {:error, {:invalid_transition, :observed, :queued}} = Proposal.advance(proposal, :queued)
    assert {:ok, p2} = Proposal.advance(proposal, :reproduced)
    assert {:ok, p3} = Proposal.advance(p2, :candidate_generated)
    assert {:ok, p4} = Proposal.advance(p3, :verification_passed)
    assert {:ok, p5} = Proposal.advance(p4, :queued)
    assert {:ok, p6} = Proposal.advance(p5, :human_review)
    assert {:ok, p7} = Proposal.advance(p6, :approved)
    assert {:ok, p8} = Proposal.advance(p7, :phase8)
    assert {:ok, p9} = Proposal.advance(p8, :observed_outcome)
    p10 = Proposal.archive(p9, %{decision: :success})
    assert p10.status == :archived
  end

  # 3. The suggested repair for the T+48h pattern is Map.get with a neutral default.
  test "T+48h KeyError pattern suggests Map.get with 0.5 default" do
    failure = t48h_keyerror_failure()
    {:ok, proposal, hypothesis} = RootCauseAnalyzer.analyze(failure)

    assert hypothesis.suggested_repair_template == "Map.get(artifact, :uncertainty_level, 0.5)"
    assert proposal.contract_violation.policy == :normalize_with_default
  end

  # 4. VerificationAuthority returns a truthful result: without real
  #    reproduction / regression evidence the proposal does NOT pass.
  test "VerificationAuthority reports unavailability instead of fabricating a pass" do
    failure = t48h_keyerror_failure()
    {:ok, proposal, _hypothesis} = RootCauseAnalyzer.analyze(failure)
    proposal = Proposal.set_repair(proposal, "Map.get(artifact, :uncertainty_level, 0.5)", 1)

    result = VerificationAuthority.verify(proposal)

    refute Tiannara.Verification.Result.passed?(result)
    assert result.immutable == true
    assert result.reproduction.reproduced == false
    assert result.regression_tests.all_passing == false
    assert result.constitutional_compliance.compliant == false
    assert result.constitutional_compliance.reason == :not_independently_assessed
  end

  # 5. Proposal immutability: set_repair returns NEW proposal, original unchanged.
  test "Proposal.set_repair returns new struct, original unchanged" do
    failure = t48h_keyerror_failure()
    {:ok, proposal, _} = RootCauseAnalyzer.analyze(failure)
    original_status = proposal.status
    original_suggested = proposal.suggested_repair

    patched = Proposal.set_repair(proposal, "Map.get(artifact, :uncertainty_level, 0.5)", 1)

    assert proposal.status == original_status
    assert proposal.suggested_repair == original_suggested
    assert patched.status == :candidate_generated
    assert patched.suggested_repair == "Map.get(artifact, :uncertainty_level, 0.5)"
  end
end
