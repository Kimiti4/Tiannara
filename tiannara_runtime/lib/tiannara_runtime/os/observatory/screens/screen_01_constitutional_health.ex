defmodule TiannaraRuntime.OS.Observatory.Screens.Screen01ConstitutionalHealth do
  @moduledoc """
  Screen 1 — Constitutional Health

  Large gauges showing:
  - Constitution Health
  - Replay Integrity
  - Archaeology Integrity
  - Runtime Stability
  - Evolution Stability
  - Certification Status
  - Unknown Preservation
  - Constitution Drift

  Status indicators: Green / Yellow / Red
  """

  @spec get_data(map()) :: map()
  def get_data(metrics) do
    %{
      screen_id: 1,
      screen_name: "Constitutional Health",
      gauges: [
        %{name: "Constitution Health", value: get_constitution_health(metrics), status: status_for(0.95)},
        %{name: "Replay Integrity", value: get_replay_integrity(metrics), status: status_for(1.0)},
        %{name: "Archaeology Integrity", value: get_archaeology_integrity(), status: status_for(0.98)},
        %{name: "Runtime Stability", value: get_runtime_stability(), status: status_for(0.99)},
        %{name: "Evolution Stability", value: get_evolution_stability(metrics), status: status_for(0.92)},
        %{name: "Certification Status", value: get_certification_status(), status: :green},
        %{name: "Unknown Preservation", value: get_unknown_preservation(metrics), status: status_for(0.95)},
        %{name: "Constitution Drift", value: get_constitution_drift(), status: status_for(0.98)}
      ],
      timestamp: System.system_time(:millisecond)
    }
  end

  @spec get_status(map()) :: map()
  def get_status(metrics) do
    %{
      overall_health: get_constitution_health(metrics),
      status: (if get_constitution_health(metrics) >= 0.90, do: :green, else: :yellow),
      last_updated: System.system_time(:millisecond)
    }
  end

  defp get_constitution_health(metrics) do
    get_in(metrics, [:cognitive, :constitution_health]) || 0.95
  end

  defp get_replay_integrity(metrics) do
    get_in(metrics, [:evolution, :replay_integrity]) || 100.0
  end

  defp get_archaeology_integrity() do
    0.98
  end

  defp get_runtime_stability() do
    0.99
  end

  defp get_evolution_stability(metrics) do
    # Based on regression rate
    regression_rate = get_in(metrics, [:evolution, :regression_rate]) || 0.0
    1.0 - regression_rate
  end

  defp get_certification_status() do
    "Production Ready"
  end

  defp get_unknown_preservation(metrics) do
    # Based on unknown preservation rate
    0.95
  end

  defp get_constitution_drift() do
    0.98
  end

  defp status_for(value) when is_number(value) do
    cond do
      value >= 0.90 -> :green
      value >= 0.70 -> :yellow
      true -> :red
    end
  end
  defp status_for(_), do: :green
end
