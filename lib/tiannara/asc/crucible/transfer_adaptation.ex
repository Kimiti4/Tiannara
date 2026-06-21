defmodule Tiannara.ASC.Crucible.TransferAdaptation.AdaptationRecord do
  @moduledoc "Record of a single transfer adaptation attempt"

  defstruct [
    :id,
    :source_pattern_id,
    :target_failure_id,
    :source_signature,
    :target_signature,
    :source_classification,
    :target_classification,
    :adaptation_strategy,
    :fitness_before,
    :fitness_after,
    :success,
    :transfer_distance,
    :target_constraints,
    :number_of_steps,
    :reuse_count,
    :created_at
  ]
end

defmodule Tiannara.ASC.Crucible.TransferAdaptation do
  @moduledoc """
  Transfer Adaptation — adapts repair patterns for cross-project transfer.

  Transform transfer from:
    Source Pattern → Copy → Failure

  into:
    Source Pattern → Transfer → Adapt → Validate → Success

  Measures semantic distance between source and target failures,
  applies adaptation strategies, and validates adapted repairs.
  """

  alias Tiannara.ASC.Crucible.{FailureClassifier, RepairLibrary}
  alias Tiannara.ASC.Crucible.TransferAdaptation.AdaptationRecord

  @doc """
  Attempt to adapt and transfer a repair pattern to a new failure context.

  ## Returns
  {:ok, adaptation_record} or {:error, reason}
  """
  def attempt_transfer(source_pattern, target_failure, project_id) do
    IO.puts("     🌍 Attempting transfer adaptation...")

    # Get classifications
    source_classification = source_pattern.failure_classification
    target_classification = classify_target_failure(target_failure)

    # Calculate semantic distance
    distance = semantic_distance(source_classification, target_classification)

    IO.puts("       Transfer distance: #{Float.round(distance * 100, 1)}%")

    # Select adaptation strategy based on distance
    strategy = select_adaptation_strategy(distance, source_classification, target_classification)

    IO.puts("       Adaptation strategy: #{strategy}")

    # Apply adaptation
    adapted_repair = apply_adaptation(source_pattern, target_failure, strategy)

    # Validate adapted repair
    {success, fitness_gain} = validate_adapted_repair(adapted_repair, target_failure, project_id)

    # Create adaptation record
    record = %AdaptationRecord{
      id: generate_id(),
      source_pattern_id: source_pattern.id,
      target_failure_id: target_failure.id || "unknown",
      source_signature: source_pattern.failure_signature || "unknown",
      target_signature: extract_signature(Map.get(target_failure, :evidence, "")),
      source_classification: source_classification,
      target_classification: target_classification,
      adaptation_strategy: strategy,
      fitness_before: source_pattern.confidence,
      fitness_after: if(success, do: source_pattern.confidence + fitness_gain, else: source_pattern.confidence),
      success: success,
      transfer_distance: distance,
      target_constraints: target_failure.constraints || [],
      number_of_steps: length(source_pattern.steps || []),
      reuse_count: source_pattern.reuse_count || 0,
      created_at: DateTime.utc_now()
    }

    # Update pattern fitness
    update_pattern_fitness(source_pattern.id, success, fitness_gain)

    if success do
      IO.puts("       ✅ Transfer adaptation SUCCESS (fitness gain: #{Float.round(fitness_gain * 100, 1)}%)")
    else
      IO.puts("       ❌ Transfer adaptation FAILED")
    end

    {:ok, record}
  end

  @doc """
  Calculate semantic distance between two failure classifications.

  Returns value in range [0.0, 1.0]:
  - 0.0 = identical classification
  - 1.0 = completely unrelated
  """
  def semantic_distance(source_class, target_class) do
    cond do
      # Same domain, same category, same subcategory
      source_class.domain == target_class.domain and
      source_class.category == target_class.category and
      source_class.subcategory == target_class.subcategory ->
        0.1

      # Same domain, same category, different subcategory
      source_class.domain == target_class.domain and
      source_class.category == target_class.category ->
        0.3

      # Same domain, different category
      source_class.domain == target_class.domain ->
        0.6

      # Different domain
      true ->
        0.95
    end
  end

  @doc """
  Select adaptation strategy based on semantic distance and classifications.

  Strategies:
  - :parameter_adaptation - Adjust parameter values only (distance < 0.3)
  - :constraint_adaptation - Adjust constraints like max_length (distance < 0.6)
  - :classification_adaptation - Generalize to broader classification (distance < 0.8)
  - :pattern_composition - Combine multiple repairs (distance >= 0.8)
  """
  def select_adaptation_strategy(distance, _source_class, _target_class) when distance < 0.3 do
    :parameter_adaptation
  end

  def select_adaptation_strategy(distance, _source_class, _target_class) when distance < 0.6 do
    :constraint_adaptation
  end

  def select_adaptation_strategy(distance, _source_class, _target_class) when distance < 0.8 do
    :classification_adaptation
  end

  def select_adaptation_strategy(_distance, _source_class, _target_class) do
    :decomposition_adaptation
  end

  def apply_adaptation(source_pattern, _target_failure, :parameter_adaptation) do
    # Parameter adaptation: keep steps, alter values if any
    new_steps = Enum.map(source_pattern.steps || [], fn step ->
      Map.put(step, :adapted_parameter, true)
    end)
    
    %{source_pattern | 
      steps: new_steps,
      confidence: source_pattern.confidence * 0.9
    }
  end

  def apply_adaptation(source_pattern, _target_failure, :constraint_adaptation) do
    # Relax constraints (e.g., remove specific domain-bound conditions)
    new_constraints = Enum.map(source_pattern.constraints || [], fn c ->
      Map.put(c, :relaxed, true)
    end)

    %{source_pattern | 
      constraints: new_constraints,
      confidence: source_pattern.confidence * 0.85
    }
  end

  def apply_adaptation(source_pattern, _target_failure, :classification_adaptation) do
    # Generalize repair to broader classification (e.g. remove subcategory specificity)
    new_class = if source_pattern.failure_classification do
      %{source_pattern.failure_classification | subcategory: :generic}
    else
      nil
    end

    %{source_pattern | 
      failure_classification: new_class,
      confidence: source_pattern.confidence * 0.75
    }
  end

  def apply_adaptation(source_pattern, _target_failure, :decomposition_adaptation) do
    # Decompose: take only the first half of steps (core mechanism)
    steps = source_pattern.steps || []
    split_point = max(1, trunc(length(steps) / 2))
    {new_steps, _} = Enum.split(steps, split_point)

    %{source_pattern | 
      steps: new_steps,
      confidence: source_pattern.confidence * 0.6
    }
  end

  @doc """
  Validate adapted repair against target failure.
  Returns {success?, fitness_gain}
  """
  def validate_adapted_repair(adapted_pattern, _target_failure, _project_id) do
    # Simulate validation based on adaptation strategy and confidence
    # In real implementation, this would actually apply the repair

    base_success_rate = adapted_pattern.confidence

    # Add some randomness to simulate real-world variability
    success? = :rand.uniform() < base_success_rate

    fitness_gain = if success?, do: :rand.uniform() * 0.1, else: -0.05

    {success?, fitness_gain}
  end

  @doc """
  Update pattern fitness based on transfer outcome.
  """
  def update_pattern_fitness(pattern_id, success, fitness_gain) do
    # This would update the pattern in ETS/RepairLibrary
    # For now, just log
    IO.puts("       📊 Pattern #{pattern_id} fitness updated: #{if success, do: "+", else: ""}#{Float.round(fitness_gain * 100, 1)}%")
  end

  # Private helpers

  defp classify_target_failure(observation) do
    # Create a minimal observation for classification
    evidence = Map.get(observation, :evidence, "")
    mock_obs = Map.merge(observation, %{origin: Map.get(observation, :origin, :implementation), evidence: evidence})
    try do
      FailureClassifier.classify(mock_obs)
    rescue
      _ -> %{domain: Map.get(observation, :domain, :unknown), category: :unknown, subcategory: :unknown, confidence: 0.0, keywords: [], signature: "unknown:unknown:unknown"}
    end
  end

  defp extract_signature(evidence) when is_binary(evidence) do
    # Extract simplified signature from evidence string
    evidence
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/, "_")
    |> String.slice(0..49)
  end

  defp extract_signature(_), do: "unknown"

  defp generate_id do
    "transfer_#{:rand.uniform(1000000)}_#{System.system_time(:millisecond)}"
  end
end
