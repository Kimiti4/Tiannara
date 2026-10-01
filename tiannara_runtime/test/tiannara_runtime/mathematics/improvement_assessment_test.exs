defmodule TiannaraRuntime.Mathematics.ImprovementAssessmentTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.ImprovementAssessment

  test "mathematical merit alone cannot authorize an improvement" do
    evidence = %{
      mathematical_validity: :pass,
      necessity: :pass,
      system_impact: :pass,
      regression: :pass,
      safety: :pass,
      acl: :pass,
      oavl: :pass,
      cel: :pass,
      human_authorization: :missing
    }

    {:ok, result} = ImprovementAssessment.assess(%{change: :x}, evidence)
    assert result.status == :blocked_pending_evidence
    assert result.implementation_allowed == false
  end

  test "regression blocks implementation" do
    evidence = Map.new([
      {:necessity, :pass}, {:mathematical_validity, :pass},
      {:system_impact, :pass}, {:regression, :regression_detected},
      {:safety, :pass}, {:acl, :pass}, {:oavl, :pass}, {:cel, :pass},
      {:human_authorization, :pass}
    ])

    {:ok, result} = ImprovementAssessment.assess(%{}, evidence)
    assert result.status == :rejected
  end

  test "complete evidence still reaches human authorization gate" do
    evidence = Map.new([
      {:necessity, :pass}, {:mathematical_validity, :pass},
      {:system_impact, :pass}, {:regression, :pass}, {:safety, :pass},
      {:acl, :pass}, {:oavl, :pass}, {:cel, :pass},
      {:human_authorization, :pass}
    ])

    {:ok, result} = ImprovementAssessment.assess(%{}, evidence)
    assert result.status == :ready_for_human_authorization
    assert result.implementation_allowed == false
  end
end
