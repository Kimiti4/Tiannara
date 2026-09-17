defmodule Tiannara.EPC.StabilityMonitor do
  @moduledoc """
  Evolution Pressure Control: Stability Monitor.
  MSCL-gated stability evaluation.
  """
  
  def check(a, s) do
    eigen_proxy = max_map_value(a)

    %{
      eigen_proxy: eigen_proxy,
      risk: eigen_proxy + s.phi + s.d
    }
  end

  defp max_map_value(map) do
    map |> Map.values() |> Enum.max()
  end
end
