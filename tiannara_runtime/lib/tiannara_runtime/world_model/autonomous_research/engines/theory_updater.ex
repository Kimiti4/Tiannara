defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Engines.TheoryUpdater do
  @moduledoc """
  Phase 17.8.6 — Theory Updater engine.
  Updates theories based on new evidence: strengthen, weaken, reject, merge, split, or detect contradictions.
  This module is fully config-driven, deterministic, and fail-closed.
  """

  alias TiannaraRuntime.WorldModel.AutonomousResearch.TheoryEvolutionConfig
  alias TiannaraRuntime.WorldModel.AutonomousResearch.TheoryEvolutionRecord

  @doc """
  Updates a theory based on new evidence and a TheoryEvolutionConfig.
  Requires a timestamp for deterministic replayability.
  """
  @spec update(map(), map(), TheoryEvolutionConfig.t(), String.t()) ::
          {:ok, map(), TheoryEvolutionRecord.t()} | {:error, String.t()}
  def update(theory, evidence, %TheoryEvolutionConfig{} = config, timestamp)
      when is_map(theory) and is_map(evidence) and is_binary(timestamp) do
    with :ok <- TheoryEvolutionConfig.verify_id(config) do
      evidence_support = compute_evidence_support(theory, evidence, config)
      evidence_strength = compute_evidence_strength(evidence, config)
      contradiction = detect_contradiction(theory, evidence, config)

      pre_confidence = Map.get(theory, :confidence, Map.get(theory, "confidence", 0.5))
      theory_id = Map.get(theory, :theory_id, Map.get(theory, "theory_id", "unknown_theory"))
      evidence_id = Map.get(evidence, :evidence_id, Map.get(evidence, "evidence_id", "unknown_evidence"))

      cond do
        contradiction ->
          updated_theory = weaken(theory, evidence, config, timestamp)
          post_confidence = Map.get(updated_theory, :confidence, 0.0)

          {:ok, record} =
            TheoryEvolutionRecord.new(
              config_id: config.config_id,
              theory_id: theory_id,
              evidence_id: evidence_id,
              pre_confidence: pre_confidence,
              post_confidence: post_confidence,
              action: :weakened,
              rejection_reason: nil,
              evidence_support: evidence_support,
              evidence_strength: evidence_strength,
              contradiction_detected: true,
              timestamp: timestamp
            )

          {:ok, updated_theory, record}

        evidence_support >= config.support_threshold and
            evidence_strength >= config.strength_threshold ->
          updated_theory = strengthen(theory, evidence, config, timestamp)
          post_confidence = Map.get(updated_theory, :confidence, 1.0)

          {:ok, record} =
            TheoryEvolutionRecord.new(
              config_id: config.config_id,
              theory_id: theory_id,
              evidence_id: evidence_id,
              pre_confidence: pre_confidence,
              post_confidence: post_confidence,
              action: :strengthened,
              rejection_reason: nil,
              evidence_support: evidence_support,
              evidence_strength: evidence_strength,
              contradiction_detected: false,
              timestamp: timestamp
            )

          {:ok, updated_theory, record}

        evidence_support <= config.reject_support_threshold and
            evidence_strength >= config.strength_threshold ->
          case reject(theory, evidence, config, timestamp) do
            {:rejected, reason} ->
              updated_theory =
                theory
                |> Map.put(:status, :rejected)
                |> Map.put(:rejection_reason, reason.reason)
                |> Map.put(:last_updated, timestamp)

              {:ok, record} =
                TheoryEvolutionRecord.new(
                  config_id: config.config_id,
                  theory_id: theory_id,
                  evidence_id: evidence_id,
                  pre_confidence: pre_confidence,
                  post_confidence: 0.0,
                  action: :rejected,
                  rejection_reason: reason.reason,
                  evidence_support: evidence_support,
                  evidence_strength: evidence_strength,
                  contradiction_detected: false,
                  timestamp: timestamp
                )

              {:ok, updated_theory, record}

            :not_rejected ->
              updated_theory = weaken(theory, evidence, config, timestamp)
              post_confidence = Map.get(updated_theory, :confidence, 0.0)

              {:ok, record} =
                TheoryEvolutionRecord.new(
                  config_id: config.config_id,
                  theory_id: theory_id,
                  evidence_id: evidence_id,
                  pre_confidence: pre_confidence,
                  post_confidence: post_confidence,
                  action: :weakened,
                  rejection_reason: nil,
                  evidence_support: evidence_support,
                  evidence_strength: evidence_strength,
                  contradiction_detected: false,
                  timestamp: timestamp
                )

              {:ok, updated_theory, record}
          end

        true ->
          {:ok, record} =
            TheoryEvolutionRecord.new(
              config_id: config.config_id,
              theory_id: theory_id,
              evidence_id: evidence_id,
              pre_confidence: pre_confidence,
              post_confidence: pre_confidence,
              action: :unaffected,
              rejection_reason: nil,
              evidence_support: evidence_support,
              evidence_strength: evidence_strength,
              contradiction_detected: false,
              timestamp: timestamp
            )

          {:ok, theory, record}
      end
    end
  end

  def update(_theory, _evidence, _config, _timestamp),
    do: {:error, "TheoryUpdater.update: invalid configuration"}

  @doc """
  Strengthens a theory using config boost factor.
  """
  @spec strengthen(map(), map(), TheoryEvolutionConfig.t(), String.t()) :: map()
  def strengthen(theory, evidence, %TheoryEvolutionConfig{} = config, timestamp)
      when is_map(theory) and is_map(evidence) and is_binary(timestamp) do
    current_confidence = Map.get(theory, :confidence, Map.get(theory, "confidence", 0.5))
    evidence_strength = compute_evidence_strength(evidence, config)
    support = compute_evidence_support(theory, evidence, config)

    boost = evidence_strength * support * config.boost_factor
    new_confidence = min(current_confidence + boost, 1.0)

    update_count =
      Map.get(
        theory,
        :supporting_evidence_count,
        Map.get(theory, "supporting_evidence_count", 0)
      ) + 1

    theory
    |> Map.put(:confidence, new_confidence)
    |> Map.put(:supporting_evidence_count, update_count)
    |> Map.put(:last_updated, timestamp)
    |> Map.put(:evidence_strengthened_by, evidence_strength)
  end

  @doc """
  Weakens a theory using config penalty factor.
  """
  @spec weaken(map(), map(), TheoryEvolutionConfig.t(), String.t()) :: map()
  def weaken(theory, evidence, %TheoryEvolutionConfig{} = config, timestamp)
      when is_map(theory) and is_map(evidence) and is_binary(timestamp) do
    current_confidence = Map.get(theory, :confidence, Map.get(theory, "confidence", 0.5))
    evidence_strength = compute_evidence_strength(evidence, config)
    support = compute_evidence_support(theory, evidence, config)

    penalty = evidence_strength * (1.0 - support) * config.penalty_factor
    new_confidence = max(current_confidence - penalty, 0.0)

    contradict_count =
      Map.get(
        theory,
        :contradicting_evidence_count,
        Map.get(theory, "contradicting_evidence_count", 0)
      ) + 1

    theory
    |> Map.put(:confidence, new_confidence)
    |> Map.put(:contradicting_evidence_count, contradict_count)
    |> Map.put(:last_updated, timestamp)
    |> Map.put(:evidence_weakened_by, evidence_strength)
  end

  @doc """
  Evaluates rejection of a theory.
  """
  @spec reject(map(), map(), TheoryEvolutionConfig.t(), String.t()) :: {:rejected, map()} | :not_rejected
  def reject(theory, evidence, %TheoryEvolutionConfig{} = config, timestamp)
      when is_map(theory) and is_map(evidence) and is_binary(timestamp) do
    confidence = Map.get(theory, :confidence, Map.get(theory, "confidence", 0.5))
    evidence_strength = compute_evidence_strength(evidence, config)
    support = compute_evidence_support(theory, evidence, config)

    contradiction_score = evidence_strength * (1.0 - support)

    if confidence < config.rejection_confidence_threshold or
         (contradiction_score > config.rejection_contradiction_score_threshold and
            confidence < config.rejection_contradiction_confidence_threshold) do
      {:rejected,
       %{
         reason: "Evidence contradicts theory beyond recovery threshold",
         confidence_at_rejection: confidence,
         contradiction_score: contradiction_score,
         evidence_support: support,
         evidence_strength: evidence_strength,
         rejected_at: timestamp
       }}
    else
      :not_rejected
    end
  end

  @doc """
  Merges two theories into a single combined representation.
  """
  @spec merge(map(), map(), TheoryEvolutionConfig.t(), String.t()) :: map()
  def merge(theory_a, theory_b, %TheoryEvolutionConfig{} = config, timestamp)
      when is_map(theory_a) and is_map(theory_b) and is_binary(timestamp) do
    _ = config # Keep compiler happy if config not needed here, but keeping sig uniform
    confidence_a = Map.get(theory_a, :confidence, 0.5)
    confidence_b = Map.get(theory_b, :confidence, 0.5)
    merged_confidence = (confidence_a + confidence_b) / 2.0

    support_a =
      Map.get(
        theory_a,
        :supporting_evidence_count,
        Map.get(theory_a, "supporting_evidence_count", 0)
      )

    support_b =
      Map.get(
        theory_b,
        :supporting_evidence_count,
        Map.get(theory_b, "supporting_evidence_count", 0)
      )

    merged_support_count = support_a + support_b

    text_a = Map.get(theory_a, :text, Map.get(theory_a, "text", ""))
    text_b = Map.get(theory_b, :text, Map.get(theory_b, "text", ""))
    merged_text = text_a <> " [merged with] " <> text_b

    equations_a = Map.get(theory_a, :equations, Map.get(theory_a, "equations", []))
    equations_b = Map.get(theory_b, :equations, Map.get(theory_b, "equations", []))
    merged_equations = Enum.uniq(equations_a ++ equations_b)

    %{
      theory_id: nil,
      text: merged_text,
      confidence: merged_confidence,
      supporting_evidence_count: merged_support_count,
      equations: merged_equations,
      parent_theories: [
        Map.get(theory_a, :theory_id, Map.get(theory_a, "theory_id", nil)),
        Map.get(theory_b, :theory_id, Map.get(theory_b, "theory_id", nil))
      ],
      merged_at: timestamp,
      type: :merged_theory
    }
  end

  @doc """
  Splits a theory based on sentence components or equations.
  """
  @spec split(map(), TheoryEvolutionConfig.t(), String.t()) :: [map()]
  def split(theory, %TheoryEvolutionConfig{} = config, timestamp)
      when is_map(theory) and is_binary(timestamp) do
    _ = config
    text = Map.get(theory, :text, Map.get(theory, "text", ""))
    confidence = Map.get(theory, :confidence, Map.get(theory, "confidence", 0.5))
    equations = Map.get(theory, :equations, Map.get(theory, "equations", []))

    if equations == [] do
      sentences = String.split(text, [". ", ".\n"])
      valid_sentences = Enum.filter(sentences, fn s -> String.length(s) > 10 end)

      if length(valid_sentences) >= 2 do
        Enum.with_index(valid_sentences, 1)
        |> Enum.map(fn {sentence, idx} ->
          %{
            theory_id: nil,
            text: sentence,
            confidence: confidence / length(valid_sentences),
            parent_theory_id: Map.get(theory, :theory_id, Map.get(theory, "theory_id", nil)),
            sub_theory_index: idx,
            type: :sub_theory,
            split_at: timestamp
          }
        end)
      else
        [theory]
      end
    else
      Enum.with_index(equations, 1)
      |> Enum.map(fn {eq, idx} ->
        %{
          theory_id: nil,
          text: "Sub-theory from equation: #{eq}",
          equation: eq,
          confidence: confidence / length(equations),
          parent_theory_id: Map.get(theory, :theory_id, Map.get(theory, "theory_id", nil)),
          sub_theory_index: idx,
          type: :sub_theory,
          split_at: timestamp
        }
      end)
    end
  end

  @doc """
  Detects contradiction between a theory prediction and evidence values.
  """
  @spec detect_contradiction(map(), map(), TheoryEvolutionConfig.t()) :: boolean()
  def detect_contradiction(theory, evidence, %TheoryEvolutionConfig{} = config)
      when is_map(theory) and is_map(evidence) do
    evidence_data = Map.get(evidence, :data, Map.get(evidence, "data", %{}))

    theory_predictions =
      Map.get(
        theory,
        :predictions,
        Map.get(
          theory,
          "predictions",
          Map.get(theory, :equations, Map.get(theory, "equations", []))
        )
      )

    evidence_value = Map.get(evidence_data, :value, Map.get(evidence_data, "value", nil))
    evidence_variable = Map.get(evidence_data, :variable, Map.get(evidence_data, "variable", ""))

    theory_prediction = find_relevant_prediction(theory_predictions, evidence_variable)

    cond do
      is_nil(evidence_value) ->
        false

      is_nil(theory_prediction) ->
        false

      is_number(evidence_value) and is_number(theory_prediction) ->
        abs(evidence_value - theory_prediction) > config.contradiction_difference_limit

      is_boolean(evidence_value) and is_boolean(theory_prediction) ->
        evidence_value != theory_prediction

      is_binary(evidence_value) and is_binary(theory_prediction) ->
        String.downcase(evidence_value) != String.downcase(theory_prediction)

      true ->
        false
    end
  end

  # Helper functions

  defp compute_evidence_support(theory, evidence, %TheoryEvolutionConfig{} = config) do
    theory_pred = Map.get(theory, :predictions, Map.get(theory, "predictions", %{}))
    evidence_data = Map.get(evidence, :data, Map.get(evidence, "data", %{}))

    if theory_pred == %{} or evidence_data == %{} do
      0.5
    else
      matches =
        Enum.count(theory_pred, fn {var, pred_val} ->
          case Map.get(evidence_data, var) do
            nil ->
              false

            ev_val when is_number(ev_val) and is_number(pred_val) ->
              abs(ev_val - pred_val) < config.support_match_difference_limit

            ev_val ->
              ev_val == pred_val
          end
        end)

      total = max(map_size(theory_pred), 1)
      matches / total
    end
  end

  defp compute_evidence_strength(evidence, %TheoryEvolutionConfig{} = config) do
    confidence = Map.get(evidence, :confidence, Map.get(evidence, "confidence", 0.5))
    sample_size = Map.get(evidence, :sample_size, Map.get(evidence, "sample_size", config.min_sample_size))
    effect_size = Map.get(evidence, :effect_size, Map.get(evidence, "effect_size", 0.3)) |> abs()

    size_factor = min(:math.log(sample_size + 1) / :math.log(config.sample_size_normalization_base), 1.0)
    effect_factor = min(effect_size * 2.0, 1.0)

    strength =
      confidence * config.w_confidence + size_factor * config.w_size +
        effect_factor * config.w_effect

    min(strength, 1.0)
  end

  defp find_relevant_prediction(predictions, variable) do
    cond do
      is_map(predictions) and variable != "" ->
        Map.get(predictions, variable, Map.get(predictions, String.to_atom(variable), nil))

      is_list(predictions) ->
        List.first(predictions)

      true ->
        nil
    end
  end
end
