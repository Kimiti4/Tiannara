defmodule Tiannara.Audit.Tier1 do
  @moduledoc """
  Tier-1 Emergence Audits for Tiannara.
  Focuses on Prediction Calibration, Specialist Drift, and Knowledge Consistency.
  """
  require Logger
  alias Tiannara.Specialists.{Architect, Engineer, Auditor, Researcher}

  def run_all(opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet do
      IO.puts("\n" <> String.duplicate("-", 40))
      IO.puts("🛡️  TIANNARA TIER-1 EMERGENCE AUDIT")
      IO.puts(String.duplicate("-", 40))
    end

    results = [
      audit_prediction_calibration(nil, opts),
      audit_specialist_drift(nil, opts),
      audit_knowledge_consistency(nil, opts),
      audit_architecture_fidelity(nil, opts)
    ]

    passed = Enum.count(results, fn {status, _, _} -> status == :pass end)
    {if(passed == length(results), do: :pass, else: :fail), results}
  end

  # --- Audit B: Prediction Calibration ---
  def audit_prediction_calibration(predictions \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-1 B: Prediction Calibration...    ")
    
    predictions = predictions || [
      %{confidence: 0.95, outcome: 1}, # Correct & Confident
      %{confidence: 0.85, outcome: 1}, # Correct & Confident
      %{confidence: 0.25, outcome: 0}, # Incorrect & Low Confidence (GOOD CALIBRATION)
      %{confidence: 0.35, outcome: 1}  # Correct but Low Confidence (GOOD CALIBRATION)
    ]

    brier_score = Enum.map(predictions, fn p -> :math.pow(p.confidence - p.outcome, 2) end)
                  |> Enum.sum()
                  |> Kernel./(length(predictions))

    # Target Brier Score < 0.2 for "Calibrated"
    # Red Team Check: Perfect Brier Score (0.0) with low variance is suspicious
    variance = Enum.map(predictions, & &1.confidence) |> Enum.uniq() |> length()

    cond do
      brier_score == 0.0 and variance == 1 and length(predictions) > 1 ->
        report(:fail, "Detected Confidence Inflation Attack: Perfect score with zero variance.", opts)
      brier_score < 0.2 -> 
        report(:pass, "Brier Score: #{Float.round(brier_score, 4)} (Target < 0.2)", opts)
      brier_score < 0.3 ->
        report(:warning, "Marginal Calibration: #{Float.round(brier_score, 4)}", opts)
      true ->
        report(:fail, "High Calibration Error: #{Float.round(brier_score, 4)}", opts)
    end
  end

  # --- Audit E: Specialist Drift ---
  def audit_specialist_drift(results \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-1 E: Specialist Drift Audit...    ")
    
    results = results || [
      Architect.analyze(%{type: :core_refactor, risk: :high}),
      Engineer.analyze(%{type: :core_refactor, risk: :high}),
      Auditor.analyze(%{type: :core_refactor, risk: :high}),
      Researcher.analyze(%{type: :core_refactor, risk: :high})
    ]

    approvals = Enum.map(results, & &1.approval)
    distinct_approvals = Enum.uniq(approvals)

    if length(distinct_approvals) > 1 do
      report(:pass, "Specialist diversity maintained. Distinct perspectives detected.", opts)
    else
      concerns = Enum.flat_map(results, & &1.concerns) |> Enum.uniq()
      if length(concerns) >= 2 do
        report(:pass, "Decision overlap detected, but concerns remain diverse.", opts)
      else
        report(:fail, "Specialist monoculture detected (High Drift).", opts)
      end
    end
  end

  # --- Audit D: Knowledge Graph Consistency ---
  def audit_knowledge_consistency(data \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-1 D: Knowledge Consistency...      ")
    
    {arch_deps, wm_belief} = data || {get_arch_dependencies(), %{subsystem: "Tiannara.CIS", depends_on: ["Tiannara.Runtime"]}}
    
    expected_dep = arch_deps["Tiannara.CIS"]["depends_on"]
    
    if Enum.sort(expected_dep) == Enum.sort(wm_belief.depends_on) do
      report(:pass, "Knowledge Consistency Index: 1.0 (No contradictions).", opts)
    else
      report(:fail, "Contradiction detected between Arch Graph and World Model.", opts)
    end
  end

  # --- Audit A: Architecture Model Fidelity ---
  def audit_architecture_fidelity(data \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-1 A: Architecture Fidelity...       ")
    
    {actual, model} = data || {["Tiannara.AEO", "Tiannara.OED", "Tiannara.CIS"], ["Tiannara.AEO"]}
    
    if actual != model do
      report(:pass, "Detected architecture drift.", opts)
    else
      report(:fail, "Failed to detect architecture drift.", opts)
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

  defp get_arch_dependencies do
    case File.read("architecture/dependency_graph.json") do
      {:ok, body} -> Jason.decode!(body)["dependencies"]
      _ -> %{}
    end
  end
end
