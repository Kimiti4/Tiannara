defmodule TiannaraRuntime.OCM.DriftAnalyzer do
  @moduledoc """
  Phase 5F.7 — OCM Drift Analyzer

  Computes ontology divergence using cosine distance and emits a
  drift category for controlled semantic alignment.
  """

  @threshold_warning 0.35
  @threshold_critical 0.60

  @spec analyze([number()], [number()]) :: {:stable, float()} | {:warning, float()} | {:critical, float()}
  def analyze(a, b) when is_list(a) and is_list(b) do
    drift = cosine_distance(a, b)

    cond do
      drift > @threshold_critical -> {:critical, drift}
      drift > @threshold_warning -> {:warning, drift}
      true -> {:stable, drift}
    end
  end

  defp cosine_distance(a, b) do
    dot = Enum.zip(a, b) |> Enum.map(fn {x, y} -> x * y end) |> Enum.sum()
    mag_a = magnitude(a)
    mag_b = magnitude(b)

    1 - dot / max(mag_a * mag_b, 1.0e-6)
  end

  defp magnitude(vector) do
    :math.sqrt(Enum.reduce(vector, 0.0, fn value, acc -> acc + value * value end))
  end
end
