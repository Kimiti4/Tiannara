defmodule Tiannara.Autonomy.ConstitutionalValidatorTest do
  use ExUnit.Case, async: false

  alias Tiannara.Autonomy.ConstitutionalValidator

  defp valid_proposal do
    %{id: "prop1", title: "Optimize scheduler", objective: "Reduce latency",
      rationale: "Benchmarks show bottleneck", target: :scheduler,
      category: :performance, expected_impact: 0.5, confidence: 0.8,
      risk_level: :medium, rollback_plan: "Revert to previous config",
      human_approval_required: false,
      lineage: %{source: :improvement_engine, opportunity_id: "opp1"}}
  end

  describe "validate" do
    test "approves valid proposals" do
      assert {:approved, reason} = ConstitutionalValidator.validate(valid_proposal())
      assert reason =~ "All constitutional checks passed"
    end

    test "rejects proposal missing objective" do
      bad = %{valid_proposal() | objective: ""}
      assert {:rejected, reason} = ConstitutionalValidator.validate(bad)
      assert reason =~ "Mission alignment"
    end

    test "rejects proposal missing rationale" do
      bad = %{valid_proposal() | rationale: ""}
      assert {:rejected, reason} = ConstitutionalValidator.validate(bad)
      assert reason =~ "Mission alignment"
    end

    test "rejects proposal missing rollback plan" do
      bad = %{valid_proposal() | rollback_plan: ""}
      assert {:rejected, reason} = ConstitutionalValidator.validate(bad)
      assert reason =~ "Rollback availability"
    end

    test "rejects proposal missing lineage" do
      bad = %{valid_proposal() | lineage: nil}
      assert {:rejected, reason} = ConstitutionalValidator.validate(bad)
      assert reason =~ "Lineage preservation"
    end

    test "rejects high-risk proposal without human approval" do
      bad = %{valid_proposal() | risk_level: :high, human_approval_required: false}
      assert {:rejected, reason} = ConstitutionalValidator.validate(bad)
      assert reason =~ "Human augmentation"
    end

    test "rejects critical risk with low impact" do
      bad = %{valid_proposal() | risk_level: :critical, expected_impact: 0.3}
      assert {:rejected, reason} = ConstitutionalValidator.validate(bad)
      assert reason =~ "Risk proportionality"
    end

    test "rejects very low impact proposals" do
      bad = %{valid_proposal() | expected_impact: 0.05}
      assert {:rejected, reason} = ConstitutionalValidator.validate(bad)
      assert reason =~ "Complexity justification"
    end

    test "rejects proposal targeting legacy components" do
      bad = %{valid_proposal() | target: :legacy_system}
      assert {:rejected, reason} = ConstitutionalValidator.validate(bad)
      assert reason =~ "Long-term compatibility"
    end

    test "approved proposals pass all 8 checks" do
      assert {:approved, _} = ConstitutionalValidator.validate(valid_proposal())
    end
  end

  describe "total_violations" do
    test "counts accumulated violations" do
      before = ConstitutionalValidator.total_violations()
      ConstitutionalValidator.validate(%{valid_proposal() | objective: ""})
      assert ConstitutionalValidator.total_violations() == before + 1
    end
  end

  describe "status" do
    test "returns metrics" do
      status = ConstitutionalValidator.status()
      assert is_integer(status.total_validated)
      assert is_integer(status.total_approved)
      assert is_integer(status.total_rejected)
      assert is_integer(status.total_violations)
    end
  end
end
