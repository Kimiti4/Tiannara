defmodule TiannaraRuntime.Identity.Fingerprint do
  @moduledoc """
  PHASE 4B.2: Identity Fingerprint Generator
  
  Creates stable identity signatures for coalitions based on:
  - Centroid drift vector (spatial movement pattern)
  - Entropy signature curve (temporal entropy pattern)
  - Decision pattern embedding (CAL decision history)
  - Survival curve (longevity and resilience)
  
  These fingerprints enable recognition of recurring coalition "species".
  """
  
  require Logger
  
  @fingerprint_version "1.0"
  
  @doc """
  Generate identity fingerprint for a coalition from its history.
  
  Returns: {:ok, fingerprint_vector} or {:error, reason}
  """
  def generate(coalition_id, history, snapshots \\ []) do
    try do
      # Calculate component vectors
      centroid_drift = compute_centroid_drift(history)
      entropy_signature = compute_entropy_signature(snapshots)
      decision_pattern = compute_decision_pattern(history)
      survival_curve = compute_survival_curve(history)
      
      # Combine into fingerprint vector
      fingerprint = %{
        coalition_id: coalition_id,
        version: @fingerprint_version,
        generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        components: %{
          centroid_drift: centroid_drift,
          entropy_signature: entropy_signature,
          decision_pattern: decision_pattern,
          survival_curve: survival_curve
        },
        # Combined hash for quick comparison
        hash: generate_hash(centroid_drift, entropy_signature, decision_pattern, survival_curve)
      }
      
      Logger.debug("🧬 Generated fingerprint for #{coalition_id}")
      
      {:ok, fingerprint}
    rescue
      e ->
        Logger.error("Failed to generate fingerprint: #{inspect(e)}")
        {:error, :fingerprint_generation_failed}
    end
  end
  
  @doc """
  Calculate similarity between two fingerprints using cosine similarity.
  
  Returns: similarity score (0.0 to 1.0)
  """
  def similarity(fingerprint_a, fingerprint_b) do
    # Extract component vectors
    vec_a = to_vector(fingerprint_a)
    vec_b = to_vector(fingerprint_b)
    
    # Cosine similarity using the private function
    fingerprint_cosine_similarity(vec_a, vec_b)
  end
  
  @doc """
  Check if two coalitions are the same "species" (similarity > threshold).
  
  Default threshold: 0.85 (85% similar)
  """
  def same_species?(fingerprint_a, fingerprint_b, threshold \\ 0.85) do
    sim = similarity(fingerprint_a, fingerprint_b)
    sim >= threshold
  end
  
  # Private Implementation
  
  defp compute_centroid_drift(history) do
    # Extract position changes over time
    positions = Enum.map(history, fn event ->
      Map.get(event.metadata, :position, [0, 0, 0])
    end)
    
    if length(positions) < 2 do
      [0.0, 0.0, 0.0]  # No drift if insufficient data
    else
      # Calculate average drift vector
      first = hd(positions)
      last = List.last(positions)
      
      drift = Enum.zip([last, first])
              |> Enum.map(fn {l, f} -> l - f end)
      
      # Normalize
      magnitude = :math.sqrt(Enum.sum(Enum.map(drift, &(&1 * &1))))
      if magnitude > 0 do
        Enum.map(drift, &(&1 / magnitude))
      else
        [0.0, 0.0, 0.0]
      end
    end
  end
  
  defp compute_entropy_signature(snapshots) do
    # Extract entropy values from snapshots
    entropy_values = Enum.map(snapshots, fn snap ->
      Map.get(snap.cis_state, :entropy_level, 0.5)
    end)
    
    if Enum.empty?(entropy_values) do
      [0.5, 0.0, 0.0]  # Default signature
    else
      # Compute statistical features
      mean = Enum.sum(entropy_values) / length(entropy_values)
      variance = calculate_variance(entropy_values, mean)
      std_dev = :math.sqrt(variance)
      
      # Normalize to [0, 1] range
      [
        Float.round(mean, 3),
        Float.round(std_dev, 3),
        Float.round(variance, 3)
      ]
    end
  end
  
  defp compute_decision_pattern(history) do
    # Extract CAL decisions from history
    decisions = Enum.filter(history, fn event ->
      event.type in ["arbitration", "selection", "suppression"]
    end)
    
    if Enum.empty?(decisions) do
      [0.0, 0.0, 0.0, 0.0]
    else
      # Count decision types
      arbitration_count = Enum.count(decisions, &(&1.type == "arbitration"))
      selection_count = Enum.count(decisions, &(&1.type == "selection"))
      suppression_count = Enum.count(decisions, &(&1.type == "suppression"))
      total = length(decisions)
      
      # Normalize to proportions
      [
        Float.round(arbitration_count / total, 3),
        Float.round(selection_count / total, 3),
        Float.round(suppression_count / total, 3),
        Float.round(total / 100.0, 3)  # Frequency (normalized)
      ]
    end
  end
  
  defp compute_survival_curve(history) do
    # Calculate survival metrics
    birth_event = Enum.find(history, &(&1.type == "birth"))
    death_event = Enum.find(history, &(&1.type == "death"))
    
    lifespan_ms = case {birth_event, death_event} do
      {nil, _} -> 0
      {birth, nil} ->
        (DateTime.utc_now() |> DateTime.to_unix(:millisecond)) - birth.timestamp
      {birth, death} ->
        death.timestamp - birth.timestamp
    end
    
    # Count interventions affecting this coalition
    intervention_count = Enum.count(history, fn event ->
      event.type == "cis_intervention"
    end)
    
    # Recovery events (bounce-back after intervention)
    recovery_count = Enum.count(history, fn event ->
      event.type == "recovery"
    end)
    
    [
      Float.round(lifespan_ms / 1000.0, 3),  # Lifespan in seconds
      Float.round(intervention_count, 3),
      Float.round(recovery_count, 3),
      Float.round(recovery_count / max(intervention_count, 1), 3)  # Recovery rate
    ]
  end
  
  defp generate_hash(centroid_drift, entropy_sig, decision_pat, survival_curv) do
    # Combine all components into single hash
    combined = centroid_drift ++ entropy_sig ++ decision_pat ++ survival_curv
    
    # Simple hash (in production, use proper cryptographic hash)
    :erlang.phash2(combined) |> Integer.to_string(16)
  end
  
  defp to_vector(fingerprint) do
    # Flatten all components into single vector for similarity calculation
    components = fingerprint.components
    
    components.centroid_drift ++
    components.entropy_signature ++
    components.decision_pattern ++
    components.survival_curve
  end
  
  # Define a separate private function with a different name to avoid conflict
  defp fingerprint_cosine_similarity(vec_a, vec_b) do
    # Ensure same length
    min_len = min(length(vec_a), length(vec_b))
    a = Enum.take(vec_a, min_len)
    b = Enum.take(vec_b, min_len)
    
    # Dot product
    dot_product = Enum.sum(Enum.zip_with(a, b, fn x, y -> x * y end))
    
    # Magnitudes
    mag_a = :math.sqrt(Enum.sum(Enum.map(a, &(&1 * &1))))
    mag_b = :math.sqrt(Enum.sum(Enum.map(b, &(&1 * &1))))
    
    # Cosine similarity
    if mag_a > 0 and mag_b > 0 do
      Float.round(dot_product / (mag_a * mag_b), 4)
    else
      0.0
    end
  end

  @doc """
  Calculate cosine similarity between two vectors
  
  ## Examples
  
      iex> TiannaraRuntime.Identity.Fingerprint.cosine_similarity([1, 2, 3], [4, 5, 6])
      0.9746
      
      iex> TiannaraRuntime.Identity.Fingerprint.cosine_similarity([1, 0, 0], [0, 1, 0])
      0.0
      
      iex> TiannaraRuntime.Identity.Fingerprint.cosine_similarity([1, 1], [1, 1])
      1.0
      
      iex> TiannaraRuntime.Identity.Fingerprint.cosine_similarity([], [1, 2, 3])
      0.0
      
      iex> TiannaraRuntime.Identity.Fingerprint.cosine_similarity([1, 2, 3], [])
      0.0
  """
  def cosine_similarity(a, b) when is_list(a) and is_list(b) do
    cond do
      length(a) != length(b) ->
        0.0
      Enum.all?(a, &(&1 == 0)) or Enum.all?(b, &(&1 == 0)) ->
        0.0
      true ->
        dot = Enum.zip(a, b) 
              |> Enum.map(fn {x, y} -> x * y end) 
              |> Enum.sum()
        mag_a = :math.sqrt(Enum.map(a, &(&1 * &1)) |> Enum.sum())
        mag_b = :math.sqrt(Enum.map(b, &(&1 * &1)) |> Enum.sum())

        if mag_a == 0 or mag_b == 0 do
          0.0
        else
          Float.round(dot / (mag_a * mag_b), 4)
        end
    end
  end

  @doc """
  Normalize a vector to unit length
  
  ## Examples
  
      iex> TiannaraRuntime.Identity.Fingerprint.normalize([3, 4])
      [0.6, 0.8]
      
      iex> TiannaraRuntime.Identity.Fingerprint.normalize([0, 0])
      [0.0, 0.0]
  """
  def normalize(vector) when is_list(vector) do
    magnitude = :math.sqrt(Enum.map(vector, &(&1 * &1)) |> Enum.sum())
    
    if magnitude == 0 do
      Enum.map(vector, fn _ -> 0.0 end)
    else
      Enum.map(vector, &(&1 / magnitude))
    end
  end

  @doc """
  Calculate Euclidean distance between two vectors
  
  ## Examples
  
      iex> TiannaraRuntime.Identity.Fingerprint.euclidean_distance([1, 2], [4, 6])
      5.0
      
      iex> TiannaraRuntime.Identity.Fingerprint.euclidean_distance([0, 0], [0, 0])
      0.0
  """
  def euclidean_distance(a, b) when is_list(a) and is_list(b) do
    cond do
      length(a) != length(b) ->
        :infinity
      true ->
        Enum.zip(a, b)
        |> Enum.map(fn {x, y} -> (x - y) * (x - y) end)
        |> Enum.sum()
        |> :math.sqrt()
    end
  end

  @doc """
  Calculate Manhattan distance between two vectors
  
  ## Examples
  
      iex> TiannaraRuntime.Identity.Fingerprint.manhattan_distance([1, 2], [4, 6])
      7
      
      iex> TiannaraRuntime.Identity.Fingerprint.manhattan_distance([0, 0], [0, 0])
      0
  """
  def manhattan_distance(a, b) when is_list(a) and is_list(b) do
    cond do
      length(a) != length(b) ->
        :infinity
      true ->
        Enum.zip(a, b)
        |> Enum.map(fn {x, y} -> abs(x - y) end)
        |> Enum.sum()
    end
  end
  
  defp calculate_variance(values, mean) do
    squared_diffs = Enum.map(values, fn v ->
      diff = v - mean
      diff * diff
    end)
    
    Enum.sum(squared_diffs) / length(values)
  end
end
