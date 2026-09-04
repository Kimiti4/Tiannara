defmodule Tiannara.Agency.TelemetryCollector do
  @moduledoc """
  Collects observations from all observable subsystems.
  In production, each source is a real adapter; here we produce realistic signals.
  """
  alias Tiannara.Agency.Models.Observation

  def collect(source) do
    base_time = DateTime.utc_now()

    case source do
      :rea_evolution ->
        [
          observation(:rea_evolution, :genome_entropy, random_around(0.65, 0.15), base_time),
          observation(:rea_evolution, :discovery_rate, random_around(12.0, 4.0), base_time),
          observation(:rea_evolution, :lineage_diversity, random_around(0.78, 0.10), base_time)
        ]

      :sopl_governance ->
        [
          observation(:sopl_governance, :law_stability, random_around(0.88, 0.05), base_time),
          observation(:sopl_governance, :constitutional_compliance, random_around(0.95, 0.03), base_time)
        ]

      :memory_system ->
        [
          observation(:memory_system, :usage_mb, random_around(512, 80), base_time),
          observation(:memory_system, :compression_ratio, random_around(0.82, 0.05), base_time),
          observation(:memory_system, :retrieval_latency_ms, random_around(45, 15), base_time)
        ]

      :reality_graph ->
        [
          observation(:reality_graph, :node_count, random_around(10_000, 500), base_time),
          observation(:reality_graph, :edge_count, random_around(25_000, 1200), base_time),
          observation(:reality_graph, :query_latency_ms, random_around(30, 10), base_time)
        ]

      :runtime_performance ->
        [
          observation(:runtime_performance, :cpu_percent, random_around(35, 15), base_time),
          observation(:runtime_performance, :process_count, random_around(120, 20), base_time),
          observation(:runtime_performance, :message_queue_depth, random_around(50, 25), base_time)
        ]

      :security_posture ->
        [
          observation(:security_posture, :auth_failure_rate, random_around(0.02, 0.01), base_time),
          observation(:security_posture, :anomaly_score, random_around(0.15, 0.08), base_time)
        ]

      :knowledge_growth ->
        [
          observation(:knowledge_growth, :principles_count, random_around(45, 5), base_time),
          observation(:knowledge_growth, :validated_assets, random_around(320, 40), base_time),
          observation(:knowledge_growth, :reuse_rate, random_around(0.68, 0.12), base_time)
        ]
    end
  end

  defp observation(source, metric, value, timestamp) do
    %Observation{
      id: UUID.uuid4(),
      timestamp: timestamp,
      source: source,
      metric_name: metric,
      value: value,
      baseline: value * 0.95,
      delta: value * 0.05,
      delta_percent: 5.0,
      quality: 0.9 + :rand.uniform() * 0.1
    }
  end

  defp random_around(mean, spread) do
    mean + (:rand.uniform() * 2 - 1) * spread
  end
end
