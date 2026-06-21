defmodule Tiannara.Ocm.SemanticDriftAnalyzer do
  @moduledoc """
  Calculates semantic drift between ontology vectors.

  Drift metric:

      Do = 1 - cos(theta)

  where theta is the angle between two ontology embeddings.
  """

  @telemetry_prefix "tiannara.ocm.semantic_drift"

  @default_threshold 0.30

  @spec calculate_drift([float()], [float()]) :: {:ok, float()} | {:error, term()}
  def calculate_drift(vector_a, vector_b) when is_list(vector_a) and is_list(vector_b) do
    if length(vector_a) != length(vector_b) do
      {:error, :dimension_mismatch}
    else
      dot = dot_product(vector_a, vector_b)
      magnitude_a = magnitude(vector_a)
      magnitude_b = magnitude(vector_b)

      cond do
        magnitude_a == 0 or magnitude_b == 0 ->
          {:error, :zero_vector}

        true ->
          cosine = dot / (magnitude_a * magnitude_b)
          drift = 1 - cosine
          {:ok, drift}
      end
    end
  end

  @spec threshold_exceeded?(float(), float()) :: boolean()
  def threshold_exceeded?(drift, threshold \\ @default_threshold) do
    drift > threshold
  end

  @spec classify_drift(float(), float()) :: :aligned | :translate | :quarantine | :reconcile
  def classify_drift(drift, threshold \\ @default_threshold) do
    cond do
      drift <= threshold -> :aligned
      drift <= threshold * 2 -> :translate
      drift <= threshold * 3 -> :quarantine
      true -> :reconcile
    end
  end

  @spec emit_telemetry(map()) :: :ok
  def emit_telemetry(metadata) do
    :telemetry.execute([:tiannara, :ocm, :semantic_drift], %{}, metadata)
  end

  defp dot_product(a, b) do
    a
    |> Enum.zip(b)
    |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
  end

  defp magnitude(vector) do
    vector
    |> Enum.reduce(0.0, fn value, acc -> acc + value * value end)
    |> :math.sqrt()
  end
end