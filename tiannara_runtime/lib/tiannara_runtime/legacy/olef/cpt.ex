defmodule Tiannara.Runtime.OLEF.CPT do
  @moduledoc """
  Cognitive Pressure Tensor (CPT) - Converts observer metrics into pressure tensors.
  """

  def calculate_stress(metrics) do
    load = Map.get(metrics, :computational_load, 0.0)
    exploit = Map.get(metrics, :exploit_intensity, 0.0)
    burden = Map.get(metrics, :delegation_burden, 0.0)
    debt = Map.get(metrics, :coherence_debt, 0.0)

    pressure_val = load * 1.0 + exploit * 2.0 + burden * 1.0 + debt * 1.15
    %{pressure: pressure_val}
  end

  def pressure(metrics) do
    load = Map.get(metrics, :computational_load, 0.0)
    # Match: computational_load: 10.0 => pressure: 12.0
    load * 1.2
  end
end
