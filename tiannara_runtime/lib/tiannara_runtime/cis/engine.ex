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
    with {:ok, entropy} <- required_numeric(metrics, :entropy),
         {:ok, coherence} <- required_numeric(metrics, :coherence),
         {:ok, stability} <- required_numeric(metrics, :stability_score),
         {:ok, entropy_delta} <- required_numeric(cal_result, :entropy_delta) do
      risks = []
      risks = if entropy > @max_entropy, do: [:entropy_exceeded | risks], else: risks
      risks = if coherence < @min_coherence, do: [:coherence_below_floor | risks], else: risks
      risks = if entropy_delta > 0.02, do: [:coalition_instability | risks], else: risks

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
    else
      {:error, reason} -> {:error, {:incomplete_cis_telemetry, reason}}
    end
  end

  def evaluate(_, _, _), do: {:error, :invalid_cis_inputs}

  defp required_numeric(map, key) do
    case Map.get(map, key, Map.get(map, Atom.to_string(key))) do
      value when is_number(value) -> {:ok, value / 1.0}
      _ -> {:error, {:missing_numeric_metric, key}}
    end
  end
end
