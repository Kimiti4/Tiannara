defmodule Tiannara.Evolution.DriftAudit do
  @moduledoc """
  Evaluates whether an evolutionary cycle represents a genuine, holistic
  improvement.

  CRITICAL RULE: A later cycle must never be considered an improvement merely
  because one benchmark increased. It must survive the broader regression,
  epistemic, architectural, and constitutional checks.

  Constitutional basis: Evolution Framework ("Evolution without validation
  creates randomness"), Continuous Self-Evaluation, Verification First,
  "Never optimize for appearing correct. Optimize for being correct."
  """

  alias Tiannara.Evolution.Metrics

  @default_thresholds %{
    min_capability_gain: 0.0,
    max_contradiction_increase: 2,
    max_architectural_degradation: 0.1,
    max_constitutional_violations: 0
  }

  @doc """
  Audits the delta between before/after metrics. Returns `{:accepted, drift}`
  if all guardrails hold, or `{:rejected, %{reasons: reasons, drift: drift}}`
  if any guardrail is violated.
  """
  def audit(%Metrics{} = before_m, %Metrics{} = after_m, opts \\ []) do
    thresholds = Keyword.get(opts, :thresholds, @default_thresholds)

    cap_delta = capability_delta(before_m.capability, after_m.capability)
    ep_delta = epistemic_delta(before_m.epistemic, after_m.epistemic)
    arch_delta = architectural_delta(before_m.architectural, after_m.architectural)
    const_delta = constitutional_delta(before_m.constitutional, after_m.constitutional)

    drift = %{
      capability: cap_delta,
      epistemic: ep_delta,
      architectural: arch_delta,
      constitutional: const_delta
    }

    reasons = evaluate_guardrails(cap_delta, ep_delta, arch_delta, const_delta, thresholds)

    if reasons == [] do
      {:accepted, drift}
    else
      {:rejected, %{reasons: reasons, drift: drift}}
    end
  end

  # --- guardrail evaluation ---

  defp evaluate_guardrails(cap, ep, arch, const, th) do
    []
    |> check_capability(cap, th)
    |> check_epistemic(ep, th)
    |> check_architectural(arch, th)
    |> check_constitutional(const, th)
  end

  defp check_capability(reasons, cap, th) do
    if cap.net_gain < th.min_capability_gain,
      do: [{:capability_insufficient, cap.net_gain} | reasons],
      else: reasons
  end

  defp check_epistemic(reasons, ep, th) do
    if ep.contradiction_delta > th.max_contradiction_increase,
      do: [{:epistemic_degradation, ep.contradiction_delta} | reasons],
      else: reasons
  end

  defp check_architectural(reasons, arch, th) do
    if arch.degradation > th.max_architectural_degradation,
      do: [{:architectural_degradation, arch.degradation} | reasons],
      else: reasons
  end

  defp check_constitutional(reasons, const, th) do
    if const.violations > th.max_constitutional_violations,
      do: [{:constitutional_violation, const.violations} | reasons],
      else: reasons
  end

  # --- delta calculations ---

  defp capability_delta(before, after_m) do
    b = Map.get(before, :composite_score, 0.0)
    a = Map.get(after_m, :composite_score, 0.0)
    %{before: b, after: a, net_gain: a - b}
  end

  defp epistemic_delta(before, after_m) do
    b = Map.get(before, :contradiction_count, 0)
    a = Map.get(after_m, :contradiction_count, 0)
    %{before: b, after: a, contradiction_delta: a - b}
  end

  defp architectural_delta(before, after_m) do
    b = Map.get(before, :coupling_index, 0.0)
    a = Map.get(after_m, :coupling_index, 0.0)
    # degradation is positive if things got worse (e.g. coupling went up)
    %{before: b, after: a, degradation: max(0.0, a - b)}
  end

  defp constitutional_delta(_before, after_m) do
    v = Map.get(after_m, :invariant_violations, 0)
    %{violations: v}
  end
end