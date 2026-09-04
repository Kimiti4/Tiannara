defmodule Tiannara.Discovery.Discovery do
  alias Tiannara.Discovery.Domain.KnowledgeGap
  alias Tiannara.Discovery.DiscoveryScore

  defstruct [:id, :question, :gap, :hypotheses, :predictions, :experiments,
    :evidence, :conclusion, :score, :confidence, :uncertainty, :status,
    :lineage, :workflow_ids, :created_at, :updated_at, :completed_at, :metadata]

  @type t :: %__MODULE__{}

  @statuses [:question_formulated, :gap_identified, :hypotheses_generated,
    :predictions_made, :experiments_planned, :experiments_dispatched,
    :awaiting_evidence, :evidence_collected, :conclusion_reached,
    :knowledge_promoted, :completed, :abandoned]

  @valid_transitions %{
    question_formulated: [:gap_identified, :abandoned],
    gap_identified: [:hypotheses_generated, :abandoned],
    hypotheses_generated: [:predictions_made, :abandoned],
    predictions_made: [:experiments_planned, :abandoned],
    experiments_planned: [:experiments_dispatched, :abandoned],
    experiments_dispatched: [:awaiting_evidence, :abandoned],
    awaiting_evidence: [:evidence_collected, :abandoned],
    evidence_collected: [:conclusion_reached, :abandoned],
    conclusion_reached: [:knowledge_promoted, :abandoned],
    knowledge_promoted: [:completed],
    completed: [],
    abandoned: []
  }

  def statuses, do: @statuses

  def from_gap(%KnowledgeGap{} = gap) do
    %__MODULE__{
      id: generate_id(),
      question: "What explains #{gap.description} in the #{gap.domain} domain?",
      gap: gap, hypotheses: [], predictions: [], experiments: [], evidence: [],
      conclusion: nil, score: DiscoveryScore.from_gap(gap),
      confidence: 0.0, uncertainty: 1.0, status: :question_formulated,
      lineage: [%{event: :discovery_created, from_gap: gap.id, at: DateTime.utc_now()}],
      workflow_ids: [], created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(),
      completed_at: nil, metadata: %{}
    }
  end

  def transition(%__MODULE__{status: current} = disc, new_status) do
    allowed = Map.get(@valid_transitions, current, [])
    if new_status in allowed do
      updated = %{disc | status: new_status, updated_at: DateTime.utc_now(),
        lineage: disc.lineage ++ [%{event: :status_change, from: current, to: new_status, at: DateTime.utc_now()}]}
      updated = if new_status in [:completed, :abandoned], do: %{updated | completed_at: DateTime.utc_now()}, else: updated
      {:ok, updated}
    else
      {:error, {:invalid_transition, current, new_status}}
    end
  end

  def add_hypotheses(%__MODULE__{} = disc, hypotheses) when is_list(hypotheses) do
    %{disc | hypotheses: disc.hypotheses ++ hypotheses, updated_at: DateTime.utc_now(),
      lineage: disc.lineage ++ [%{event: :hypotheses_added, count: length(hypotheses),
        ids: Enum.map(hypotheses, & &1.id), at: DateTime.utc_now()}]}
  end

  def add_predictions(%__MODULE__{} = disc, predictions) when is_list(predictions) do
    %{disc | predictions: disc.predictions ++ predictions, updated_at: DateTime.utc_now(),
      lineage: disc.lineage ++ [%{event: :predictions_added, count: length(predictions),
        ids: Enum.map(predictions, & &1.id), at: DateTime.utc_now()}]}
  end

  def add_experiments(%__MODULE__{} = disc, experiments) when is_list(experiments) do
    %{disc | experiments: disc.experiments ++ experiments, updated_at: DateTime.utc_now(),
      lineage: disc.lineage ++ [%{event: :experiments_added, count: length(experiments),
        ids: Enum.map(experiments, & &1.id), at: DateTime.utc_now()}]}
  end

  def add_evidence(%__MODULE__{} = disc, results) when is_list(results) do
    new_confidence = compute_posterior(disc, results)
    %{disc | evidence: disc.evidence ++ results, confidence: new_confidence,
      uncertainty: 1.0 - new_confidence, updated_at: DateTime.utc_now(),
      lineage: disc.lineage ++ [%{event: :evidence_added, count: length(results),
        new_confidence: new_confidence, at: DateTime.utc_now()}]}
  end

  def conclude(%__MODULE__{} = disc, conclusion) when is_map(conclusion) do
    %{disc | conclusion: conclusion, updated_at: DateTime.utc_now(),
      lineage: disc.lineage ++ [%{event: :conclusion_reached, at: DateTime.utc_now()}]}
  end

  def complete(%__MODULE__{status: status} = disc) when status in [:completed, :abandoned], do: disc
  def complete(%__MODULE__{} = disc) do
    case walk_to_completion(disc, status_path(disc.status)) do
      {:ok, d} -> d
      {:error, _} -> disc
    end
  end

  defp status_path(:question_formulated), do: [:gap_identified, :hypotheses_generated, :predictions_made, :experiments_planned, :experiments_dispatched, :awaiting_evidence, :evidence_collected, :conclusion_reached, :knowledge_promoted, :completed]
  defp status_path(:gap_identified), do: [:hypotheses_generated, :predictions_made, :experiments_planned, :experiments_dispatched, :awaiting_evidence, :evidence_collected, :conclusion_reached, :knowledge_promoted, :completed]
  defp status_path(:hypotheses_generated), do: [:predictions_made, :experiments_planned, :experiments_dispatched, :awaiting_evidence, :evidence_collected, :conclusion_reached, :knowledge_promoted, :completed]
  defp status_path(:predictions_made), do: [:experiments_planned, :experiments_dispatched, :awaiting_evidence, :evidence_collected, :conclusion_reached, :knowledge_promoted, :completed]
  defp status_path(:experiments_planned), do: [:experiments_dispatched, :awaiting_evidence, :evidence_collected, :conclusion_reached, :knowledge_promoted, :completed]
  defp status_path(:experiments_dispatched), do: [:awaiting_evidence, :evidence_collected, :conclusion_reached, :knowledge_promoted, :completed]
  defp status_path(:awaiting_evidence), do: [:evidence_collected, :conclusion_reached, :knowledge_promoted, :completed]
  defp status_path(:evidence_collected), do: [:conclusion_reached, :knowledge_promoted, :completed]
  defp status_path(:conclusion_reached), do: [:knowledge_promoted, :completed]
  defp status_path(:knowledge_promoted), do: [:completed]
  defp status_path(_), do: []

  defp walk_to_completion(disc, []), do: {:ok, disc}
  defp walk_to_completion(disc, [next | rest]) do
    case transition(disc, next) do
      {:ok, d} -> walk_to_completion(d, rest)
      {:error, _} -> {:ok, disc}
    end
  end

  def terminal?(%__MODULE__{status: status}), do: status in [:completed, :abandoned]
  def lineage_depth(%__MODULE__{lineage: l}), do: length(l)

  defp generate_id, do: "disc_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  defp formulate_question(%KnowledgeGap{} = gap), do: "What explains #{gap.description} in the #{gap.domain} domain?"

  defp compute_posterior(%__MODULE__{confidence: prior}, []) do
    prior
  end

  defp compute_posterior(%__MODULE__{confidence: prior}, results) do
    evidence_strength = Enum.reduce(results, 0.0, fn r, acc -> acc + abs(Map.get(r, :confidence_delta, 0.0)) end) / length(results)
    weight = min(1.0, length(results) * 0.2)
    posterior = prior + (evidence_strength - prior) * weight
    max(0.0, min(1.0, posterior))
  end
end
