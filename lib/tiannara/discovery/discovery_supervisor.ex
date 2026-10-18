defmodule Tiannara.Discovery.DiscoverySupervisor do
  use Supervisor

  alias Tiannara.Discovery.{DiscoveryEngine, DiscoveryScheduler, DiscoveryMetrics}
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
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

  # Fail-closed (production-readiness scan B2): when the engine cannot answer,
  # report the constitutionally-defined unavailable score (all zeros — never
  # boot-ready) instead of the all-ones self-asserted default. `catch` covers
  # raises, throws, and :noproc exits, which `rescue` alone would miss.
  def constitutional_score do
    Tiannara.Discovery.DiscoveryEngine.constitutional_score()
  catch
    kind, reason ->
      Logger.warning(
        "[DiscoverySupervisor] constitutional_score unavailable (#{inspect(kind)}: #{inspect(reason)})"
      )

      Tiannara.CEL.Kernel.ConstitutionalScore.unavailable(:discovery_supervisor)
  end
end
