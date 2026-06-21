defmodule Tiannara.Core.EpistemicHistory do
  @moduledoc """
  Epistemic History Engine

  Tracks and records the evolution of the system's knowledge:
  - How beliefs have changed and why
  - Which predictions succeeded and which failed
  - How causal relationships have been corrected
  - How ontologies have evolved
  - Which realities were admitted and rejected

  This enables learning from experience and long-horizon adaptation.

  ## Architecture

  The epistemic history is NOT a log of events. It is a queryable knowledge graph
  that enables the system to answer questions like:

  - "Why did we change our mind about X?"
  - "What did we learn from that failed prediction?"
  - "How has domain Y's accuracy evolved over time?"
  - "Which beliefs are based on outdated assumptions?"
  - "What evidence could reverse this belief?"

  ## Integration Points

  - **World Model**: Queries history for confidence calibration
  - **GRCC**: Uses accuracy history for lineage fitness
  - **CIS**: Monitors belief revision rate as instability signal
  - **Domains**: Record outcomes for learning
  - **RAC**: Records admissions and challenges

  ## Structures

  Each history layer has its own module:
  - BeliefRevisions: confidence trajectory + evidence
  - FailedPredictions: outcomes + lessons learned
  - CausalCorrections: interventions + accuracy
  - OntologyEvolution: schema changes + impact
  - RealityAdmissions: RAC decisions + reasons
  """

  defstruct [
    :belief_revisions,      # BeliefRevisions registry
    :failed_predictions,    # FailedPredictions registry
    :causal_corrections,    # CausalCorrections registry
    :ontology_evolution,    # OntologyEvolution registry
    :reality_admissions,    # RealityAdmissions registry
    :created_at,
    :last_update
  ]

  @doc """
  Create a new Epistemic History engine.

  The history system tracks how the system's knowledge evolves.
  """
  def new do
    %__MODULE__{
      belief_revisions: %{},
      failed_predictions: %{},
      causal_corrections: %{},
      ontology_evolution: %{},
      reality_admissions: %{},
      created_at: DateTime.utc_now(),
      last_update: DateTime.utc_now()
    }
  end

  @doc """
  Record a belief revision in the epistemic history.

  When a belief's confidence changes, we record:
  - What changed
  - Why it changed (evidence type)
  - Impact on dependent knowledge
  """
  def record_belief_revision(history, belief_id, statement, old_confidence, new_confidence, reason) do
    revision = %{
      belief_id: belief_id,
      statement: statement,
      old_confidence: old_confidence,
      new_confidence: new_confidence,
      reason: reason,
      timestamp: DateTime.utc_now(),
      delta: new_confidence - old_confidence
    }

    updated_revisions = Map.put(
      history.belief_revisions,
      belief_id,
      [revision | Map.get(history.belief_revisions, belief_id, [])]
    )

    %{history | 
      belief_revisions: updated_revisions,
      last_update: DateTime.utc_now()
    }
  end

  @doc """
  Record a failed prediction and lessons learned.

  When a prediction doesn't match reality:
  - We record the prediction, actual outcome, confidence
  - Extract lessons for domain improvement
  - Track impact on affected lineages
  """
  def record_failed_prediction(history, prediction_id, domain, predicted, actual, confidence_before) do
    failed_pred = %{
      prediction_id: prediction_id,
      domain: domain,
      predicted: predicted,
      actual: actual,
      confidence_before: confidence_before,
      timestamp: DateTime.utc_now(),
      error_magnitude: calculate_error(predicted, actual),
      lesson: extract_lesson(predicted, actual)
    }

    updated_preds = Map.put(
      history.failed_predictions,
      prediction_id,
      failed_pred
    )

    %{history |
      failed_predictions: updated_preds,
      last_update: DateTime.utc_now()
    }
  end

  @doc """
  Record a causal correction.

  When a causal edge is revised based on evidence:
  - Record original and revised strength
  - Track evidence that triggered change
  - Note affected predictions
  """
  def record_causal_correction(history, causal_edge_id, original_strength, revised_strength, evidence) do
    correction = %{
      causal_edge_id: causal_edge_id,
      original_strength: original_strength,
      revised_strength: revised_strength,
      evidence: evidence,
      timestamp: DateTime.utc_now(),
      strength_delta: revised_strength - original_strength,
      affected_predictions: []  # Populated by caller
    }

    updated_corrections = Map.put(
      history.causal_corrections,
      causal_edge_id,
      [correction | Map.get(history.causal_corrections, causal_edge_id, [])]
    )

    %{history |
      causal_corrections: updated_corrections,
      last_update: DateTime.utc_now()
    }
  end

  @doc """
  Record an ontology evolution.

  When entity types or relationships change:
  - Record what changed (added, removed, modified)
  - Track impact on affected beliefs
  - Note cascading changes
  """
  def record_ontology_evolution(history, version, changes, affected_beliefs) do
    evolution = %{
      version: version,
      changes: changes,
      affected_beliefs: affected_beliefs,
      timestamp: DateTime.utc_now(),
      change_count: length(changes)
    }

    updated_evolution = Map.put(
      history.ontology_evolution,
      version,
      evolution
    )

    %{history |
      ontology_evolution: updated_evolution,
      last_update: DateTime.utc_now()
    }
  end

  @doc """
  Record a reality admission decision.

  When RAC admits or rejects a belief:
  - Record the belief and RAC decision
  - Track which challenges passed/failed
  - Note reasons for rejection if applicable
  """
  def record_reality_admission(history, belief_id, admitted?, challenges_results, reason) do
    admission = %{
      belief_id: belief_id,
      admitted?: admitted?,
      challenges_results: challenges_results,
      reason: reason,
      timestamp: DateTime.utc_now()
    }

    updated_admissions = Map.put(
      history.reality_admissions,
      belief_id,
      admission
    )

    %{history |
      reality_admissions: updated_admissions,
      last_update: DateTime.utc_now()
    }
  end

  @doc """
  Query belief revision history.

  Get the complete trajectory of how a belief evolved.
  """
  def get_belief_trajectory(history, belief_id) do
    Map.get(history.belief_revisions, belief_id, [])
    |> Enum.sort_by(& &1.timestamp)
  end

  @doc """
  Calculate learning impact from failed predictions.

  Determine which domains produced failed predictions and their accuracy.
  """
  def get_domain_accuracy(history, domain) do
    failed = Enum.filter(
      Map.values(history.failed_predictions),
      &(&1.domain == domain)
    )

    case length(failed) do
      0 -> nil
      count ->
        avg_error = Enum.map(failed, & &1.error_magnitude)
        |> Enum.sum()
        |> Kernel./(count)
        %{
          domain: domain,
          failed_count: count,
          avg_error: avg_error,
          accuracy: 1.0 - avg_error
        }
    end
  end

  @doc """
  Get ontology impact analysis.

  Show which beliefs were affected by ontology changes.
  """
  def get_ontology_impact(history) do
    history.ontology_evolution
    |> Map.values()
    |> Enum.map(fn evo ->
      %{
        version: evo.version,
        changes: evo.change_count,
        affected_beliefs: length(evo.affected_beliefs),
        timestamp: evo.timestamp
      }
    end)
  end

  @doc """
  Summarize system learning over time period.

  High-level view of how much the system has learned/changed.
  """
  def summarize_learning(history, start_time \\ nil) do
    belief_revisions = Enum.filter(
      Map.values(history.belief_revisions) |> Enum.flat_map(&(&1)),
      fn rev ->
        case start_time do
          nil -> true
          time -> DateTime.compare(rev.timestamp, time) != :lt
        end
      end
    )

    failed_predictions = Enum.filter(
      Map.values(history.failed_predictions),
      fn pred ->
        case start_time do
          nil -> true
          time -> DateTime.compare(pred.timestamp, time) != :lt
        end
      end
    )

    causal_corrections = Enum.filter(
      Map.values(history.causal_corrections) |> Enum.flat_map(&(&1)),
      fn corr ->
        case start_time do
          nil -> true
          time -> DateTime.compare(corr.timestamp, time) != :lt
        end
      end
    )

    %{
      total_belief_revisions: length(belief_revisions),
      avg_revision_delta: average_delta(belief_revisions),
      failed_predictions: length(failed_predictions),
      avg_prediction_error: average_error(failed_predictions),
      causal_corrections: length(causal_corrections),
      avg_causal_change: average_causal_change(causal_corrections),
      period_start: start_time || history.created_at,
      period_end: history.last_update
    }
  end

  # Private helpers

  defp calculate_error(predicted, actual) when is_number(predicted) and is_number(actual) do
    abs(predicted - actual) / max(abs(actual), 1)
  end

  defp calculate_error(_, _), do: 1.0

  defp extract_lesson(predicted, actual) do
    if predicted != actual do
      "Prediction #{predicted} contradicted by actual #{actual}"
    else
      "Prediction validated"
    end
  end

  defp average_delta(revisions) do
    case length(revisions) do
      0 -> 0.0
      count ->
        Enum.map(revisions, & &1.delta)
        |> Enum.sum()
        |> Kernel./(count)
    end
  end

  defp average_error(predictions) do
    case length(predictions) do
      0 -> 0.0
      count ->
        Enum.map(predictions, & &1.error_magnitude)
        |> Enum.sum()
        |> Kernel./(count)
    end
  end

  defp average_causal_change(corrections) do
    case length(corrections) do
      0 -> 0.0
      count ->
        Enum.map(corrections, &abs(&1.strength_delta))
        |> Enum.sum()
        |> Kernel./(count)
    end
  end
end
