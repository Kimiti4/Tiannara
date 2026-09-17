defmodule Tiannara.EPC.ModeSelector do
  @moduledoc """
  Evolution Pressure Control: Mode Selector.
  
  Dynamically switches regimes based on the state tensor and stability risk.
  """
  
  @doc """
  Selects the appropriate EPC regulation mode.
  """
  def select_mode(s_t, stability_risk) do
    cond do
      s_t.compression_load > 0.8 ->
        :fold_mode
        
      stability_risk in [:spectral_risk, :critical_runaway] or s_t.dominance > 0.7 ->
        :containment_mode
        
      s_t.entropy < 0.3 ->
        :exploration_mode
        
      true ->
        :balance_mode
    end
  end
end
