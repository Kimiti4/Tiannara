defmodule TiannaraRuntime.Observability.TestPublisher do
  @moduledoc """
  COGNITIVE OBSERVABILITY LAYER: Test Event Publisher
  
  Publishes sample cognitive events to NATS for testing the visualization system.
  
  Usage:
    iex -S mix
    iex> TiannaraRuntime.Observability.TestPublisher.publish_sample_events()
  """
  
  require Logger
  
  @doc """
  Publish a set of sample events to test the observability layer.
  """
  def publish_sample_events() do
    Logger.info("🧪 Publishing sample cognitive events...")
    
    # Sample CAL events (coalition formation)
    publish_cal_event("C1", "coalition.formed", %{coherence: 0.85, entropy: 0.42, strength: 0.77})
    publish_cal_event("C2", "coalition.formed", %{coherence: 0.72, entropy: 0.55, strength: 0.65})
    publish_cal_event("C3", "coalition.formed", %{coherence: 0.91, entropy: 0.38, strength: 0.88})
    
    # Sample CIS events (entropy monitoring)
    publish_cis_event("field_1", "entropy.spike", %{entropy: 0.82, region: [10, 20]})
    publish_cis_event("intervention_1", "intervention.issued", %{type: "damping", target_entropy: 0.65})
    publish_cis_event("field_1", "entropy.damping", %{entropy: 0.58, damping_factor: 0.3})
    
    # Sample system events
    publish_system_event("system", "health.pulse", %{status: "healthy", uptime: 3600})
    publish_system_event("system", "mode.switch", %{old_mode: "exploration", new_mode: "exploitation"})
    
    Logger.info("✅ Sample events published successfully")
  end
  
  @doc """
  Publish a continuous stream of test events (for live testing).
  """
  def publish_continuous_stream(duration_seconds \\ 60) do
    Logger.info("🔄 Starting continuous event stream for #{duration_seconds} seconds...")
    
    end_time = System.monotonic_time(:second) + duration_seconds
    
    Enum.each(0..duration_seconds, fn second ->
      if System.monotonic_time(:second) < end_time do
        # Random coalition updates
        coalition_id = "C#{:rand.uniform(10)}"
        coherence = :rand.uniform() * 0.5 + 0.5  # 0.5 to 1.0
        entropy = :rand.uniform() * 0.4 + 0.4    # 0.4 to 0.8
        
        case :rand.uniform(3) do
          1 ->
            publish_cal_event(coalition_id, "coalition.updated", %{
              coherence: coherence,
              entropy: entropy,
              strength: :rand.uniform()
            })
          
          2 ->
            publish_cis_event("field_#{:rand.uniform(5)}", "entropy.tick", %{
              entropy: entropy,
              timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
            })
          
          3 ->
            if :rand.uniform() > 0.7 do
              publish_system_event("system", "health.pulse", %{
                status: if(entropy < 0.6, do: "healthy", else: "at_risk"),
                active_coalitions: :rand.uniform(20)
              })
            end
        end
        
        :timer.sleep(1000)  # 1 event per second
      end
    end)
    
    Logger.info("✅ Continuous stream completed")
  end
  
  # Private helper functions
  
  defp publish_cal_event(entity_id, type, metrics) do
    payload = Jason.encode!(%{
      type: type,
      entity_id: entity_id,
      entity_type: "coalition",
      metrics: metrics,
      state: "active",
      position: [
        (:rand.uniform() - 0.5) * 30,
        (:rand.uniform() - 0.5) * 20,
        (:rand.uniform() - 0.5) * 10
      ],
      timestamp: DateTime.utc_now() |> DateTime.to_unix()
    })
    
    TiannaraRuntime.EventGateway.publish_event("tiannara.cal.#{type}", payload)
    Logger.debug("📤 Published CAL event: #{type} for #{entity_id}")
  end
  
  defp publish_cis_event(entity_id, type, data) do
    payload = Jason.encode!(%{
      type: type,
      entity_id: entity_id,
      entity_type: "field",
      metrics: Map.take(data, [:entropy]),
      state: case type do
        "entropy.spike" -> "high_entropy"
        "entropy.damping" -> "stabilizing"
        _ -> "active"
      end,
      position: [0, 0, 0],
      timestamp: DateTime.utc_now() |> DateTime.to_unix(),
      extra: data
    })
    
    TiannaraRuntime.EventGateway.publish_event("tiannara.cis.#{type}", payload)
    Logger.debug("📤 Published CIS event: #{type}")
  end
  
  defp publish_system_event(entity_id, type, data) do
    payload = Jason.encode!(%{
      type: type,
      entity_id: entity_id,
      entity_type: "system",
      metrics: %{},
      state: Map.get(data, :status, "unknown"),
      position: [0, 0, 0],
      timestamp: DateTime.utc_now() |> DateTime.to_unix(),
      extra: data
    })
    
    TiannaraRuntime.EventGateway.publish_event("tiannara.system.#{type}", payload)
    Logger.debug("📤 Published system event: #{type}")
  end
end
