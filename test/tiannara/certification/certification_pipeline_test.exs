defmodule Tiannara.Certification.CertificationPipelineTest do
  use ExUnit.Case, async: true

  alias Tiannara.Certification.{Pipeline, MultiCertificate}
  alias Tiannara.Constitution.{Suite, Gate, Registry}

  @moduletag :certification_pipeline

  defp all_pass do
    %{
      constitutional_invariants: :gate_open,
      recovery: :gate_open,
      evidence_integrity: :gate_open,
      funnel_integrity: :gate_open,
      adversarial_detection: :gate_open,
      authorization_integrity: :gate_open,
      deterministic_replay: :gate_open
    }
  end

  test "all critical dimensions passing yields CERTIFIED" do
    cert = Pipeline.evaluate(all_pass())
    assert MultiCertificate.certified?(cert)
    assert cert.verdict == :certified
  end

  test "a failing critical dimension blocks certification" do
    results = Map.put(all_pass(), :recovery, {:gate_closed, [:crash_recovery]})
    cert = Pipeline.evaluate(results)

    refute MultiCertificate.certified?(cert)
    assert {:not_certified, {:dimensions_failed, [:recovery]}} = cert.verdict
  end

  test "an unevaluated critical dimension blocks certification" do
    results = Map.put(all_pass(), :evidence_integrity, :unevaluated)
    cert = Pipeline.evaluate(results)

    refute MultiCertificate.certified?(cert)
    assert {:not_certified, {:dimensions_unevaluated, [:evidence_integrity]}} = cert.verdict
  end

  test "a missing dimension is treated as unevaluated and blocks" do
    results = Map.delete(all_pass(), :adversarial_detection)
    cert = Pipeline.evaluate(results)

    refute MultiCertificate.certified?(cert)
    assert {:not_certified, {:dimensions_unevaluated, [:adversarial_detection]}} = cert.verdict
  end

  test "an advisory dimension failing does not block certification" do
    results = Map.put(all_pass(), :deterministic_replay, :fail)
    cert = Pipeline.evaluate(results)
    assert MultiCertificate.certified?(cert)
  end

  test "certificate renders dimensions and verdict" do
    cert = Pipeline.evaluate(all_pass())
    text = MultiCertificate.render(cert)

    assert text =~ "TIANNARA CERTIFICATION"
    assert text =~ "CERTIFIED"
    assert text =~ "constitutional_invariants"
    assert text =~ "[critical]"
  end

  test "integrates with the constitutional invariant suite" do
    run = Suite.run(Suite.new(Registry.default_invariants()))
    invariant_verdict = Gate.verdict(run)

    results = Map.put(all_pass(), :constitutional_invariants, invariant_verdict)
    cert = Pipeline.evaluate(results)

    assert MultiCertificate.certified?(cert)
  end
end