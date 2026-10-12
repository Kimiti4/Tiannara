defmodule Tiannara.RealityAdmissionControlTest do
  use ExUnit.Case, async: false

  setup do
    keys = [:rac_acm_checker, :rac_oavl_checker, :rac_world_model_adapter]
    previous = Map.new(keys, &{&1, Application.get_env(:tiannara, &1)})
    Enum.each(keys, &Application.delete_env(:tiannara, &1))

    on_exit(fn ->
      Enum.each(previous, fn
        {key, nil} -> Application.delete_env(:tiannara, key)
        {key, value} -> Application.put_env(:tiannara, key, value)
      end)
    end)

    :ok
  end

  defp conclusion do
    %{
      statement: "The service is healthy",
      confidence: 0.7,
      uncertainty: 0.2,
      evidence: [%{source: "health-check", observation: "HTTP 200"}]
    }
  end

  test "unknown external validators prevent admission" do
    assert {:challenged, result} =
             Tiannara.RealityAdmissionControl.challenge_conclusion(conclusion(), :operations)

    assert result.statuses.acm == :unknown
    assert result.statuses.oavl == :unknown
    assert result.statuses.umsc == :pass
    assert result.admission_decision == :rejected_or_unverified
    assert {:error, {:rac_checks_not_passed, _}} =
             Tiannara.RealityAdmissionControl.admit_to_world_model(conclusion(), :operations, [])
  end

  test "UMSC rejects missing evidence and contradictory confidence bounds" do
    missing_evidence = %{conclusion() | evidence: []}
    assert %{status: :fail} =
             Tiannara.RealityAdmissionControl.umsc_uncertainty_check(%{output: missing_evidence})

    inconsistent = %{conclusion() | confidence: 0.9, uncertainty: 0.2}
    assert %{status: :fail, reason: :confidence_exceeds_complement_of_uncertainty} =
             Tiannara.RealityAdmissionControl.umsc_uncertainty_check(%{output: inconsistent})
  end

  test "caller-supplied PASS flags cannot bypass live checks" do
    forged = %{
      output: conclusion(),
      source: :operations,
      statuses: %{acm: :pass, oavl: :pass, umsc: :pass},
      admission_decision: :eligible_for_admission
    }

    assert {:error, {:rac_checks_not_passed, _}} =
             Tiannara.RealityAdmissionControl.admit_to_world_model(forged, :operations, [])
  end

  test "valid UMSC contract passes its local structural checks" do
    assert %{status: :pass, evidence: [%{check: :uncertainty_contract}]} =
             Tiannara.RealityAdmissionControl.umsc_uncertainty_check(%{output: conclusion()})
  end
end
