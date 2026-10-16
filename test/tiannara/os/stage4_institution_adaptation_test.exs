defmodule TiannaraOS.Stage4InstitutionAdaptationTest do
  use ExUnit.Case, async: true

  alias TiannaraOS.{Stage4InstitutionAdaptation, MethodEvolutionResult}

  # Genuine-shaped proposals as produced by MethodEvolutionPipeline
  # (Phase B): category/description/expected_impact (float upper bound),
  # confidence :insufficient_data, implementation_complexity, risk_level,
  # supporting_episode_ids referencing retrieved episodes.
  defp genuine_mer(opts \\ []) do
    proposals =
      Keyword.get(opts, :proposals, [
        %{
          category: :data_quality,
          description: "Strengthen data quality gate",
          expected_impact: 0.15,
          confidence: :insufficient_data,
          implementation_complexity: :medium,
          risk_level: :low,
          supporting_episode_count: 3,
          supporting_episode_ids: ["ep_1", "ep_2", "ep_3"]
        }
      ])

    %MethodEvolutionResult{
      id: "mer_evidence_1",
      institution_id: :constitution_institution,
      candidate_improvements: proposals,
      competing_improvements: [],
      evidence_summary: %{insufficient_data_metrics: []},
      status: :completed
    }
  end

  # Legacy synthetic-shaped proposals (simulated mode only): self-asserted
  # evidence tags, improvement_id, priority, map-shaped expected_impact.
  defp synthetic_mer(opts \\ []) do
    proposals =
      Keyword.get(opts, :proposals, [
        %{
          improvement_id: "synth_prop_1",
          category: :caching,
          description: "Synthetic caching improvement",
          expected_impact: %{success_rate_increase: 0.4, efficiency_gain: 0.1},
          implementation_risk: :low,
          priority: :high,
          supporting_episodes: ["ep_a", "ep_b"],
          evidence_quality: :strong
        }
      ])

    %MethodEvolutionResult{
      id: "mer_synthetic_1",
      institution_id: :constitution_institution,
      candidate_improvements: proposals,
      competing_improvements: [],
      status: :completed
    }
  end

  defp stage_names(result) do
    Enum.map(result.stage_history || [], & &1.stage)
  end

  describe "execute_stage_4/3 evidence mode (default, fail-closed)" do
    test "rejects proposals with legacy synthetic shape" do
      out =
        Stage4InstitutionAdaptation.execute_stage_4(
          [synthetic_mer()],
          :constitution_institution,
          %{}
        )

      assert out.evidence_mode == :evidence_backed
      # Synthetic shape never passes the evidence gate; nothing is processed.
      assert out.total_adopted == 0
      assert out.total_deferred == 0
      assert out.adaptation_results == []
    end

    test "rejects proposals without supporting_episode_ids" do
      mer =
        genuine_mer(
          proposals: [
            %{
              category: :data_quality,
              description: "No references",
              expected_impact: 0.1,
              implementation_complexity: :low,
              risk_level: :low,
              supporting_episode_ids: []
            }
          ]
        )

      out = Stage4InstitutionAdaptation.execute_stage_4([mer], :constitution_institution, %{})
      assert out.adaptation_results == []
    end

    test "valid proposals are deferred, never adopted, without fabricated pilot metrics" do
      out =
        Stage4InstitutionAdaptation.execute_stage_4(
          [genuine_mer()],
          :constitution_institution,
          %{}
        )

      assert out.total_adopted == 0
      assert out.total_rejected == 0
      assert out.total_deferred == 1

      assert [result] = out.adaptation_results
      assert result.adoption_decision == :none_adopted
      assert result.simulation_results.evidence_source == :evidence_backed
      assert result.simulation_results.pilot_executed == false
      assert result.simulation_results.pilot_refusal_reason == :no_pilot_execution_capability
      assert result.simulation_results.adopted_proposals == []

      assert [deferred] = result.simulation_results.deferred_proposals
      assert deferred.deferral_reason == :awaiting_pilot_evidence
      assert deferred.supporting_episode_ids == ["ep_1", "ep_2", "ep_3"]
    end

    test "projection is labeled as upper bound and efficiency stays :insufficient_data" do
      out =
        Stage4InstitutionAdaptation.execute_stage_4(
          [genuine_mer()],
          :constitution_institution,
          %{}
        )

      assert [result] = out.adaptation_results
      assert [deferred] = result.simulation_results.deferred_proposals
      assert deferred.projection.projection_method == :upper_bound_decay
      assert deferred.projection.projected_success_upper_bound == 0.15
      assert deferred.projection.projected_efficiency_gain == :insufficient_data
    end

    test "lifecycle history contains only performed stages and no :governance_reviewed" do
      out =
        Stage4InstitutionAdaptation.execute_stage_4(
          [genuine_mer()],
          :constitution_institution,
          %{}
        )

      assert [result] = out.adaptation_results
      stages = stage_names(result)

      assert stages == [
               :proposal_received,
               :compatibility_analyzed,
               :risk_assessed,
               :projected,
               :decision_recorded
             ]

      refute :governance_reviewed in stages
      refute :simulated in stages
      refute :piloted in stages
    end

    test "no RNG: two identical runs produce identical decisions" do
      run1 = Stage4InstitutionAdaptation.execute_stage_4([genuine_mer()], :all, %{})
      run2 = Stage4InstitutionAdaptation.execute_stage_4([genuine_mer()], :all, %{})

      assert run1.total_deferred == run2.total_deferred
      assert run1.total_adopted == run2.total_adopted
      assert hd(run1.adaptation_results).adoption_decision ==
               hd(run2.adaptation_results).adoption_decision
    end

    test "invalid evidence_mode raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Stage4InstitutionAdaptation.execute_stage_4(
          [genuine_mer()],
          :constitution_institution,
          %{evidence_mode: :fabricated}
        )
      end
    end
  end

  describe "execute_stage_4/3 simulated mode (explicit opt-in)" do
    setup do
      :rand.seed(:exsss, {1, 2, 3})
      :ok
    end

    test "legacy synthetic shape is accepted and results are labeled :simulated" do
      out =
        Stage4InstitutionAdaptation.execute_stage_4(
          [synthetic_mer()],
          :constitution_institution,
          %{evidence_mode: :simulated}
        )

      assert out.evidence_mode == :simulated
      assert [result] = out.adaptation_results
      assert result.simulation_results.evidence_source == :simulated
      assert result.simulation_results.total_proposals_evaluated == 1
    end

    test "simulated results never claim :governance_reviewed" do
      out =
        Stage4InstitutionAdaptation.execute_stage_4(
          [synthetic_mer()],
          :constitution_institution,
          %{evidence_mode: :simulated}
        )

      assert [result] = out.adaptation_results
      stages = stage_names(result)
      refute :governance_reviewed in stages
    end

    test "genuine proposals without synthetic tags are filtered out in simulated mode" do
      out =
        Stage4InstitutionAdaptation.execute_stage_4(
          [genuine_mer()],
          :constitution_institution,
          %{evidence_mode: :simulated}
        )

      assert out.adaptation_results == []
    end
  end
end
