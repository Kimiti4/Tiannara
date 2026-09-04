defmodule Tiannara.Sentinel.Cognition.Interface do
  @moduledoc "Human Scientific Interface. Augments human intelligence, does not replace it."

  def generate_report(%Tiannara.Sentinel.Cognition.State{} = cs) do
    """
    =========================================
    SENTINEL INVESTIGATION REPORT
    =========================================
    Observation: #{cs.event.observation}

    Context:
    #{cs.context.synthesized_context}

    Causal Explanation:
    Root Cause: #{cs.causal.root_cause}
    Confidence: #{cs.causal.confidence}

    Hypothesis:
    #{cs.hypothesis.hypothesis}

    Prediction:
    #{cs.prediction.forecast} (Confidence: #{cs.prediction.confidence})

    Research Priority:
    Tier: #{cs.priority.tier} (Score: #{Float.round(cs.priority.score, 2)})

    Proposed Experiment:
    Question: #{cs.experiment.research_question}
    Expected Outcome: #{cs.experiment.expected_outcome}
    Failure Conditions: #{Enum.join(cs.experiment.failure_conditions, ", ")}
    Rollback Plan: #{cs.experiment.rollback_plan}

    Epistemic Confidence:
    Overall: #{cs.confidence.confidence} | Evidence Quality: #{cs.confidence.evidence_quality}
    Contradictions: #{cs.confidence.contradictions} | Unknowns: #{cs.confidence.unknowns}

    =========================================
    HUMAN DECISION REQUIRED:
    Approve, modify, or reject the proposed experiment.
    =========================================
    """
  end
end
