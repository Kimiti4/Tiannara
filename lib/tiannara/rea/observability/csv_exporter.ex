defmodule Tiannara.REA.Observability.CSVExporter do
  @moduledoc "Exports the Continuity Tracker data to a CSV file for plotting."
  require Logger

  def export(filename \\ "rea_4_7_telemetry.csv") do
    data = Tiannara.REA.Observability.ContinuityTracker.get_time_series()
    
    if data == [] do
      Logger.warning("⚠️ [CSVExporter] No telemetry data found to export.")
      :ok
    else
      # Sort by epoch
      data = Enum.sort_by(data, & &1.epoch)
      
      header = "epoch,novelty_rate,novelty_source_count,genome_entropy,domain_entropy,extinctions,total_knowledge,is_monoculture\n"
      
      rows = Enum.map(data, fn row ->
        "#{row.epoch},#{row.novelty_rate},#{row.novelty_source_count},#{row.genome_entropy},#{row.domain_entropy},#{row.extinctions},#{row.total_knowledge},#{row.is_monoculture}\n"
      end)
      
      File.write!(filename, [header | rows])
      Logger.info("✅ [CSVExporter] Exported #{length(data)} rows to #{filename}.")
      :ok
    end
  end
end
