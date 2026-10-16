defmodule TiannaraOS.Stage5EvidenceLineageTest do
  use ExUnit.Case, async: true

  alias TiannaraOS.{Stage5CivilizationAdaptation, InstitutionAdaptationResult}

  # InstitutionAdaptationResult that passes the structural gates:
  # stage_history >= 7, constitutional compliance, rollback available,
  # and an explicit evidence_source label in simulation_results.
  defp structurally_valid_result(id, source) do
    %InstitutionAdaptationResult{
      id: id,
      institution_id: :constitution_institution,
      stage_history:
        Enum.map(1..8, fn i ->
          %{stage: :"stage_#{i}", timestamp: DateTime.utc_now(), metadata: %{}}
        end),
      constitutional_compliance: %{is_compliant: true, violations: []},
      rollback_available: true,
      simulation_results:
        Map.merge(
          %{adopted_proposals: [%{category: :caching, improvement_id: "imp_#{id}"}]},
          if(source, do: %{evidence_source: source}, else: %{})
        ),
      lifecycle_events: [],
      semantic_events: []
    }
  end

  defp unlabeled_result(id) do
    %InstitutionAdaptationResult{
      structurally_valid_result(id, nil)
      | simulation_results: %{adopted_proposals: [%{category: :caching, improvement_id: "imp_#{id}"}]}
    }
  end

  describe "evidence-source validation gate" do
    test "unlabeled inputs are rejected fail-closed" do
      result =
        Stage5CivilizationAdaptation.execute_stage_5(
          [unlabeled_result("a")],
          :test_civilization,
          []
        )

      assert result.status == :failed
      assert result.failure_reason == :no_valid_adaptations
      assert result.evidence_lineage == nil
    end

    test "empty input list is rejected fail-closed" do
      result = Stage5CivilizationAdaptation.execute_stage_5([], :test_civilization, [])

      assert result.status == :failed
      assert result.failure_reason == :no_valid_adaptations
    end
  end

  describe "evidence lineage labeling" do
    test "labeled :evidence_backed inputs produce evidence_backed lineage" do
      result =
        Stage5CivilizationAdaptation.execute_stage_5(
          [structurally_valid_result("a", :evidence_backed)],
          :test_civilization,
          []
        )

      assert result.evidence_lineage.weakest_input_source == :evidence_backed
      assert [%{adaptation_result_id: "a", evidence_source: :evidence_backed}] =
               result.evidence_lineage.inputs
    end

    test "synthetic inputs mark weakest source :synthetic and are never upgraded" do
      result =
        Stage5CivilizationAdaptation.execute_stage_5(
          [
            structurally_valid_result("a", :evidence_backed),
            structurally_valid_result("b", :synthetic)
          ],
          :test_civilization,
          []
        )

      assert result.evidence_lineage.weakest_input_source == :synthetic
      assert length(result.evidence_lineage.inputs) == 2

      sources = Enum.map(result.evidence_lineage.inputs, & &1.evidence_source)
      assert :synthetic in sources
    end

    test "rollout plan is labeled simulated" do
      result =
        Stage5CivilizationAdaptation.execute_stage_5(
          [structurally_valid_result("a", :evidence_backed)],
          :test_civilization,
          []
        )

      assert result.rollout_plan[:rollout_plan_source] == :simulated
    end
  end
end
