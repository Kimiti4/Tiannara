defmodule Tiannara.TWP.ObserverBiasAnalyzer do
  @moduledoc """
  Evaluates Pt ∝ O × E to prevent popular but incorrect branches from dominating.
  """

  def check_bias(branch_state) do
    popularity = Map.get(branch_state, :observer_density, 0)
    evidence = Map.get(branch_state, :evidence_strength, 1.0)
    
    # If it's unpopular but has strong evidence, protect it
    if popularity < 0.2 and evidence > 0.8 do
      {:error, :bias_detected}
    else
      {:ok, :unbiased}
    end
  end
end
