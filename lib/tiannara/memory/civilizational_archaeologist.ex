defmodule Tiannara.Memory.CivilizationalArchaeologist do
  @moduledoc """
  Phase 22: Deep Time Memory.
  Compresses the Fossil Record and Treaty History into Epochal Strata.
  Allows the civilization to remember centuries, not just days.
  """
  require Logger

  @strata_path "data/archaeology/strata/"

  @doc """
  Compresses the events of a completed Era into a permanent geological stratum.
  """
  def form_stratum(era_name, summary) do
    stratum = %{
      era: era_name,
      timestamp: System.system_time(:second),
      dominant_paradigms: summary.paradigms,
      fatal_mistakes: summary.fatal_mistakes,
      breakthrough_laws: summary.laws,
      economic_conditions: summary.economics
    }

    File.mkdir_p!(@strata_path)
    file = Path.join(@strata_path, "#{era_name}.json")
    File.write!(file, Jason.encode!(stratum, pretty: true))
    Logger.info("🏺 [Archaeologist] Formed geological stratum for Era: #{era_name}")
  end

  @doc """
  Excavates deep time to find historical precedents for current friction.
  """
  def excavate_precedent(current_friction_profile) do
    Logger.info("⛏️ [Archaeologist] Excavating deep time for historical precedents...")
    
    if File.exists?(@strata_path) do
      @strata_path
      |> File.ls!()
      |> Enum.map(fn file -> 
        @strata_path |> Path.join(file) |> File.read!() |> Jason.decode!() 
      end)
      |> Enum.filter(fn stratum -> 
        # Heuristic: Match current friction against historical economic/paradigm conditions
        MapSet.intersection(MapSet.new(stratum["economic_conditions"] || []), MapSet.new(current_friction_profile)) 
        |> MapSet.size() > 0
      end)
    else
      []
    end
  end
end
