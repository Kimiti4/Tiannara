defmodule TiannaraOS.Kernel.GenerationHistory do
  @moduledoc """
  GenerationHistory - Immutable historical record of a single civilization generation.

  This artifact captures the complete state of the research civilization after executing
  one full generation cycle (Stages 1-5). It provides longitudinal evidence for Stage 6
  validation that recursive adaptation produces measurable improvement.

  ## Constitutional Role

  GenerationHistory is append-only and immutable. Once created, it cannot be modified.
  This ensures that longitudinal analysis is based on genuine execution history, not
  fabricated metrics.

  ## Constitutional Compliance (Phase 13.5B.3)

  GenerationHistory stores ONLY references to constitutional artifacts:
  - `manifest_id`: Reference to ConstitutionManifest (owns all hashes)
  - `certificate_id`: Reference to ConstitutionCertificate (execution attestation)

  All component hashes are reconstructed from the referenced Manifest.
  No duplicate hash storage anywhere in GenerationHistory.

  ## Fields

  - `generation_number`: Sequential generation identifier
  - `timestamp`: When this generation completed
  - `execution_duration_ms`: Total time to execute all stages
  - `episodes_created`: Number of new ResearchEpisodes generated
  - `discoveries_made`: Number of discoveries produced
  - `theories_formed`: Number of theories created/updated
  - `unknowns_resolved`: Number of unknown dependencies resolved
  - `research_debt`: Current research debt level
  - `adaptations_evaluated`: Count of adaptations considered
  - `adaptations_adopted`: Count of adaptations approved
  - `prediction_accuracy`: Aggregate prediction quality metrics
  - `civilization_adaptation_index`: Composite civilizational health metric
  - `resource_utilization`: Resource consumption metrics
  - `scientific_capital`: Accumulated scientific knowledge value
  - `institution_diversity`: Measure of institutional specialization diversity
  - `method_diversity`: Measure of method variety
  - `collaboration_density`: Network density of inter-institution collaboration
  - `mission_control_snapshot`: Point-in-time Mission Control data
  - `executive_dashboard_snapshot`: Point-in-time Executive Dashboard data
  - `ledger_snapshot`: Economic ledger state
  - `knowledge_graph_snapshot`: Knowledge graph statistics
  - `canonical_transactions`: References to all canonical transactions produced
  - `manifest_id`: Reference to ConstitutionManifest (constitutional SBOM)
  - `certificate_id`: Reference to ConstitutionCertificate (execution proof)

  ## Usage

      history = GenerationHistory.new(%{
        generation_number: 1,
        episodes_created: 200,
        discoveries_made: 15,
        manifest_id: "MANIFEST-abc123...",
        certificate_id: "CERT-xyz789...",
        ...
      })

      # Append to history file (immutable)
      GenerationHistory.append_to_file(history, "data/generation_history.csv")
  """

  defstruct [
    # Core identification
    :generation_number,
    :timestamp,
    :execution_duration_ms,

    # Scientific output
    :episodes_created,
    :discoveries_made,
    :theories_formed,
    :unknowns_resolved,

    # Research health
    :research_debt,
    :research_velocity,
    :replication_success_rate,

    # Adaptation metrics
    :adaptations_evaluated,
    :adaptations_adopted,
    :adaptations_rejected,
    :adaptation_success_rate,

    # Prediction quality
    :prediction_accuracy,
    :prediction_calibration,
    :prediction_reliability,

    # Civilization health
    :civilization_adaptation_index,
    :scientific_capital,
    :institution_diversity,
    :method_diversity,
    :collaboration_density,

    # Resource metrics
    :resource_utilization,
    :budget_remaining,
    :credits_spent,

    # Snapshots
    :mission_control_snapshot,
    :executive_dashboard_snapshot,
    :ledger_snapshot,
    :knowledge_graph_snapshot,

    # Provenance
    :canonical_transaction_ids,
    :stage3_results_count,
    :stage4_results_count,
    :stage5_result_id,

    # Metadata
    :constitutional_violations,
    :lifecycle_completeness_pct,
    :rollback_frequency,

    # Constitutional references (Phase 13.5B.3 - Single Source of Truth)
    :manifest_id,      # Reference to ConstitutionManifest (owns all hashes)
    :certificate_id    # Reference to ConstitutionCertificate (execution attestation)
  ]

  @type t :: %__MODULE__{
    generation_number: pos_integer(),
    timestamp: DateTime.t(),
    execution_duration_ms: non_neg_integer(),
    episodes_created: non_neg_integer(),
    discoveries_made: non_neg_integer(),
    theories_formed: non_neg_integer(),
    unknowns_resolved: non_neg_integer(),
    research_debt: non_neg_integer(),
    research_velocity: float(),
    replication_success_rate: float() | nil,
    adaptations_evaluated: non_neg_integer(),
    adaptations_adopted: non_neg_integer(),
    adaptations_rejected: non_neg_integer(),
    adaptation_success_rate: float(),
    prediction_accuracy: map() | nil,
    prediction_calibration: float() | nil,
    prediction_reliability: float() | nil,
    civilization_adaptation_index: float() | nil,
    scientific_capital: float(),
    institution_diversity: float(),
    method_diversity: float(),
    collaboration_density: float(),
    resource_utilization: map(),
    budget_remaining: non_neg_integer(),
    credits_spent: non_neg_integer(),
    mission_control_snapshot: map() | nil,
    executive_dashboard_snapshot: map() | nil,
    ledger_snapshot: map() | nil,
    knowledge_graph_snapshot: map() | nil,
    canonical_transaction_ids: [String.t()],
    stage3_results_count: non_neg_integer(),
    stage4_results_count: non_neg_integer(),
    stage5_result_id: String.t() | nil,
    constitutional_violations: non_neg_integer(),
    lifecycle_completeness_pct: float(),
    rollback_frequency: float(),
    manifest_id: String.t() | nil,
    certificate_id: String.t() | nil
  }

  @doc """
  Create a new GenerationHistory record.

  ## Parameters
  - `opts`: Keyword list or map with history fields

  ## Returns
  %GenerationHistory{}

  ## Examples

      GenerationHistory.new(%{
        generation_number: 1,
        episodes_created: 200,
        discoveries_made: 15,
        manifest_id: "MANIFEST-abc123",
        certificate_id: "CERT-xyz789"
      })
  """
  def new(opts \\ []) do
    opts = if is_map(opts), do: Map.to_list(opts), else: opts

    %__MODULE__{
      generation_number: Keyword.get(opts, :generation_number),
      timestamp: DateTime.utc_now(),
      execution_duration_ms: Keyword.get(opts, :execution_duration_ms, 0),
      episodes_created: Keyword.get(opts, :episodes_created, 0),
      discoveries_made: Keyword.get(opts, :discoveries_made, 0),
      theories_formed: Keyword.get(opts, :theories_formed, 0),
      unknowns_resolved: Keyword.get(opts, :unknowns_resolved, 0),
      research_debt: Keyword.get(opts, :research_debt, 0),
      research_velocity: Keyword.get(opts, :research_velocity, 0.0),
      replication_success_rate: Keyword.get(opts, :replication_success_rate),
      adaptations_evaluated: Keyword.get(opts, :adaptations_evaluated, 0),
      adaptations_adopted: Keyword.get(opts, :adaptations_adopted, 0),
      adaptations_rejected: Keyword.get(opts, :adaptations_rejected, 0),
      adaptation_success_rate: Keyword.get(opts, :adaptation_success_rate, 0.0),
      prediction_accuracy: Keyword.get(opts, :prediction_accuracy),
      prediction_calibration: Keyword.get(opts, :prediction_calibration),
      prediction_reliability: Keyword.get(opts, :prediction_reliability),
      civilization_adaptation_index: Keyword.get(opts, :civilization_adaptation_index),
      scientific_capital: Keyword.get(opts, :scientific_capital, 0.0),
      institution_diversity: Keyword.get(opts, :institution_diversity, 0.0),
      method_diversity: Keyword.get(opts, :method_diversity, 0.0),
      collaboration_density: Keyword.get(opts, :collaboration_density, 0.0),
      resource_utilization: Keyword.get(opts, :resource_utilization, %{}),
      budget_remaining: Keyword.get(opts, :budget_remaining, 0),
      credits_spent: Keyword.get(opts, :credits_spent, 0),
      mission_control_snapshot: Keyword.get(opts, :mission_control_snapshot),
      executive_dashboard_snapshot: Keyword.get(opts, :executive_dashboard_snapshot),
      ledger_snapshot: Keyword.get(opts, :ledger_snapshot),
      knowledge_graph_snapshot: Keyword.get(opts, :knowledge_graph_snapshot),
      canonical_transaction_ids: Keyword.get(opts, :canonical_transaction_ids, []),
      stage3_results_count: Keyword.get(opts, :stage3_results_count, 0),
      stage4_results_count: Keyword.get(opts, :stage4_results_count, 0),
      stage5_result_id: Keyword.get(opts, :stage5_result_id),
      constitutional_violations: Keyword.get(opts, :constitutional_violations, 0),
      lifecycle_completeness_pct: Keyword.get(opts, :lifecycle_completeness_pct, 0.0),
      rollback_frequency: Keyword.get(opts, :rollback_frequency, 0.0),
      manifest_id: Keyword.get(opts, :manifest_id),
      certificate_id: Keyword.get(opts, :certificate_id)
    }
  end

  @doc """
  Calculate Civilization Adaptation Index (composite metric).

  CAI = Observed Improvement × Prediction Reliability × Transferability Success
      × Rollback Readiness × Constitutional Compliance × Scientific Diversity

  Normalized to 0-100 scale.

  ## Parameters
  - `history`: GenerationHistory struct or map with required fields

  ## Returns
  Float between 0.0 and 100.0
  """
  def calculate_cai(history) do
    # Extract components (use defaults if missing)
    observed_improvement = normalize_metric(history.adaptation_success_rate || 0.0, 0.0, 1.0)
    prediction_reliability = normalize_metric(history.prediction_reliability || 0.5, 0.0, 1.0)
    transferability_success = normalize_metric(history.adaptation_success_rate || 0.5, 0.0, 1.0)
    rollback_readiness = 1.0 - normalize_metric(history.rollback_frequency || 0.1, 0.0, 1.0)
    constitutional_compliance = 1.0 - normalize_metric(history.constitutional_violations || 0, 0, 10) / 10.0
    scientific_diversity = normalize_metric((history.institution_diversity + history.method_diversity) / 2.0, 0.0, 1.0)

    # Calculate composite
    cai = observed_improvement * prediction_reliability * transferability_success *
          rollback_readiness * constitutional_compliance * scientific_diversity

    # Normalize to 0-100
    Float.round(cai * 100, 2)
  end

  @doc """
  Convert GenerationHistory to CSV row format.

  ## Returns
  List of values in column order
  """
  def to_csv_row(history) do
    [
      history.generation_number,
      DateTime.to_iso8601(history.timestamp),
      history.execution_duration_ms,
      history.episodes_created,
      history.discoveries_made,
      history.theories_formed,
      history.unknowns_resolved,
      history.research_debt,
      history.research_velocity,
      history.replication_success_rate || "",
      history.adaptations_evaluated,
      history.adaptations_adopted,
      history.adaptations_rejected,
      history.adaptation_success_rate,
      format_prediction_accuracy(history.prediction_accuracy),
      history.prediction_calibration || "",
      history.prediction_reliability || "",
      history.civilization_adaptation_index || "",
      history.scientific_capital,
      history.institution_diversity,
      history.method_diversity,
      history.collaboration_density,
      format_resource_utilization(history.resource_utilization),
      history.budget_remaining,
      history.credits_spent,
      history.canonical_transaction_ids |> length(),
      history.stage3_results_count,
      history.stage4_results_count,
      history.stage5_result_id || "",
      history.constitutional_violations,
      history.lifecycle_completeness_pct,
      history.rollback_frequency,
      history.manifest_id || "",
      history.certificate_id || ""
    ]
  end

  @doc """
  Get CSV header row.

  ## Returns
  List of column names
  """
  def csv_headers do
    [
      "generation_number",
      "timestamp",
      "execution_duration_ms",
      "episodes_created",
      "discoveries_made",
      "theories_formed",
      "unknowns_resolved",
      "research_debt",
      "research_velocity",
      "replication_success_rate",
      "adaptations_evaluated",
      "adaptations_adopted",
      "adaptations_rejected",
      "adaptation_success_rate",
      "prediction_accuracy",
      "prediction_calibration",
      "prediction_reliability",
      "civilization_adaptation_index",
      "scientific_capital",
      "institution_diversity",
      "method_diversity",
      "collaboration_density",
      "resource_utilization",
      "budget_remaining",
      "credits_spent",
      "canonical_transaction_count",
      "stage3_results_count",
      "stage4_results_count",
      "stage5_result_id",
      "constitutional_violations",
      "lifecycle_completeness_pct",
      "rollback_frequency",
      "manifest_id",
      "certificate_id"
    ]
  end

  @doc """
  Append GenerationHistory to CSV file (append-only, immutable).

  ## Parameters
  - `history`: GenerationHistory struct
  - `file_path`: Path to CSV file

  ## Returns
  :ok | {:error, reason}
  """
  def append_to_file(history, file_path) do
    # Ensure directory exists
    dir = Path.dirname(file_path)
    File.mkdir_p!(dir)

    # Check if file exists, write header if not
    headers = if not File.exists?(file_path) do
      [csv_headers() |> Enum.join(",")]
    else
      []
    end

    # Append row
    row = to_csv_row(history) |> Enum.join(",")
    content = (headers ++ [row]) |> Enum.join("\n")
    content = content <> "\n"

    case File.open(file_path, [:append]) do
      {:ok, file} ->
        IO.write(file, content)
        File.close(file)
        :ok
      {:error, reason} ->
        {:error, reason}
    end
  end

  # ──────────────────────────────────────────────
  # Private Helpers
  # ──────────────────────────────────────────────

  defp normalize_metric(value, min, max) do
    cond do
      value <= min -> 0.0
      value >= max -> 1.0
      true -> (value - min) / (max - min)
    end
  end

  defp format_prediction_accuracy(nil), do: ""
  defp format_prediction_accuracy(%{average_absolute_error: nil}), do: ""
  defp format_prediction_accuracy(%{average_absolute_error: err}) when is_number(err), do: Float.round(err, 4)
  defp format_prediction_accuracy(_), do: ""

  defp format_resource_utilization(map) when is_map(map) do
    map |> inspect() |> String.replace(",", ";")
  end
  defp format_resource_utilization(_), do: ""
end
