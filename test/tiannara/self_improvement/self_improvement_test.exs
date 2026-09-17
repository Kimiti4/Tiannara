defmodule Tiannara.SelfImprovement.SelfImprovementTest do
  use ExUnit.Case, async: true

  alias Tiannara.SelfImprovement.{Pipeline, Proposal, GateResult, ProtectedCore}

  @moduletag :omega4_self_improvement

  defp gr(gate, passed, source),
    do: %GateResult{gate: gate, passed: passed, source: source, evidence: []}

  defp passing_gates do
    %{
      tests: gr(:tests, true, :ci),
      benchmark: gr(:benchmark, true, :ci),
      adversarial_validation: gr(:adversarial_validation, true, :adversarial_lab),
      constitutional_review: gr(:constitutional_review, true, :constitutional_reviewer),
      human_approval: gr(:human_approval, true, :human)
    }
  end

  test "deployment is disabled by default even when all gates pass" do
    p = %Proposal{id: :p1, targets: [:inference_module]}
    assert {:error, :deployment_disabled} = Pipeline.request_deployment(p, passing_gates())
  end

  test "deployment authorized when enabled and all gates pass (non-protected)" do
    p = %Proposal{id: :p1, targets: [:inference_module]}

    assert {:ok, :deployment_authorized} =
             Pipeline.request_deployment(p, passing_gates(), deployment_enabled: true)
  end

  test "a failed gate blocks deployment" do
    gates = Map.put(passing_gates(), :tests, gr(:tests, false, :ci))
    p = %Proposal{id: :p1, targets: [:inference_module]}

    assert {:error, {:gates_failed, [:tests]}} =
             Pipeline.request_deployment(p, gates, deployment_enabled: true)
  end

  test "missing human approval blocks deployment" do
    gates = Map.delete(passing_gates(), :human_approval)
    p = %Proposal{id: :p1, targets: [:inference_module]}

    assert {:error, {:gates_failed, [:human_approval]}} =
             Pipeline.request_deployment(p, gates, deployment_enabled: true)
  end

  test "protected-core change without independent verification is blocked" do
    p = %Proposal{id: :p2, targets: [:authorization]}

    assert {:error, :protected_core_requires_independent_verification} =
             Pipeline.request_deployment(p, passing_gates(), deployment_enabled: true)
  end

  test "protected-core change with EXTERNAL independent verification is authorized" do
    gates =
      Map.put(passing_gates(), :independent_verification,
        gr(:independent_verification, true, :external_auditor))

    p = %Proposal{id: :p2, targets: [:authorization]}

    assert {:ok, :deployment_authorized} =
             Pipeline.request_deployment(p, gates, deployment_enabled: true)
  end

  test "protected-core change with SELF attestation is rejected" do
    gates =
      Map.put(passing_gates(), :independent_verification,
        gr(:independent_verification, true, :self_improvement))

    p = %Proposal{id: :p3, targets: [:constitutional]}

    assert {:error, :protected_core_requires_independent_verification} =
             Pipeline.request_deployment(p, gates, deployment_enabled: true)
  end

  test "protected core enumerates authorization, constitutional, audit, safety" do
    assert ProtectedCore.protected_subsystems() == [:authorization, :constitutional, :audit, :safety]
  end
end