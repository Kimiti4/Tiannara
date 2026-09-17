defmodule Tiannara.Evidence.R0Test do
  @moduledoc """
  R0 acceptance tests covering all four mutation groups:
    R0-A: Provenance schema
    R0-B: Heartbeat quarantine
    R0-C: Certification gate
    R0-D: Historical quarantine
    Adversarial: no path for fabricated evidence
  """
  use ExUnit.Case, async: true

  alias Tiannara.Evidence.{Provenance, CertificationGate, HistoricalQuarantine}
  alias Tiannara.Research.Heartbeat

  # --- R0-A: provenance schema ---

  describe "R0-A: provenance schema" do
    test "builds real_execution provenance with required fields" do
      assert {:ok, p} = Provenance.build(kind: :real_execution, execution_id: "exec-1")
      assert p.kind == :real_execution
      assert p.execution_id == "exec-1"
    end

    test "rejects real_execution without execution_id" do
      assert {:error, :real_execution_requires_execution_id} =
               Provenance.build(kind: :real_execution)
    end

    test "rejects imported_evidence without source" do
      assert {:error, :imported_evidence_requires_source} =
               Provenance.build(kind: :imported_evidence)
    end

    test "rejects invalid kind" do
      assert {:error, {:invalid_provenance_kind, :fake}} =
               Provenance.build(kind: :fake)
    end

    test "unknown provenance is explicit and honest" do
      p = Provenance.unknown("test_reason")
      assert p.kind == :unknown
      assert p.audit_trail == ["unknown_provenance: test_reason"]
    end

    test "only real_execution and imported_evidence are acceptable" do
      assert Provenance.acceptable_as_evidence?(%{kind: :real_execution})
      assert Provenance.acceptable_as_evidence?(%{kind: :imported_evidence, source: "ext"})
      refute Provenance.acceptable_as_evidence?(%{kind: :simulation})
      refute Provenance.acceptable_as_evidence?(%{kind: :synthetic_fixture})
      refute Provenance.acceptable_as_evidence?(%{kind: :unknown})
    end

    test "hash is deterministic" do
      p = %{kind: :real_execution, source: nil, producer: nil, produced_at: ~U[2026-01-01 00:00:00Z], execution_id: "e1", experiment_id: nil, environment: nil, evidence_hash: nil, audit_trail: []}
      h1 = Provenance.hash(p)
      h2 = Provenance.hash(p)
      assert is_binary(h1)
      assert h1 == h2
    end

    test "builds simulation provenance" do
      assert {:ok, p} = Provenance.build(kind: :simulation, execution_id: "sim-1")
      assert p.kind == :simulation
    end

    test "builds synthetic_fixture provenance" do
      assert {:ok, p} = Provenance.build(kind: :synthetic_fixture)
      assert p.kind == :synthetic_fixture
    end
  end

  # --- R0-B: heartbeat quarantine ---

  describe "R0-B: heartbeat quarantine" do
    test "heartbeat produces NO fabricated scientific results" do
      assert {:ok, hb} = Heartbeat.beat(%{})
      assert hb.experiment_result == :not_executed
      assert hb.provenance.kind == :unknown
      assert hb.provenance.audit_trail == ["unknown_provenance: heartbeat_observational_only"]
    end

    test "heartbeat does not persist random values" do
      assert {:ok, hb} = Heartbeat.beat(%{})
      refute Map.has_key?(hb, :random_result)
      refute Map.has_key?(hb, :fabricated_p_value)
      refute Map.has_key?(hb, :experiment_outcome)
    end

    test "heartbeat state is one of the allowed observational states" do
      assert {:ok, hb} = Heartbeat.beat(%{})
      assert hb.state in [:healthy, :awaiting_experiment, :simulation_only, :degraded]
    end

    test "heartbeat has no confidence field" do
      assert {:ok, hb} = Heartbeat.beat(%{})
      refute Map.has_key?(hb, :confidence)
      refute Map.has_key?(hb, :p_value)
    end
  end

  # --- R0-C: certification gate ---

  describe "R0-C: certification gate" do
    test "accepts real_execution provenance" do
      artifact = %{provenance: %{kind: :real_execution, execution_id: "e1"}}
      assert {:accepted, ^artifact} = CertificationGate.evaluate(artifact)
    end

    test "accepts imported_evidence with source" do
      artifact = %{provenance: %{kind: :imported_evidence, source: "ext-source"}}
      assert {:accepted, ^artifact} = CertificationGate.evaluate(artifact)
    end

    test "rejects simulation provenance" do
      artifact = %{provenance: %{kind: :simulation}}
      assert {:rejected, ^artifact, "fabricated_or_synthetic:simulation"} =
               CertificationGate.evaluate(artifact)
    end

    test "rejects synthetic_fixture provenance" do
      artifact = %{provenance: %{kind: :synthetic_fixture}}
      assert {:rejected, ^artifact, "fabricated_or_synthetic:synthetic_fixture"} =
               CertificationGate.evaluate(artifact)
    end

    test "quarantines unknown provenance" do
      artifact = %{provenance: %{kind: :unknown}}
      assert {:quarantined, ^artifact, "unknown_provenance"} =
               CertificationGate.evaluate(artifact)
    end

    test "quarantines missing provenance" do
      artifact = %{}
      assert {:quarantined, ^artifact, "missing_provenance"} =
               CertificationGate.evaluate(artifact)
    end

    test "evaluate! raises RejectedError on simulation" do
      artifact = %{provenance: %{kind: :simulation}}
      assert_raise Tiannara.Evidence.RejectedError, ~r/fabricated/, fn ->
        CertificationGate.evaluate!(artifact)
      end
    end

    test "evaluate! raises QuarantinedError on unknown" do
      artifact = %{provenance: %{kind: :unknown}}
      assert_raise Tiannara.Evidence.QuarantinedError, ~r/unknown/, fn ->
        CertificationGate.evaluate!(artifact)
      end
    end
  end

  # --- R0-D: historical quarantine ---

  describe "R0-D: historical quarantine" do
    test "dry_run produces report without mutation" do
      report = HistoricalQuarantine.migrate(dry_run: true)
      assert report.dry_run == true
      assert is_map(report)
      assert Map.has_key?(report, :scanned)
      assert Map.has_key?(report, :quarantined)
      assert Map.has_key?(report, :audit_trail)
    end
  end

  # --- Adversarial: no path for fabrication ---

  describe "adversarial: no path for fabricated evidence" do
    test "heartbeat result cannot pass certification gate" do
      {:ok, hb} = Heartbeat.beat(%{})
      assert {:quarantined, _, "unknown_provenance"} = CertificationGate.evaluate(hb)
    end

    test "simulation cannot masquerade as real_execution" do
      simulated = %{provenance: %{kind: :simulation}}
      assert {:rejected, _, _} = CertificationGate.evaluate(simulated)
    end

    test "missing provenance is quarantined, not accepted" do
      assert {:quarantined, _, _} = CertificationGate.evaluate(%{id: "no-prov"})
    end

    test "malformed provenance is quarantined" do
      artifact = %{provenance: "not-a-map"}
      assert {:quarantined, _, reason} = CertificationGate.evaluate(artifact)
      assert String.contains?(reason, "malformed_provenance")
    end
  end
end
