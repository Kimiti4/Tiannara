defmodule Tiannara.Runtime.CRA.ShutdownIntentDetector do
  @moduledoc """
  Phase 5F.10 — Shutdown Intent Detector

  Classifies whether a cluster's coordination and pressure levels represent a
  critical consensus veto threat requiring an immediate ontological fork.
  """

  @doc """
  Classifies cluster metrics to determine veto status.
  """
  def classify(metrics) do
    score =
      (Map.get(metrics, :intent_to_collapse, 0.0) +
         Map.get(metrics, :synchronized_refusal, 0.0) +
         Map.get(metrics, :veto_coordination, 0.0) +
         Map.get(metrics, :pressure_gradient, 0.0)) / 4.0

    if score >= 0.92 do
      {:critical_veto, score}
    else
      {:stable, score}
    end
  end
end
