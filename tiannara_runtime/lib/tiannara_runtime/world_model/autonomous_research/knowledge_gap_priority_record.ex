defmodule TiannaraRuntime.WorldModel.AutonomousResearch.KnowledgeGapPriorityRecord do
  @moduledoc """
  Phase 17.8.2 — KnowledgeGapPriorityRecord: the prioritized output artifact
  produced by the ARPEPriorityScorer for a single KnowledgeGap.

  This is an immutable, content-addressed artifact. Every field is required —
  no defaults. The score and its component breakdown are computed by the
  prioritizer and recorded here so that archaeology can reconstruct exactly
  why a gap was ranked as it was.

  Constitutional rules:
  - All field values come from the caller (the prioritizer engine).
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation.
  - The score is not validated for range — the prioritizer is responsible for
    producing valid scores. This struct records what the prioritizer computed.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "kgpr"
  @id_field :priority_record_id

  defstruct [
    :priority_record_id,
    :knowledge_gap_id,
    :epoch_id,
    :scoring_config_id,
    :composite_score,
    :score_components,
    :rank,
    :twin_provenance_hash
  ]

  @type score_components :: %{
          uncertainty: float(),
          impact: float(),
          feasibility: float(),
          civilization_relevance: float(),
          information_gain: float()
        }

  @type t :: %__MODULE__{
          priority_record_id: String.t() | nil,
          knowledge_gap_id: String.t() | nil,
          epoch_id: String.t() | nil,
          scoring_config_id: String.t() | nil,
          composite_score: float() | nil,
          score_components: score_components() | nil,
          rank: non_neg_integer() | nil,
          twin_provenance_hash: String.t() | nil
        }

  @doc """
  Constructs and validates a KnowledgeGapPriorityRecord.

  Required keys:
  - :knowledge_gap_id (String.t)
  - :epoch_id (String.t)
  - :scoring_config_id (String.t)
  - :composite_score (float)
  - :score_components (map with :uncertainty, :impact, :feasibility,
                       :civilization_relevance, :information_gain keys)
  - :rank (non_neg_integer — ordinal rank within the current epoch's priority list)
  - :twin_provenance_hash (String.t — hash of the World Model snapshot that
                           produced the source KnowledgeGap)

  The :priority_record_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    record = %__MODULE__{
      knowledge_gap_id: Keyword.get(opts, :knowledge_gap_id),
      epoch_id: Keyword.get(opts, :epoch_id),
      scoring_config_id: Keyword.get(opts, :scoring_config_id),
      composite_score: Keyword.get(opts, :composite_score),
      score_components: Keyword.get(opts, :score_components),
      rank: Keyword.get(opts, :rank),
      twin_provenance_hash: Keyword.get(opts, :twin_provenance_hash)
    }

    with :ok <- validate(record) do
      id = Canonical.generate_id(record, @id_field, @id_prefix)
      {:ok, %{record | priority_record_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = record) do
    Canonical.verify_id(record, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{knowledge_gap_id: nil}),
    do: {:error, "KnowledgeGapPriorityRecord: knowledge_gap_id is required"}

  defp validate(%__MODULE__{knowledge_gap_id: v}) when not is_binary(v) or v == "",
    do: {:error, "KnowledgeGapPriorityRecord: knowledge_gap_id must be a non-empty string"}

  defp validate(%__MODULE__{epoch_id: nil}),
    do: {:error, "KnowledgeGapPriorityRecord: epoch_id is required"}

  defp validate(%__MODULE__{epoch_id: v}) when not is_binary(v) or v == "",
    do: {:error, "KnowledgeGapPriorityRecord: epoch_id must be a non-empty string"}

  defp validate(%__MODULE__{scoring_config_id: nil}),
    do: {:error, "KnowledgeGapPriorityRecord: scoring_config_id is required"}

  defp validate(%__MODULE__{scoring_config_id: v}) when not is_binary(v) or v == "",
    do: {:error, "KnowledgeGapPriorityRecord: scoring_config_id must be a non-empty string"}

  defp validate(%__MODULE__{composite_score: nil}),
    do: {:error, "KnowledgeGapPriorityRecord: composite_score is required"}

  defp validate(%__MODULE__{composite_score: v}) when not is_float(v),
    do: {:error, "KnowledgeGapPriorityRecord: composite_score must be a float"}

  defp validate(%__MODULE__{score_components: nil}),
    do: {:error, "KnowledgeGapPriorityRecord: score_components is required"}

  defp validate(%__MODULE__{score_components: v}) when not is_map(v),
    do: {:error, "KnowledgeGapPriorityRecord: score_components must be a map"}

  defp validate(%__MODULE__{score_components: components} = r) do
    required_keys = [:uncertainty, :impact, :feasibility, :civilization_relevance, :information_gain]
    missing = Enum.reject(required_keys, &Map.has_key?(components, &1))

    if missing == [] do
      validate_remaining(r)
    else
      {:error,
       "KnowledgeGapPriorityRecord: score_components missing keys #{inspect(missing)}"}
    end
  end

  defp validate_remaining(%__MODULE__{rank: nil}),
    do: {:error, "KnowledgeGapPriorityRecord: rank is required"}

  defp validate_remaining(%__MODULE__{rank: v}) when not is_integer(v) or v < 0,
    do: {:error, "KnowledgeGapPriorityRecord: rank must be a non-negative integer"}

  defp validate_remaining(%__MODULE__{twin_provenance_hash: nil}),
    do: {:error, "KnowledgeGapPriorityRecord: twin_provenance_hash is required"}

  defp validate_remaining(%__MODULE__{twin_provenance_hash: v})
       when not is_binary(v) or v == "",
       do: {:error,
            "KnowledgeGapPriorityRecord: twin_provenance_hash must be a non-empty string"}

  defp validate_remaining(%__MODULE__{}), do: :ok
end
