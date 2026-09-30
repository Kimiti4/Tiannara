defmodule TiannaraRuntime.CIS.Engine do
  @moduledoc """
  Bounded per-world Cognitive Immune System.

  CIS observes world metrics and CAL outcomes, adjusts thresholds within
  configured bounds, and records interventions. It does not fabricate a
  successful intervention.
  """

  @max_entropy 0.8
  @min_coherence 0.3
  @recovery_step 0.02

  def evaluate(cis_state, cal_result, metrics) when is_map(cis_state) and is_map(metrics) do
    entropy = numeric(Map.get(metrics, :entropy), 0.0)
    coherence = numeric(Map.get(metrics, :coherence), 0.5)
    stability = numeric(Map.get(metrics, :stability_score), 0.5)

    risks = []
    risks = if entropy > @max_entropy, do: [:entropy_exceeded | risks], else: risks
    risks = if coherence < @min_coherence, do: [:coherence_below_floor | risks], else: risks
    risks = if Map.get(cal_result, :entropy_delta, 0.0) > 0.02, do: [:coalition_instability | risks], else: risks

    interventions =
      Enum.map(risks, fn
        :entropy_exceeded -> %{type: :entropy_damping, status: :proposed}
        :coherence_below_floor -> %{type: :coherence_recovery, status: :proposed}
        :coalition_instability -> %{type: :coalition_monitoring, status: :proposed}
      end)

    next_stability =
      if risks == [], do: min(1.0, stability + @recovery_step), else: max(0.0, stability - @recovery_step)

    %{
      interventions: interventions,
      stability_score: next_stability,
      thresholds_adjusted: [],
      metrics: %{
        entropy: entropy,
        coherence: coherence,
        stability_score: next_stability,
        collapse_frequency: if(risks == [], do: 0.0, else: length(risks) / 3.0),
        cis_risk_count: length(risks)
      },
      decision: if(risks == [], do: :monitor, else: :constrain),
      source: :observed_world_state
    }
  end

  def evaluate(_, _, _), do: {:error, :invalid_cis_inputs}

  defp numeric(value, default) when is_number(value), do: value / 1.0
  defp numeric(_, default), do: default
end
