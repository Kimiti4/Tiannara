defmodule Tiannara.UCC.EmergenceScorer do
  @moduledoc """
  Calculates the comprehensive emergence metrics for a Constitution or Institution.
  """
  
  alias Tiannara.UCC.EmergenceScore

  def compute_score(fri, tps, cai, delta_fri, tau_int, c_ratio, p_ret, a_gain, i_ret) do
    # Resilience Quotient
    rq = fri * max(0.0, tps) * (1.0 / (1.0 + cai))
    
    # Exploration Efficiency
    ee = if tau_int > 0 do
      delta_fri / tau_int
    else
      0.0
    end

    %EmergenceScore{
      rq: rq,
      ee: ee,
      compression_ratio: c_ratio,
      predictive_retention: p_ret,
      adaptive_gain: a_gain,
      identity_retention: i_ret
    }
  end
end
