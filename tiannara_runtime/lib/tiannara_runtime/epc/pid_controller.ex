defmodule Tiannara.EPC.PIDController do
  @moduledoc """
  Evolution Pressure Control: Damped PID Controller with Saturation.
  
  Computes control vectors u(t) = [u_ose, u_cis, u_grcc, u_ogc] 
  using a discrete-time PID formulation to prevent high-frequency oscillation
  and derivative explosion.
  """

  @doc """
  Computes the bounded control vector u_t for all subsystems.
  """
  def compute(s_t, prev_error, integral) do
    # Target values
    h_target = 0.8
    
    # 1. Calculate Errors (Proportional)
    e_ose  = (h_target - s_t.entropy) + s_t.novelty_flux - s_t.dominance
    e_cis  = s_t.causal_stability - sigmoid(s_t.dominance) - sigmoid(s_t.novelty_flux)
    e_grcc = s_t.entropy - s_t.dominance + s_t.observer_survival
    e_ogc  = s_t.compression_load - s_t.lineage_complexity
    
    current_error = %{ose: e_ose, cis: e_cis, grcc: e_grcc, ogc: e_ogc}
    
    # 2. Update Integrals (bounded to prevent windup)
    new_integral = %{
      ose: clamp(integral.ose + e_ose, -5.0, 5.0),
      cis: clamp(integral.cis + e_cis, -5.0, 5.0),
      grcc: clamp(integral.grcc + e_grcc, -5.0, 5.0),
      ogc: clamp(integral.ogc + e_ogc, -5.0, 5.0)
    }
    
    # 3. Calculate Derivatives (Damped)
    derivative = %{
      ose: current_error.ose - prev_error.ose,
      cis: current_error.cis - prev_error.cis,
      grcc: current_error.grcc - prev_error.grcc,
      ogc: current_error.ogc - prev_error.ogc
    }
    
    # 4. PID Output calculation (with Kp, Ki, Kd tuning)
    kp = 0.5
    ki = 0.1
    kd = 0.2
    
    raw_u = %{
      ose:  (kp * current_error.ose)  + (ki * new_integral.ose)  + (kd * derivative.ose),
      cis:  (kp * current_error.cis)  + (ki * new_integral.cis)  + (kd * derivative.cis),
      grcc: (kp * current_error.grcc) + (ki * new_integral.grcc) + (kd * derivative.grcc),
      ogc:  (kp * current_error.ogc)  + (ki * new_integral.ogc)  + (kd * derivative.ogc)
    }
    
    # 5. Saturation Layer (Hard clamp to [-1.0, 1.0])
    u_t = %{
      ose:  clamp(raw_u.ose, -1.0, 1.0),
      cis:  clamp(raw_u.cis, -1.0, 1.0),
      grcc: clamp(raw_u.grcc, -1.0, 1.0),
      ogc:  clamp(raw_u.ogc, -1.0, 1.0)
    }
    
    {u_t, current_error, new_integral}
  end
  
  # --- Helpers ---
  
  defp clamp(val, min_val, max_val), do: max(min_val, min(val, max_val))
  
  defp sigmoid(x), do: 1.0 / (1.0 + :math.exp(-x))
end
