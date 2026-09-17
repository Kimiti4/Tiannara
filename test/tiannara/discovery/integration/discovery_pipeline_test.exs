defmodule Tiannara.Discovery.Integration.DiscoveryPipelineTest do
  use ExUnit.Case, async: false

  alias Tiannara.Discovery.{Discovery, EvidenceIntegrator, DiscoveryLineage, DiscoverySupervisor, DiscoveryEngine, DiscoveryMetrics}
  alias Tiannara.Discovery.Domain.{KnowledgeGap, HypothesisSpec, PredictionSpec, DiscoveryResult}

  setup do
    # The app boot (ControlCenter) already starts DiscoveryEngine and
    # DiscoveryScheduler; start only the children that are not running.
    ensure_running(DiscoveryEngine, [])
    ensure_running(Tiannara.Discovery.DiscoveryScheduler, [interval_ms: 30 * 60 * 1000])
    ensure_running(DiscoveryMetrics, [])
    :ok
  end

  defp ensure_running(module, opts) do
    case Process.whereis(module) do
      nil ->
        case module.start_link(opts) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
          _ -> :ok
        end

      _ ->
        :ok
    end
  end

  describe "gap-to-promotion pipeline" do
    test "full pipeline from gap to evidence integration" do
      gap = KnowledgeGap.new(%{domain: :epistemic_consistency,
        description: "Pipeline integration test gap",
        severity: :high, estimated_impact: 0.8, source: :provenance})
      {:ok, disc} = DiscoveryEngine.create_discovery(gap)
      assert disc.status == :question_formulated

      hypotheses = [
        HypothesisSpec.new(%{gap_id: gap.id, statement: "Pipeline test hypothesis 1",
          domain: :epistemic_consistency, prior: 0.5, metadata: %{causal_model: :hidden_confound}}),
        HypothesisSpec.new(%{gap_id: gap.id, statement: "Pipeline test hypothesis 2",
          domain: :epistemic_consistency, prior: 0.5, metadata: %{causal_model: :boundary_condition_divergence}})
      ]
      disc = Discovery.add_hypotheses(disc, hypotheses)
      {:ok, disc} = Discovery.transition(disc, :gap_identified)
      {:ok, disc} = Discovery.transition(disc, :hypotheses_generated)

      predictions = Enum.flat_map(disc.hypotheses, fn hyp ->
        [PredictionSpec.new(%{hypothesis_id: hyp.id, statement: "Pipeline pred for #{hyp.id}",
          falsification_criteria: "p < 0.05", confidence: 0.6})]
      end)
      disc = Discovery.add_predictions(disc, predictions)
      {:ok, disc} = Discovery.transition(disc, :predictions_made)

      all_experiments = Enum.flat_map(disc.hypotheses, fn hyp ->
        hyp_predictions = Enum.filter(disc.predictions, &(&1.hypothesis_id == hyp.id))
        Tiannara.Discovery.ExperimentPlanner.plan(hyp, hyp_predictions)
      end)
      disc = Discovery.add_experiments(disc, all_experiments)
      {:ok, disc} = Discovery.transition(disc, :experiments_planned)
      assert length(disc.experiments) > 0
      assert disc.status == :experiments_planned

      results = [
        DiscoveryResult.new(%{experiment_id: hd(disc.experiments).id,
          hypothesis_id: hd(disc.experiments).hypothesis_id,
          outcome: :supported, evidence: [%{type: :simulation, value: 0.85}],
          confidence_delta: 0.3, posterior: 0.8}),
        DiscoveryResult.new(%{experiment_id: hd(disc.experiments).id,
          hypothesis_id: hd(disc.experiments).hypothesis_id,
          outcome: :supported, evidence: [%{type: :validation, value: 0.9}],
          confidence_delta: 0.2, posterior: 0.85})
      ]

      evaluations = EvidenceIntegrator.integrate(results)
      assert length(evaluations) == 1
      assert hd(evaluations).outcome == :supported
      assert hd(evaluations).confidence_delta == 0.5

      {:ok, routed} = DiscoveryEngine.route_evidence(disc.id, results)
      assert routed.discovery.evidence |> length() == 2
      assert routed.evaluations |> length() == 1
      assert routed.integrity == :ok
    end

    test "lineage integrity is maintained through lifecycle" do
      gap = KnowledgeGap.new(%{domain: :evidence_quality,
        description: "Lineage integrity test", severity: :medium,
        estimated_impact: 0.5, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)
      assert DiscoveryLineage.verify_integrity(disc) == :ok

      disc = Discovery.add_hypotheses(disc, [
        HypothesisSpec.new(%{gap_id: gap.id, statement: "Lineage test hyp",
          domain: :evidence_quality, prior: 0.5})
      ])
      assert DiscoveryLineage.verify_integrity(disc) == :ok

      disc = Discovery.add_evidence(disc, [%{type: :test, confidence_delta: 0.2}])
      assert DiscoveryLineage.verify_integrity(disc) == :ok

      lineage = DiscoveryLineage.trace(disc)
      assert length(lineage) == 3
      path = DiscoveryLineage.discovery_path(disc)
      assert :discovery_created in path
      assert :hypotheses_added in path
      assert :evidence_added in path

      summary = DiscoveryLineage.summarize(disc)
      assert summary.steps == 3
      assert summary.integrity == :valid
    end
  end

  describe "evidence integration and promotion preparation" do
    test "promotion payload is correctly prepared without KC delegation" do
      result = DiscoveryResult.new(%{experiment_id: "exp_int",
        hypothesis_id: "hyp_int", outcome: :supported,
        evidence: [%{type: :observation, value: 0.95}],
        confidence_delta: 0.4, posterior: 0.9})
      payload = EvidenceIntegrator.prepare_promotion(result, %{confidence: 0.5})
      assert payload.type == :evidence_promotion
      refute Map.has_key?(payload, :call_knowledge_coordinator)
      refute Map.has_key?(payload, :promote)
    end

    test "multiple experiments produce correct aggregate outcomes" do
      results = [
        DiscoveryResult.new(%{experiment_id: "exp_a", hypothesis_id: "hyp_1",
          outcome: :supported, evidence: [%{v: 0.8}], confidence_delta: 0.2, posterior: 0.7}),
        DiscoveryResult.new(%{experiment_id: "exp_b", hypothesis_id: "hyp_1",
          outcome: :falsified, evidence: [%{v: 0.1}], confidence_delta: -0.3, posterior: 0.2}),
        DiscoveryResult.new(%{experiment_id: "exp_c", hypothesis_id: "hyp_2",
          outcome: :supported, evidence: [%{v: 0.9}], confidence_delta: 0.3, posterior: 0.8})
      ]
      evaluations = EvidenceIntegrator.integrate(results)
      assert length(evaluations) == 3
      exp_a = Enum.find(evaluations, fn e -> e.experiment_id == "exp_a" end)
      exp_b = Enum.find(evaluations, fn e -> e.experiment_id == "exp_b" end)
      assert exp_a.outcome == :supported
      assert exp_b.outcome == :falsified
    end
  end

  describe "metrics tracking" do
    test "metrics are tracked through discovery lifecycle" do
      DiscoveryMetrics.track_event(:discovery_created, %{gap_id: "gap_1"})
      DiscoveryMetrics.track_event(:experiments_planned, %{count: 3})
      DiscoveryMetrics.track_event(:experiments_dispatched, %{count: 2})
      DiscoveryMetrics.track_event(:evidence_collected, %{evidence_count: 5, confidence_delta: 0.8})
      DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :supported, stage: :analysis, duration_ms: 100})
      DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :supported, stage: :analysis, duration_ms: 200})
      DiscoveryMetrics.track_event(:discovery_completed, %{})

      :timer.sleep(50)

      velocity = DiscoveryMetrics.get_discovery_velocity()
      assert velocity.completed >= 1

      success = DiscoveryMetrics.get_experiment_success_rate()
      assert success.supported >= 1

      summary = DiscoveryMetrics.get_metrics_summary()
      assert summary.discoveries.initiated >= 1
      assert summary.discoveries.completed >= 1
      assert summary.experiments.planned >= 3
      assert summary.experiments.dispatched >= 2
      assert summary.evidence.collected >= 5
    end
  end
end
