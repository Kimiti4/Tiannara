defmodule Tiannara.Bridge.CompressionToLoad do
  @moduledoc """
  Phase 5F.12: Compression → Load Emitter
  
  Emits pressure signals to OLEF based on OMCE compression activity.
  
  When OMCE compresses ontology, it generates computational load that
  must be distributed across the OLEF field to prevent node overload.
  """

  @max_load_multiplier 10.0

  @doc """
  Emit pressure signal based on compression delta.
  
  ## Parameters
  - compression_delta: Change in ontology size (positive = expansion, negative = compression)
  
  ## Returns
  {:pressure_signal, pressure} where pressure is normalized load value
  """
  def emit(compression_delta) when is_number(compression_delta) do
    pressure =
      compression_delta
      |> normalize()
      |> scale_to_load()
    
    {:pressure_signal, pressure}
  end

  @doc """
  Normalize compression delta to [0.0, 1.0] range.
  """
  defp normalize(x) do
    # Convert absolute delta to relative measure
    abs_x = abs(x)
    
    # Use sigmoid-like function for smooth normalization
    normalized = abs_x / (1.0 + abs_x)
    
    # Ensure within bounds
    min(max(normalized, 0.0), 1.0)
  end

  @doc """
  Scale normalized value to load pressure range.
  """
  defp scale_to_load(x) do
    x * @max_load_multiplier
  end

  @doc """
  Emit pressure signal with metadata for tracking.
  
  ## Parameters
  - compression_delta: Change in ontology size
  - metadata: Additional context (observer_id, timestamp, etc.)
  
  ## Returns
  Pressure signal map with full metadata
  """
  def emit_with_metadata(compression_delta, metadata \\ %{}) do
    {:pressure_signal, base_pressure} = emit(compression_delta)
    
    %{
      pressure: base_pressure,
      compression_delta: compression_delta,
      is_expansion: compression_delta > 0,
      is_compression: compression_delta < 0,
      magnitude: abs(compression_delta),
      metadata: Map.merge(%{
        timestamp: System.system_time(:millisecond),
        source: :omce_compression_event
      }, metadata)
    }
  end

  @doc """
  Calculate cumulative load from multiple compression events.
  
  ## Parameters
  - deltas: List of compression deltas
  
  ## Returns
  Total pressure signal accounting for all events
  """
  def cumulative_load(deltas) when is_list(deltas) do
    total_delta = Enum.sum(deltas)
    emit(total_delta)
  end
end
