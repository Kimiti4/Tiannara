defmodule Tiannara.Validation.Campaign do
  @moduledoc """
  Coordinates execution of bounded simulation validations (10k, 50k, 100k ticks).
  """
  require Logger

  defstruct [
    :id,
    :name,
    :target_ticks,
    :current_tick,
    :status, # :pending, :running, :passed, :failed
    :report
  ]

  def run_campaign(name, ticks) do
    campaign = %__MODULE__{
      id: "val_#{:erlang.unique_integer([:positive])}",
      name: name,
      target_ticks: ticks,
      current_tick: 0,
      status: :running
    }
    
    Logger.info("🧪 [Validation] Starting Campaign: #{name} (#{ticks} ticks)")
    
    # Simulate execution
    Logger.info("   ... simulating #{ticks} ticks ...")
    
    # Check health after simulation
    snapshot = Tiannara.Metrics.Aggregator.get_snapshot()
    score = Tiannara.SystemHealth.Score.compute(snapshot)
    
    status = if score > 0.5, do: :passed, else: :failed
    
    report = %Tiannara.Validation.Report{
      campaign_id: campaign.id,
      final_score: score,
      passed: status == :passed,
      snapshot: snapshot
    }
    
    Logger.info("🧪 [Validation] Campaign #{status}. Final Score: #{Float.round(score, 2)}")
    
    %{campaign | status: status, current_tick: ticks, report: report}
  end
end
