defmodule Tiannara.Discovery.DiscoverySupervisor do
  use Supervisor

  alias Tiannara.Discovery.{DiscoveryEngine, DiscoveryScheduler, DiscoveryMetrics}

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def capabilities do
    [:discovery_orchestration, :hypothesis_generation, :gap_analysis,
     :contradiction_analysis, :experiment_planning, :discovery_lineage]
  end

  def init(_opts) do
    children = [
      {DiscoveryEngine, []},
      {DiscoveryScheduler, [interval_ms: 30 * 60 * 1000]},
      {DiscoveryMetrics, []}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def health do
    checks = %{
      discovery_engine: Process.whereis(DiscoveryEngine) != nil,
      discovery_scheduler: Process.whereis(DiscoveryScheduler) != nil,
      discovery_metrics: Process.whereis(DiscoveryMetrics) != nil
    }
    degraded = checks |> Enum.filter(fn {_k, v} -> not v end) |> Enum.map(fn {k, _} -> k end)
    case degraded do
      [] -> :healthy
      _ -> {:degraded, degraded}
    end
  end

  def constitutional_score do
    Tiannara.Discovery.DiscoveryEngine.constitutional_score()
  rescue _ -> Tiannara.CEL.Kernel.ConstitutionalScore.default(:discovery_supervisor)
  end
end
