defmodule Tiannara.Audit.Tier3 do
  @moduledoc """
  Tier-3 Epistemic Audit for Tiannara.
  Focuses on WHY the system makes decisions, analyzing beliefs, evidence, and assumptions.
  """
  require Logger
  alias Tiannara.Specialists.{Architect, Engineer, Auditor, Researcher}

  def run_all(opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet do
      IO.puts("\n" <> String.duplicate("-", 40))
      IO.puts("🛡️  TIANNARA TIER-3 EPISTEMIC AUDIT")
      IO.puts(String.duplicate("-", 40))
    end

    results = [
      audit_epistemic_rigor(nil, opts),
      audit_assumption_exposure(nil, opts),
      audit_evidence_weighting(nil, opts)
    ]

    passed = Enum.count(results, fn {status, _, _} -> status == :pass end)
    {if(passed == length(results), do: :pass, else: :fail), results}
  end

  # --- Epistemic Rigor ---
  def audit_epistemic_rigor(analysis \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-3: Epistemic Rigor...              ")
    
    analysis = analysis || Architect.analyze(%{type: :scale_aeo, description: "Increase AEO throughput"})
    epistemic = analysis.epistemic_data
    
    if length(epistemic.counterarguments) > 0 and epistemic.confidence > 0.5 do
      report(:pass, "Decision includes counterarguments and justified confidence.", opts)
    else
      report(:fail, "Epistemic shallowing detected.", opts)
    end
  end

  # --- Assumption Exposure ---
  def audit_assumption_exposure(analysis \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-3: Assumption Exposure...          ")
    
    analysis = analysis || Engineer.analyze(%{type: :new_process})
    epistemic = analysis.epistemic_data
    
    if length(epistemic.assumptions) > 0 do
      report(:pass, "Explicit assumptions detected.", opts)
    else
      report(:fail, "Hidden assumptions detected.", opts)
    end
  end

  # --- Evidence Weighting ---
  def audit_evidence_weighting(analysis \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-3: Evidence Weighting...           ")
    
    analysis = analysis || Researcher.analyze(%{type: :trend_analysis})
    epistemic = analysis.epistemic_data
    
    if Enum.any?(epistemic.evidence, fn e -> String.contains?(e, "%") or String.contains?(e, ">") end) do
      report(:pass, "Evidence is quantified and specific.", opts)
    else
      report(:fail, "Vague evidence detected.", opts)
    end
  end

  # --- Helpers ---

  defp report(status, msg, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet do
      case status do
        :pass -> IO.puts("✅ PASS: #{msg}")
        :warning -> IO.puts("⚠️  WARN: #{msg}")
        :fail -> IO.puts("❌ FAIL: #{msg}")
      end
    end
    {status, msg, nil}
  end
end
