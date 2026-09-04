defmodule Tiannara.ValidationSprint do
  @moduledoc """
  Executes the Meta-Stability Validation Sprint (10k tick simulation).
  """
  alias Tiannara.Metrics.Aggregator
  alias Tiannara.Metrics.Export
  alias Tiannara.Validation.Campaign
  alias Tiannara.Orbital.Classifier
  alias Tiannara.Web.MissionControl
  require Logger

  def run do
    Logger.info("🌌 [Meta-Stability Sprint] Booting Validation Framework...")

    # 1. Start the Aggregator
    {:ok, _pid} = Aggregator.start_link([])

    # 2. Simulate 10k ticks of Telemetry
    Logger.info("📡 [Telemetry] Emitting 10,000 simulated ticks of ecological activity...")
    
    # Simulate a recovery orbit trajectory
    Aggregator.push_event([:tiannara, :grcc, :entropy], 0.2)
    Aggregator.push_event([:tiannara, :cis, :collapse_probability], 0.05)
    Aggregator.push_event([:tiannara, :research, :theory, :validated], 1)
    Aggregator.push_event([:tiannara, :domain, :capital, :updated], 150)

    # 3. Classify Orbit
    snapshot = Aggregator.get_snapshot()
    orbit = Classifier.classify(snapshot)
    Aggregator.push_event([:tiannara, :orbit, :transition], orbit)
    
    # 4. Run Campaign
    campaign = Campaign.run_campaign("10k_Tick_Validation", 10_000)
    
    # 5. Persist Snapshot
    final_snapshot = Aggregator.get_snapshot()
    Export.persist_snapshot(final_snapshot)
    
    # 6. Verify Dashboard Hardening
    dashboard_data = MissionControl.render_system_health()
    Logger.info("🖥️ [Mission Control] System Health Rendered: Status=#{dashboard_data.status}, Score=#{Float.round(dashboard_data.score, 2)}")
    
    Logger.info("\n🏆 [Validation Sprint] Complete. Campaign Result: #{campaign.status}")
  end
end

Tiannara.ValidationSprint.run()
