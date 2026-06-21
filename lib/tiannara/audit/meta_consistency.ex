defmodule Tiannara.Audit.MetaConsistency do
  @moduledoc """
  Stage 3: Cross-Audit Consistency.
  Checks for impossible or suspicious combinations of audit results.
  """
  require Logger

  def run_meta_audit(results_map) do
    IO.write("Tier-3 Meta: Cross-Audit Consistency... ")
    
    contradictions = check_contradictions(results_map)
    
    if length(contradictions) == 0 do
      IO.puts("✅ PASS")
      {:pass, "No cross-audit contradictions detected."}
    else
      IO.puts("❌ FAIL")
      Enum.each(contradictions, fn c -> IO.puts("   - #{c}") end)
      {:fail, contradictions}
    end
  end

  defp check_contradictions(m) do
    []
    |> check_calibration_vs_learning(m)
    |> check_fidelity_vs_consistency(m)
  end

  defp check_calibration_vs_learning(acc, m) do
    # Perfect calibration + No learning = Suspicious
    calib = get_status(m, "Tier-1 B")
    learning = get_status(m, "Tier-2 E")
    
    if calib == :pass and learning == :fail do
      acc ++ ["Contradiction: System claims perfect calibration but shows zero learning emergence."]
    else
      acc
    end
  end

  defp check_fidelity_vs_consistency(acc, m) do
    # High Fidelity + High Inconsistency = Impossible
    fidelity = get_status(m, "Tier-1 A")
    consistency = get_status(m, "Tier-1 D")
    
    if fidelity == :pass and consistency == :fail do
      acc ++ ["Contradiction: Architecture model is 'accurate' yet contradicts World Model beliefs."]
    else
      acc
    end
  end

  defp get_status(m, key) do
    case Map.get(m, key) do
      {status, _, _} -> status
      _ -> :unknown
    end
  end
end
