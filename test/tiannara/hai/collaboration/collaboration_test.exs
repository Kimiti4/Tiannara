defmodule Tiannara.HAI.Collaboration.CollaborationTest do
  use ExUnit.Case, async: true

  alias Tiannara.HAI.Collaboration.{DebateInterface, ScientificNotebook}
  alias Tiannara.Discovery.{Discovery, HypothesisGenerator, PredictionEngine, ExperimentPlanner}
  alias Tiannara.Discovery.Domain.{KnowledgeGap, DiscoveryResult}

  defp build_discovery do
    gap = KnowledgeGap.new(%{
      domain: :epistemic_consistency,
      description: "Sensor discrepancy between A and B",
      severity: :high,
      estimated_impact: 0.8,
      source: :epistemic_integrity
    })

    disc = Discovery.from_gap(gap)
    hypotheses = HypothesisGenerator.generate(gap)
    disc = Discovery.add_hypotheses(disc, hypotheses)

    predictions = Enum.flat_map(hypotheses, &PredictionEngine.generate/1)
    disc = Discovery.add_predictions(disc, predictions)

    experiments = Enum.flat_map(hypotheses, fn hyp ->
      hyp_preds = Enum.filter(predictions, &(&1.hypothesis_id == hyp.id))
      ExperimentPlanner.plan(hyp, hyp_preds)
    end)
    disc = Discovery.add_experiments(disc, experiments)

    results = [
      DiscoveryResult.new(%{
        experiment_id: "e1", hypothesis_id: hd(hypotheses).id,
        outcome: :confirmed, evidence: [%{type: :measurement, source: :sensor_a, value: 42.5}],
        confidence_delta: 0.2, posterior: 0.7
      })
    ]

    Discovery.add_evidence(disc, results)
  end

  describe "DebateInterface" do
    test "structures a debate with all required sections" do
      disc = build_discovery()
      debate = DebateInterface.structure_debate(disc)

      assert debate.discovery_id == disc.id
      assert debate.question == disc.question
      assert length(debate.positions) == length(disc.hypotheses)
      assert is_list(debate.points_of_agreement)
      assert is_list(debate.points_of_contention)
      assert is_list(debate.missing_evidence)
      assert is_list(debate.decision_criteria)
      assert is_binary(debate.system_recommendation)
    end

    test "renders a readable debate document" do
      disc = build_discovery()
      debate = DebateInterface.structure_debate(disc)
      rendered = DebateInterface.render(debate)

      assert is_binary(rendered)
      assert String.contains?(rendered, "SCIENTIFIC DEBATE")
      assert String.contains?(rendered, "COMPETING POSITIONS")
      assert String.contains?(rendered, "CONFIDENCE DISCLOSURE")
      assert String.contains?(rendered, "You may override it")
    end

    test "positions are ranked by prior" do
      disc = build_discovery()
      debate = DebateInterface.structure_debate(disc)

      priors = Enum.map(debate.positions, & &1.prior)
      assert priors == Enum.sort(priors, :desc)
    end
  end

  describe "ScientificNotebook" do
    test "generates a complete notebook" do
      disc = build_discovery()
      notebook = ScientificNotebook.generate(disc)

      assert notebook.discovery_id == disc.id
      assert length(notebook.sections) == 7
      assert notebook.metadata.confidence == disc.confidence
    end

    test "renders a readable notebook document" do
      disc = build_discovery()
      notebook = ScientificNotebook.generate(disc)
      rendered = ScientificNotebook.render(notebook)

      assert is_binary(rendered)
      assert String.contains?(rendered, "Introduction")
      assert String.contains?(rendered, "Methodology")
      assert String.contains?(rendered, "Results")
      assert String.contains?(rendered, "Reproducibility Guide")
    end
  end
end
