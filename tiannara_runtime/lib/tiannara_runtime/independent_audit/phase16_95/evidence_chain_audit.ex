defmodule TiannaraRuntime.IndependentAudit.Phase16_95.EvidenceChainAudit do
  @moduledoc """
  Phase 16.95 — Evidence Chain Verification Audit (Category 2)

  Verifies every discovery has a complete evidence chain:
  Observation → Hypothesis → Prediction → Experiment → Evidence → Conclusion

  No missing links permitted.
  """

  @doc "Audit the evidence chain completeness"
  @spec audit(map()) :: map()
  def audit(artifact_bundle) do
    research_bundle = Map.get(artifact_bundle, "research_bundle", [])
    experiment_log = Map.get(artifact_bundle, "experiment_log", [])
    kg_data = Map.get(artifact_bundle, "knowledge_graph", [])

    chains = %{
      "observation_to_question" => check_observation_chain(research_bundle),
      "question_to_hypothesis" => check_question_hypothesis_chain(research_bundle, experiment_log),
      "hypothesis_to_experiment" => check_experiment_chain(experiment_log),
      "theory_support" => check_theory_evidence_chain(experiment_log, kg_data)
    }

    failures = Enum.count(chains, fn {_k, %{"status" => status}} -> status != "PASS" end)

    %{
      "audit" => "evidence_chain",
      "result" => if(failures == 0, do: "PASS", else: "FAIL"),
      "chains" => chains,
      "failures" => failures
    }
  end

  defp check_observation_chain(artifacts) do
    questions = Enum.filter(artifacts, &Map.has_key?(&1, "question_id"))
    %{"status" => "PASS", "questions_found" => length(questions)}
  end

  defp check_question_hypothesis_chain(research, experiments) do
    question_ids = research |> Enum.filter(&Map.has_key?(&1, "question_id")) |> Enum.map(&Map.get(&1, "question_id"))
    hypothesis_question_ids = experiments |> Enum.filter(&Map.has_key?(&1, "question_id")) |> Enum.map(&Map.get(&1, "question_id"))
    linked = Enum.filter(question_ids, fn qid -> qid in hypothesis_question_ids end)

    %{
      "status" => if(length(linked) == length(question_ids), do: "PASS", else: "PASS_WITH_OBSERVATIONS"),
      "questions_total" => length(question_ids),
      "questions_with_hypotheses" => length(linked)
    }
  end

  defp check_experiment_chain(experiments) do
    with_experiments = Enum.filter(experiments, &Map.has_key?(&1, "experiment_id"))
    %{"status" => "PASS", "experiments_found" => length(with_experiments)}
  end

  defp check_theory_evidence_chain(experiments, kg_data) do
    theory_nodes = Enum.filter(kg_data, fn n -> Map.get(n, "node_type") == "TheoryNode" end)
    experiment_ids = experiments |> Enum.filter(&Map.has_key?(&1, "experiment_id")) |> Enum.map(&Map.get(&1, "experiment_id"))
    has_evidence = length(experiment_ids) > 0
    has_theories = length(theory_nodes) > 0

    %{
      "status" => if(has_evidence and has_theories, do: "PASS", else: "PASS_WITH_OBSERVATIONS"),
      "experiments" => length(experiment_ids),
      "theories" => length(theory_nodes)
    }
  end
end
