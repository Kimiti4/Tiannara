defmodule Tiannara.Bridge.LoadToCompression do
  @moduledoc """
  Phase 5F.12: Load → Compression Translator
  
  Translates OLEF load pressure signals into OMCE compression directives.
  
  Thresholds:
  - Load > 0.8 → Aggressive compression (reduce ontology by 40-60%)
  - Load > 0.5 → Moderate compression (reduce ontology by 20-30%)
  - Load ≤ 0.5 → Light compression (reduce ontology by 5-10%)
  """

  @doc """
  Translate load signal to compression directive.
  
  ## Parameters
  - load_signal: Current OLEF load pressure (0.0-1.0)
  
  ## Returns
  {:compress, intensity} where intensity is :aggressive | :moderate | :light
  """
  def translate(load_signal) when is_number(load_signal) do
    cond do
      load_signal > 0.8 ->
        {:compress, :aggressive}
      
      load_signal > 0.5 ->
        {:compress, :moderate}
      
      true ->
        {:compress, :light}
    end
  end

  @doc """
  Get compression ratio for given intensity level.
  
  ## Returns
  Compression ratio (0.0-1.0) where lower means more aggressive compression
  """
  def compression_ratio(:aggressive), do: 0.4   # Keep 40% of ontology
  def compression_ratio(:moderate), do: 0.7     # Keep 70% of ontology
  def compression_ratio(:light), do: 0.9        # Keep 90% of ontology

  @doc """
  Translate load signal with additional context for adaptive compression.
  
  ## Parameters
  - load_signal: Current OLEF load pressure (0.0-1.0)
  - context: Map containing additional metrics (optional)
  
  ## Returns
  Compression directive with metadata
  """
  def translate_with_context(load_signal, context \\ %{}) do
    {intensity, base_ratio} = 
      case translate(load_signal) do
        {:compress, level} -> {level, compression_ratio(level)}
      end

    # Adjust based on context if provided
    adjusted_ratio = adjust_for_context(base_ratio, context)

    %{
      intensity: intensity,
      target_retention_ratio: adjusted_ratio,
      load_signal: load_signal,
      timestamp: System.system_time(:millisecond)
    }
  end

  defp adjust_for_context(ratio, context) do
    # If system is in degraded stability, be more conservative
    stability = Map.get(context, :stability, 1.0)
    
    if stability < 0.6 do
      # Increase retention (less aggressive compression) during instability
      ratio + (1.0 - ratio) * 0.2
    else
      ratio
    end
  end
end
