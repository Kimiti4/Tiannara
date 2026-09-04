defmodule Tiannara.Evolution.Trajectory do
  @moduledoc """
  Analyzes a lineage of evolutionary cycles for long-horizon health.

  Detects the failure modes of continuous optimization:
  stagnation, monoculture, regressions, epistemic drift, architectural drift,
  and governance/constitutional degradation.

  Constitutional basis: Continuous Self-Evaluation ("What scales poorly? What
  could fail under larger workloads?"), Bottleneck Discovery, "Evolution without
  validation creates randomness."
  """

  alias Tiannara.Evolution.Cycle

  @doc "Produces the full trajectory health report from a lineage."
  def analyze(lineage) when is_list(lineage) do
    accepted = Enum.filter(lineage, &(&1.decision == :accepted))

    %{
      total_cycles: length(lineage),
      accepted_cycles: length(accepted),
      capability_trend: capability_trend(accepted),
      epistemic_drift: epistemic_drift(accepted),
      architectural_drift: architectural_drift(accepted),
      constitutional_drift: constitutional_drift(accepted),
      stagnation?: stagnation?(accepted),
      monoculture?: monoculture?(lineage),
      regression_rate: regression_rate(lineage),
      certification_rate: certification_rate(lineage),
      discovery_yield: discovery_yield(accepted),
      proposal_quality: proposal_quality(lineage),
      memory_growth: memory_growth(accepted),
      lineage_integrity: lineage_integrity(lineage)
    }
    |> then(&Map.put(&1, :verdict, verdict(&1)))
  end

  # --- capability ---

  defp capability_trend([]), do: :no_data

  defp capability_trend(accepted) do
    # SR-4: filter nil values before computing first/second halves so that
    # avg/1 (which sums the list) does not encounter nil and crash with
    # `nil + 0` ArithmeticError. Mirrors the pattern already used in
    # proposal_quality/1 (line 135: |> Enum.reject(&is_nil/1)).
    scores = Enum.map(accepted, & &1.metrics_after.capability[:composite_score])
    scores = Enum.reject(scores, &is_nil/1)
    first_half = Enum.take(scores, div(length(scores), 2))
    second_half = Enum.drop(scores, div(length(scores), 2))

    cond do
      length(second_half) == 0 -> :insufficient_data
      avg(second_half) > avg(first_half) + 0.01 -> :improving
      avg(second_half) < avg(first_half) - 0.01 -> :declining
      true -> :plateaued
    end
  end

  # --- drift ---

  defp epistemic_drift([]), do: :stable

  defp epistemic_drift(accepted) do
    first = hd(accepted).metrics_before.epistemic[:contradiction_count] || 0
    last = List.last(accepted).metrics_after.epistemic[:contradiction_count] || 0

    cond do
      last > first -> :accumulating
      last < first -> :resolving
      true -> :stable
    end
  end

  defp architectural_drift([]), do: :stable

  defp architectural_drift(accepted) do
    first = hd(accepted).metrics_before.architectural[:coupling_index] || 0.0
    last = List.last(accepted).metrics_after.architectural[:coupling_index] || 0.0

    if last > first + 0.05, do: :degrading, else: :stable
  end

  defp constitutional_drift([]), do: :stable

  defp constitutional_drift(accepted) do
    # SR-4: substitute 0 for missing :invariant_violations per element so
    # that Enum.sum/1 does not encounter nil and crash with `nil + 0`
    # ArithmeticError. Mirrors the `|| 0` pattern used in epistemic_drift/1
    # and architectural_drift/1.
    violations =
      Enum.map(accepted, &(&1.metrics_after.constitutional[:invariant_violations] || 0))
      |> Enum.sum()

    if violations > 0, do: :violated, else: :stable
  end

  # --- failure modes ---

  defp stagnation?([]), do: false

  defp stagnation?(accepted) do
    recent = Enum.take(accepted, -3)

    # SR-4: substitute 0.0 for missing :composite_score on either side so
    # that the subtraction does not produce `1.0 - nil` ArithmeticError.
    # Mirrors the `|| 0.0` pattern used in architectural_drift/1 (line 75).
    gains =
      Enum.map(recent, fn c ->
        (c.metrics_after.capability[:composite_score] || 0.0) -
          (c.metrics_before.capability[:composite_score] || 0.0)
      end)

    Enum.all?(gains, &(abs(&1) < 0.01))
  end

  defp monoculture?(lineage) do
    hypothesis_ids = Enum.map(lineage, & &1.hypothesis_id) |> Enum.reject(&is_nil/1)
    unique = Enum.uniq(hypothesis_ids)
    length(hypothesis_ids) > 2 and length(unique) == 1
  end

  defp regression_rate(lineage) do
    rejected = Enum.count(lineage, &(&1.decision == :rejected))
    if length(lineage) == 0, do: 0.0, else: rejected / length(lineage)
  end

  defp certification_rate(lineage) do
    certified =
      Enum.count(lineage, fn c ->
        c.certification_result == :certified
      end)

    if length(lineage) == 0, do: 0.0, else: certified / length(lineage)
  end

  defp discovery_yield(accepted) do
    # SR-4: substitute [] for missing :evidence_ids so that length/1 does
    # not encounter nil and crash with `length(nil)` ArgumentError.
    Enum.sum(Enum.map(accepted, fn c -> length(c.evidence_ids || []) end))
  end

  defp proposal_quality(lineage) do
    scores =
      Enum.map(lineage, fn c ->
        c.metrics_after.capability[:composite_score]
      end)
      |> Enum.reject(&is_nil/1)

    if scores == [], do: 0.0, else: avg(scores)
  end

  defp memory_growth(accepted) do
    # Track memory if present in architectural metrics
    case {List.first(accepted), List.last(accepted)} do
      {nil, _} -> 0.0
      {_, nil} -> 0.0
      {first, last} ->
        b = first.metrics_before.architectural[:memory] || 0.0
        a = last.metrics_after.architectural[:memory] || 0.0
        a - b
    end
  end

  # --- lineage integrity ---

  defp lineage_integrity(lineage) do
    # Verify the parent_cycle_id chain is unbroken
    integrity =
      lineage
      |> Enum.with_index()
      |> Enum.all?(fn {cycle, idx} ->
        expected_parent = if idx == 0, do: nil, else: Enum.at(lineage, idx - 1).cycle_id
        cycle.parent_cycle_id == expected_parent
      end)

    if integrity, do: :intact, else: :broken
  end

  # --- synthesis ---

  @doc """
  Synthesizes the trajectory into an overall evolutionary health verdict.
  Governance failure is most severe, then drift, then stagnation/regression.
  """
  def verdict(t) do
    cond do
      t.constitutional_drift == :violated -> :governance_failure
      t.lineage_integrity == :broken -> :lineage_corrupted
      t.epistemic_drift == :accumulating or t.architectural_drift == :degrading -> :drifting
      t.stagnation? -> :stagnating
      t.regression_rate > 0.5 -> :degrading
      t.capability_trend == :improving and t.certification_rate > 0 -> :healthy_evolution
      true -> :plateaued
    end
  end

  defp avg([]), do: 0.0
  defp avg(list), do: Enum.sum(list) / length(list)
end