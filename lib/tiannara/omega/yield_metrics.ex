defmodule Tiannara.Omega.YieldMetrics do
  @moduledoc """
  Yield metrics over soak evidence, derived ONLY from the frozen soak log.

  All three metrics are LABELED PROXIES (proxy: true): they approximate
  yield from observable log signals, not from ground-truth measures. The
  formulas are explicit so the proxy nature is never hidden.

  VAY - Verifiable Agency Yield:
        observable useful work produced per agency loop.
        (recoveries + improvement_cycles + mints) / agency_loops
  EY  - Evidence Yield:
        fraction of log lines classifiable into evidence buckets.
        (total_lines - unmatched_lines) / total_lines
  RLR - Recovery-to-Loss Ratio:
        recoveries per WorkflowEngine loss.
        recoveries / workflow_crashes

  Constitutional basis: "Evidence Before Confidence", "Uncertainty should
  never be hidden" - every metric carries its formula and reports
  :not_measured instead of a number when the denominator is absent.
  """

  alias Tiannara.Omega.SoakEvidence

  @doc "Compute the three labeled-proxy yield metrics from soak evidence."
  def compute(%SoakEvidence{} = e) do
    %{vay: vay(e), ey: ey(e), rlr: rlr(e)}
  end

  def render(metrics) do
    for {name, m} <- metrics do
      value = if m.measured, do: Float.round(m.value, 4) |> to_string(), else: "not_measured"
      "#{String.upcase(to_string(name))} = #{value}  (proxy, formula: #{m.formula})"
    end
    |> Enum.join("\n")
  end

  defp vay(e) do
    work = e.recoveries + e.improvement_cycles + e.mints
    formula = "VAY = (recoveries + improvement_cycles + mints) / agency_loops"

    proxy(work, e.agency_loops, formula,
      note: if(e.agency_loops == 0, do: "no agency loops observed", else: nil)
    )
  end

  defp ey(e) do
    matched = e.total_lines - e.unmatched_lines
    formula = "EY = (total_lines - unmatched_lines) / total_lines"

    proxy(matched, e.total_lines, formula,
      note: if(e.total_lines == 0, do: "empty log", else: nil)
    )
  end

  defp rlr(e) do
    formula = "RLR = recoveries / workflow_crashes"

    proxy(e.recoveries, e.workflow_crashes, formula,
      note:
        if(e.workflow_crashes == 0,
          do: "no WorkflowEngine losses observed; ratio undefined",
          else: nil
        )
    )
  end

  defp proxy(num, den, formula, opts) do
    if is_number(num) and is_number(den) and den > 0 do
      %{value: num / den, proxy: true, formula: formula, measured: true,
        note: Keyword.get(opts, :note)}
    else
      %{value: nil, proxy: true, formula: formula, measured: false,
        note: Keyword.get(opts, :note)}
    end
  end
end