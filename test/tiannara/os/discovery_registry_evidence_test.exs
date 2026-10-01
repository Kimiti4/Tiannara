defmodule TiannaraOS.DiscoveryRegistryEvidenceTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.DiscoveryRegistry

  setup do
    case Process.whereis(DiscoveryRegistry) do
      nil -> {:ok, _pid} = DiscoveryRegistry.start_link([])
      _pid -> :ok
    end

    :ok
  end

  defp base(id) do
    %{
      id: id,
      name: "evidence-gated discovery",
      domain_id: :test_domain,
      experiment_ids: ["exp-1"],
      evidence_ids: ["ev-1"],
      theory_ids: [:test_theory]
    }
  end

  test "registration cannot claim reproduced or operational validation" do
    assert {:error, :registration_must_start_simulated} =
             DiscoveryRegistry.register(Map.put(base(:registration_reproduced), :validation_status, :reproduced))

    assert {:error, :registration_must_start_simulated} =
             DiscoveryRegistry.register(Map.put(base(:registration_operational), :validation_status, :operationally_validated))
  end

  test "simulated discovery cannot become reproduced without reproduction evidence" do
    {:ok, _} = DiscoveryRegistry.register(base(:missing_reproduction))

    assert {:error, :reproduction_evidence_required} =
             DiscoveryRegistry.update_validation_status(:missing_reproduction, :reproduced, %{
               evidence_class: :simulated,
               execution_mode: :simulation
             })
  end

  test "simulated evidence cannot establish operational validation" do
    {:ok, _} = DiscoveryRegistry.register(base(:simulation_cannot_be_real))

    envelope = %{
      evidence_class: :simulated,
      execution_mode: :simulation,
      real_observation: true,
      effect_verified: true,
      acl_status: :pass,
      oavl_status: :pass
    }

    assert {:error, :real_evidence_required} =
             DiscoveryRegistry.update_validation_status(
               :simulation_cannot_be_real,
               :operationally_validated,
               envelope
             )
  end

  test "operational validation requires real execution and observed verified effect" do
    {:ok, _} = DiscoveryRegistry.register(base(:real_gate))

    reproduced = %{
      evidence_class: :simulated,
      execution_mode: :simulation,
      reproduction_evidence: %{runs: 3, independent: true}
    }

    assert {:ok, %{validation_status: :reproduced}} =
             DiscoveryRegistry.update_validation_status(:real_gate, :reproduced, reproduced)

    assert {:error, :real_execution_required} =
             DiscoveryRegistry.update_validation_status(:real_gate, :operationally_validated, %{
               evidence_class: :real,
               execution_mode: :simulation,
               real_observation: true,
               effect_verified: true,
               acl_status: :pass,
               oavl_status: :pass
             })
  end

  test "fully evidenced operational transition is accepted" do
    {:ok, _} = DiscoveryRegistry.register(base(:valid_real_transition))

    assert {:ok, %{validation_status: :reproduced}} =
             DiscoveryRegistry.update_validation_status(:valid_real_transition, :reproduced, %{
               evidence_class: :real,
               execution_mode: :real_execution,
               reproduction_evidence: %{runs: 3, independent: true}
             })

    assert {:ok, discovery} =
             DiscoveryRegistry.update_validation_status(:valid_real_transition, :operationally_validated, %{
               evidence_class: :real,
               execution_mode: :real_execution,
               real_observation: true,
               effect_verified: true,
               acl_status: :pass,
               oavl_status: :pass
             })

    assert discovery.validation_status == :operationally_validated
    assert discovery.confidence == 0.0
    assert discovery.uncertainty == 1.0
  end
end
