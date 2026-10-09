defmodule TiannaraOS.Governance.CertificationLaboratoryFailClosedTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.Governance.Certification.Laboratory

  test "unimplemented authority fuzzing cannot certify a campaign" do
    assert {:error, %{campaign: :gc_002_authority_fuzzing,
                      certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_002_authority_fuzzing)
  end

  test "certificate verification refuses to run without a configured trust key" do
    previous_key = System.get_env("TIANNARA_CERT_PUBLIC_KEY")
    System.delete_env("TIANNARA_CERT_PUBLIC_KEY")

    on_exit(fn ->
      if is_binary(previous_key) do
        System.put_env("TIANNARA_CERT_PUBLIC_KEY", previous_key)
      else
        System.delete_env("TIANNARA_CERT_PUBLIC_KEY")
      end
    end)

    assert {:error, %{campaign: :gc_006_certificate_verification,
                      reason: :trusted_public_key_not_configured,
                      certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_006_certificate_verification)
  end

  test "stability campaigns cannot pass without a real mutation driver" do
    assert {:error, %{campaign: :gc_009_entropy_stability,
                      reason: :mutation_driver_not_implemented,
                      certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_009_entropy_stability)

    assert {:error, %{campaign: :gc_010_fitness_stability,
                      reason: :mutation_driver_not_implemented,
                      certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_010_fitness_stability)
  end


  test "GC-007 accepts a canonical SHA-256 evidence payload and rejects tampering" do
    original_cwd = File.cwd!()
    temp_root = Path.join(System.tmp_dir!(), "tiannara-gc007-#{System.unique_integer([:positive])}")
    evidence_dir = Path.join([temp_root, "evidence", "artifacts"])
    File.mkdir_p!(evidence_dir)

    on_exit(fn ->
      File.cd!(original_cwd)
      File.rm_rf!(temp_root)
    end)

    File.cd!(temp_root)
    payload = %{"artifact_id" => "gc007-fixture", "result" => "observed"}
    canonical = Jason.encode!(payload)
    hash = :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
    artifact_path = Path.join(evidence_dir, "fixture.json")
    File.write!(artifact_path, Jason.encode!(Map.put(payload, "sha256", hash)))

    assert {:ok, %{all_evidence_valid: true, verified_artifacts: 1}} =
             Laboratory.execute_campaign(:gc_007_evidence_verification)

    File.write!(artifact_path, Jason.encode!(%{
      "artifact_id" => "gc007-fixture",
      "result" => "tampered",
      "sha256" => hash
    }))

    assert {:error, %{failed_artifacts: 1}} =
             Laboratory.execute_campaign(:gc_007_evidence_verification)
  end

  test "GC-007 refuses to certify an empty evidence directory" do
    original_cwd = File.cwd!()
    temp_root = Path.join(System.tmp_dir!(), "tiannara-gc007-empty-#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join([temp_root, "evidence", "artifacts"]))

    on_exit(fn ->
      File.cd!(original_cwd)
      File.rm_rf!(temp_root)
    end)

    File.cd!(temp_root)

    assert {:error, %{reason: :no_evidence_artifacts}} =
             Laboratory.execute_campaign(:gc_007_evidence_verification)
  end

  test "long horizon evolution cannot certify a simulation as an executed evolution run" do
    assert {:error, %{campaign: :gc_012_long_horizon_evolution,
                      reason: :real_evolution_engine_not_executed,
                      certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_012_long_horizon_evolution)
  end
end
