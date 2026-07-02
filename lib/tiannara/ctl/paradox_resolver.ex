defmodule Tiannara.CTL.ParadoxResolver do
  @moduledoc """
  Triggered when causal stress exceeds thresholds or direct contradictions exist.
  """
  require Logger

  def resolve(branch_h, base_h) do
    Logger.warning("⚡ [CTL] ParadoxResolver activated.")
    Tiannara.Metrics.Aggregator.push_event([:tiannara, :ctl, :paradox_detected], 1)
    
    # Check for direct contradictions
    if has_contradiction?(branch_h, base_h) do
      Logger.error("💥 [CTL] Unresolvable Contradiction Detected (e.g. Event X vs Not X).")
      # Telemetry for the CIS Integration
      Tiannara.Metrics.Aggregator.push_event([:tiannara, :cis, :collapse_probability], 0.9)
      {:error, :unresolvable_paradox}
    else
      # Check if Multi-hop chain is broken
      if broken_chain?(branch_h) do
        {:error, :broken_causal_chain}
      else
        {:ok, :resolved}
      end
    end
  end
  
  defp has_contradiction?(h1, h2) do
    Map.get(h1, :contradicts_base, false)
  end
  
  defp broken_chain?(h) do
    Map.get(h, :broken_downstream, false)
  end
end
