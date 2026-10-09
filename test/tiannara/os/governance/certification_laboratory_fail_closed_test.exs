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

  test "long horizon evolution cannot certify a simulation as an executed evolution run" do
    assert {:error, %{campaign: :gc_012_long_horizon_evolution,
                      reason: :real_evolution_engine_not_executed,
                      certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_012_long_horizon_evolution)
  end
end
