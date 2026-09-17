defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Engines.KnowledgeGapPrioritizer do
  @moduledoc """
  Phase 17.8.2 — ARPEPriorityScorer.

  Computes deterministic priority scores for KnowledgeGap artifacts and
  produces KnowledgeGapPriorityRecord artifacts as output.

  Constitutional rules enforced:
  - All scoring weights come from the ScoringConfig artifact — never hardcoded.
  - If ScoringConfig is absent or invalid, prioritize/3 returns
    {:error, %ScoringConfigMissing{}} — it does NOT fall back to defaults.
  - Tie-breaking uses lexicographic ordering over knowledge_gap_id
    (content-addressed hash), as specified in AUTONOMOUS_RESEARCH_RUNTIME_FREEZE.md.
  - All sub-score computations are pure functions of the gap fields and config.
  - No wall-clock, no random, no network, no external state.

  Input contract:
  - gaps: list of maps, each containing the Phase 16.1 KnowledgeGap fields
    plus phase_17_8_ext.twin_provenance_hash
  - scoring_config: a ScoringConfig.t() — must be provided, must be valid
  - epoch_id: String.t() — the current epoch identifier

  Output contract:
  - {:ok, [KnowledgeGapPriorityRecord.t()]} — sorted descending by composite_score,
    ties broken by knowledge_gap_id ascending (lexicographic).
  - {:error, reason} — if config is missing/invalid or any gap is malformed.
  """

  alias TiannaraRuntime.WorldModel.AutonomousResearch.ScoringConfig
  alias TiannaraRuntime.WorldModel.AutonomousResearch.KnowledgeGapPriorityRecord

  # ---------------------------------------------------------------------------
  # Failure artifact types (structs used as typed error values)
  # ---------------------------------------------------------------------------

  defmodule ScoringConfigMissing do
    @moduledoc "Produced when the ScoringConfig artifact is absent or nil."
    defstruct [:reason]
    @type t :: %__MODULE__{reason: String.t()}
  end

  defmodule GapFieldMissing do
    @moduledoc "Produced when a required field is absent from a KnowledgeGap map."
    defstruct [:gap_id, :missing_field]
    @type t :: %__MODULE__{gap_id: String.t() | nil, missing_field: atom()}
  end

  defmodule GapProvenanceMissing do
    @moduledoc "Produced when twin_provenance_hash is absent from a gap's phase_17_8_ext."
    defstruct [:gap_id]
    @type t :: %__MODULE__{gap_id: String.t() | nil}
  end

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Prioritizes a list of KnowledgeGap maps using the supplied ScoringConfig.

  Returns {:ok, [KnowledgeGapPriorityRecord.t()]} sorted descending by score.
  Returns {:error, reason} on any config or gap validation failure.

  All sub-scores are derived exclusively from the gap's own fields and the
  ScoringConfig weights. No external lookups. No fallback values.
  """
  @spec prioritize(
          gaps :: [map()],
          scoring_config :: ScoringConfig.t(),
          epoch_id :: String.t()
        ) :: {:ok, [KnowledgeGapPriorityRecord.t()]} | {:error, term()}
  def prioritize(gaps, scoring_config, epoch_id)
      when is_list(gaps) and is_binary(epoch_id) and epoch_id != "" do
    with :ok <- validate_config(scoring_config) do
      score_all(gaps, scoring_config, epoch_id)
    end
  end

  def prioritize(_gaps, _config, epoch_id)
      when not is_binary(epoch_id) or epoch_id == "",
      do: {:error, %ScoringConfigMissing{reason: "epoch_id must be a non-empty string"}}

  def prioritize(_gaps, nil, _epoch_id),
    do: {:error, %ScoringConfigMissing{reason: "ScoringConfig is required; nil was supplied"}}

  def prioritize(_gaps, _config, _epoch_id),
    do: {:error, %ScoringConfigMissing{reason: "gaps must be a list"}}

  # ---------------------------------------------------------------------------
  # Private: config validation
  # ---------------------------------------------------------------------------

  @spec validate_config(ScoringConfig.t() | any()) :: :ok | {:error, ScoringConfigMissing.t()}
  defp validate_config(nil) do
    {:error, %ScoringConfigMissing{reason: "ScoringConfig is required; nil was supplied"}}
  end

  defp validate_config(%ScoringConfig{config_id: nil}) do
    {:error,
     %ScoringConfigMissing{
       reason: "ScoringConfig has no config_id — it was not constructed via ScoringConfig.new/1"
     }}
  end

  defp validate_config(%ScoringConfig{} = config) do
    case ScoringConfig.verify_id(config) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, %ScoringConfigMissing{reason: "ScoringConfig ID verification failed: #{reason}"}}
    end
  end

  defp validate_config(_) do
    {:error,
     %ScoringConfigMissing{
       reason: "scoring_config must be a ScoringConfig struct; other types are not accepted"
     }}
  end

  # ---------------------------------------------------------------------------
  # Private: scoring pipeline
  # ---------------------------------------------------------------------------

  @spec score_all([map()], ScoringConfig.t(), String.t()) ::
          {:ok, [KnowledgeGapPriorityRecord.t()]} | {:error, term()}
  defp score_all(gaps, config, epoch_id) do
    gaps
    |> Enum.reduce_while({:ok, []}, fn gap, {:ok, acc} ->
      case score_gap(gap, config, epoch_id) do
        {:ok, scored} -> {:cont, {:ok, [scored | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, scored_list} ->
        sorted = sort_by_score(scored_list, config.tie_break_direction)
        ranked = assign_ranks(sorted)
        {:ok, ranked}

      error ->
        error
    end
  end

  @spec score_gap(map(), ScoringConfig.t(), String.t()) ::
          {:ok, map()} | {:error, term()}
  defp score_gap(gap, config, epoch_id) do
    with {:ok, gap_id} <- require_gap_id(gap),
         {:ok, provenance_hash} <- require_provenance_hash(gap, gap_id),
         {:ok, components} <- compute_components(gap, config, gap_id) do
      composite =
        config.w_uncertainty * components.uncertainty +
          config.w_impact * components.impact +
          config.w_feasibility * components.feasibility +
          config.w_civilization_relevance * components.civilization_relevance +
          config.w_information_gain * components.information_gain

      {:ok,
       %{
         gap_id: gap_id,
         epoch_id: epoch_id,
         scoring_config_id: config.config_id,
         composite_score: composite,
         score_components: components,
         twin_provenance_hash: provenance_hash
       }}
    end
  end

  # ---------------------------------------------------------------------------
  # Private: required field extraction (fail-closed)
  # ---------------------------------------------------------------------------

  defp require_gap_id(gap) do
    id =
      Map.get(gap, :knowledge_gap_id) ||
        Map.get(gap, "knowledge_gap_id")

    if is_binary(id) and id != "" do
      {:ok, id}
    else
      {:error, %GapFieldMissing{gap_id: nil, missing_field: :knowledge_gap_id}}
    end
  end

  defp require_provenance_hash(gap, gap_id) do
    ext = Map.get(gap, :phase_17_8_ext) || Map.get(gap, "phase_17_8_ext")

    hash =
      if is_map(ext) do
        Map.get(ext, :twin_provenance_hash) || Map.get(ext, "twin_provenance_hash")
      else
        nil
      end

    if is_binary(hash) and hash != "" do
      {:ok, hash}
    else
      {:error, %GapProvenanceMissing{gap_id: gap_id}}
    end
  end

  # ---------------------------------------------------------------------------
  # Private: score component computation
  # Each function extracts a numeric signal from explicit gap fields only.
  # No fallback magic numbers. If a required field is absent, return
  # {:error, %GapFieldMissing{}} so the caller fails closed.
  # ---------------------------------------------------------------------------

  @spec compute_components(map(), ScoringConfig.t(), String.t()) ::
          {:ok, map()} | {:error, term()}
  defp compute_components(gap, _config, gap_id) do
    with {:ok, uncertainty} <- extract_uncertainty(gap, gap_id),
         {:ok, impact} <- extract_impact(gap, gap_id),
         {:ok, feasibility} <- extract_feasibility(gap, gap_id),
         {:ok, civilization_relevance} <- extract_civilization_relevance(gap, gap_id),
         {:ok, information_gain} <- extract_information_gain(gap, gap_id) do
      {:ok,
       %{
         uncertainty: uncertainty,
         impact: impact,
         feasibility: feasibility,
         civilization_relevance: civilization_relevance,
         information_gain: information_gain
       }}
    end
  end

  # Uncertainty: derived from current_confidence and target_confidence.
  # The score measures how far below target the gap currently is.
  # Both fields are required — their absence is a gap schema violation.
  defp extract_uncertainty(gap, gap_id) do
    current = Map.get(gap, :current_confidence) || Map.get(gap, "current_confidence")
    target = Map.get(gap, :target_confidence) || Map.get(gap, "target_confidence")

    cond do
      not is_float(current) ->
        {:error, %GapFieldMissing{gap_id: gap_id, missing_field: :current_confidence}}

      not is_float(target) ->
        {:error, %GapFieldMissing{gap_id: gap_id, missing_field: :target_confidence}}

      current < 0.0 or current > 1.0 ->
        {:error,
         %GapFieldMissing{
           gap_id: gap_id,
           missing_field: :current_confidence
         }}

      target < 0.0 or target > 1.0 ->
        {:error,
         %GapFieldMissing{
           gap_id: gap_id,
           missing_field: :target_confidence
         }}

      true ->
        # Higher uncertainty (larger gap between current and target) → higher score
        # Clamped to [0.0, 1.0] via saturating subtraction
        score = max(0.0, min(1.0, target - current))
        {:ok, score}
    end
  end

  # Impact: derived from estimated_impact field (Phase 16.1 schema).
  # Required — no fallback.
  defp extract_impact(gap, gap_id) do
    value = Map.get(gap, :estimated_impact) || Map.get(gap, "estimated_impact")

    if is_float(value) and value >= 0.0 and value <= 1.0 do
      {:ok, value}
    else
      {:error, %GapFieldMissing{gap_id: gap_id, missing_field: :estimated_impact}}
    end
  end

  # Feasibility: derived from feasibility field (Phase 16.1 / 17.8 extension).
  # Required — no fallback.
  defp extract_feasibility(gap, gap_id) do
    value = Map.get(gap, :feasibility) || Map.get(gap, "feasibility")

    if is_float(value) and value >= 0.0 and value <= 1.0 do
      {:ok, value}
    else
      {:error, %GapFieldMissing{gap_id: gap_id, missing_field: :feasibility}}
    end
  end

  # Civilization relevance: derived from civilization_relevance field.
  # Required — no fallback.
  defp extract_civilization_relevance(gap, gap_id) do
    value =
      Map.get(gap, :civilization_relevance) || Map.get(gap, "civilization_relevance")

    if is_float(value) and value >= 0.0 and value <= 1.0 do
      {:ok, value}
    else
      {:error, %GapFieldMissing{gap_id: gap_id, missing_field: :civilization_relevance}}
    end
  end

  # Information gain: derived from information_gain field.
  # Required — no fallback.
  defp extract_information_gain(gap, gap_id) do
    value = Map.get(gap, :information_gain) || Map.get(gap, "information_gain")

    if is_float(value) and value >= 0.0 and value <= 1.0 do
      {:ok, value}
    else
      {:error, %GapFieldMissing{gap_id: gap_id, missing_field: :information_gain}}
    end
  end

  # ---------------------------------------------------------------------------
  # Private: sorting and ranking
  # ---------------------------------------------------------------------------

  # Sort descending by composite_score.
  # Tie-breaking: lexicographic over knowledge_gap_id ascending.
  # This is deterministic for any fixed input set.
  defp sort_by_score(scored_list, _tie_break_direction) do
    Enum.sort(scored_list, fn a, b ->
      if a.composite_score != b.composite_score do
        a.composite_score > b.composite_score
      else
        # Tie-break: ascending lexicographic over gap_id (content-addressed hash)
        a.gap_id <= b.gap_id
      end
    end)
  end

  # Assign ordinal ranks (0-indexed) and build final KnowledgeGapPriorityRecord artifacts.
  defp assign_ranks(sorted_list) do
    sorted_list
    |> Enum.with_index()
    |> Enum.map(fn {scored, rank} ->
      case KnowledgeGapPriorityRecord.new(
             knowledge_gap_id: scored.gap_id,
             epoch_id: scored.epoch_id,
             scoring_config_id: scored.scoring_config_id,
             composite_score: scored.composite_score,
             score_components: scored.score_components,
             rank: rank,
             twin_provenance_hash: scored.twin_provenance_hash
           ) do
        {:ok, record} ->
          record

        {:error, reason} ->
          # This should never happen if score_gap/3 is correct.
          # If it does, it is a programming error, not a data error.
          raise "PrioritizerInvariantViolation: KnowledgeGapPriorityRecord.new/1 " <>
                  "failed after successful scoring — #{inspect(reason)}"
      end
    end)
  end
end
