defmodule TiannaraRuntime.OS.Resurrection.ResurrectionObservatory do
  @moduledoc """
  Resurrection Observatory

  Reports interruption metrics and long-horizon health metrics.

  Panel:
  - Runtime Availability
  - Unexpected Shutdowns
  - Recovered Automatically
  - Recovery Success
  - Lost Experiments
  - Replay Divergence

  Also tracks long-horizon metrics separately for active runtime vs wall-clock time.
  """

  @type observatory_panel :: %{
    runtime_availability: float(),
    unexpected_shutdowns: integer(),
    recovered_automatically: integer(),
    recovery_success_rate: float(),
    lost_experiments: integer(),
    replay_divergence: integer()
  }

  @type long_horizon_metric :: %{
    metric_name: String.t(),
    active_runtime_value: String.t(),
    wall_clock_value: String.t()
  }

  @doc """
  Returns the current observatory panel.
  """
  @spec get_panel() :: observatory_panel()
  def get_panel do
    stats = TiannaraRuntime.OS.Resurrection.RuntimeResurrectionEngine.get_observatory_metrics()
    %{
      runtime_availability: stats.runtime_availability,
      unexpected_shutdowns: stats.unexpected_shutdowns,
      recovered_automatically: stats.recovered_automatically,
      recovery_success_rate: stats.recovery_success_rate,
      lost_experiments: stats.lost_experiments,
      replay_divergence: stats.replay_divergence
    }
  end

  @doc """
  Returns long-horizon metrics separated by active runtime and wall-clock time.
  """
  @spec get_long_horizon_metrics() :: [long_horizon_metric()]
  def get_long_horizon_metrics do
    metrics = TiannaraRuntime.OS.Resurrection.RuntimeResurrectionEngine.get_long_horizon_metrics()

    [
      %{
        metric_name: "Knowledge Growth",
        active_runtime_value: metrics.knowledge_growth.active_runtime,
        wall_clock_value: metrics.knowledge_growth.wall_clock
      },
      %{
        metric_name: "Discoveries",
        active_runtime_value: Integer.to_string(metrics.discoveries.active_runtime),
        wall_clock_value: Integer.to_string(metrics.discoveries.wall_clock)
      },
      %{
        metric_name: "Recovery Events",
        active_runtime_value: Integer.to_string(metrics.recovery_events.active_runtime),
        wall_clock_value: Integer.to_string(metrics.recovery_events.wall_clock)
      },
      %{
        metric_name: "Replay Integrity",
        active_runtime_value: metrics.replay_integrity.active_runtime,
        wall_clock_value: metrics.replay_integrity.wall_clock
      }
    ]
  end

  @doc """
  Records a shutdown event.
  """
  @spec record_shutdown(:clean | :abnormal | :power_loss | :crash) :: :ok
  def record_shutdown(shutdown_type) do
    # In production: persist to database
    :ok
  end

  @doc """
  Records a recovery event.
  """
  @spec record_recovery(boolean(), integer()) :: :ok
  def record_recovery(success, experiments_lost) do
    # In production: persist to database
    :ok
  end

  @doc """
  Returns the formatted observatory report as a string.
  """
  @spec format_report() :: String.t()
  def format_report do
    panel = get_panel()
    metrics = get_long_horizon_metrics()

    """
    ╔══════════════════════════════════════════════════════════╗
    ║          Tiannara Resurrection Observatory              ║
    ╠══════════════════════════════════════════════════════════╣
    ║  Runtime Availability:     #{format_pct(panel.runtime_availability)}%           ║
    ║  Unexpected Shutdowns:     #{panel.unexpected_shutdowns}                       ║
    ║  Recovered Automatically:  #{panel.recovered_automatically}                       ║
    ║  Recovery Success:         #{format_pct(panel.recovery_success_rate)}%           ║
    ║  Lost Experiments:         #{panel.lost_experiments}                           ║
    ║  Replay Divergence:        #{panel.replay_divergence}                           ║
    ╠══════════════════════════════════════════════════════════╣
    ║  Long-Horizon Metrics:                                 ║
    #{format_metrics(metrics)}
    ╚══════════════════════════════════════════════════════════╝
    """
  end

  defp format_pct(nil), do: "0.0"
  defp format_pct(val), do: :io_lib.format("~.1f", [val]) |> to_string()

  defp format_metrics(metrics) do
    Enum.map_join(metrics, "\n", fn m ->
      "║    #{String.pad_trailing(m.metric_name, 20)} │ #{String.pad_leading(m.active_runtime_value, 18)} │ #{String.pad_leading(m.wall_clock_value, 18)} ║"
    end)
  end
end
