defmodule Tiannara.ASC.Immunity.AutoImmuneRegulator do
  @moduledoc """
  Phase 16: Prevents the Immune System from attacking healthy, novel mutations.
  Distinguishes between 'malignant disease' and 'healthy exploration'.
  Translates threat severity into graduated quarantine levels.
  """
  alias Tiannara.ASC.Immunity.EpistemicThreat

  def evaluate_threat(%EpistemicThreat{} = threat) do
    case threat.severity do
      :level_1_observe -> {:observe, "Benign anomaly. Monitoring."}
      :level_2_flag -> {:flag, "Warning threshold reached."}
      :level_3_restrict -> {:restrict, "Restricting execution to prevent ossification."}
      :level_4_quarantine -> {:quarantine, "Malignant epistemic threat detected. Isolating."}
      :level_5_extinction -> {:extinction, "Terminal threat detected. Reward hacking or critical failure."}
      _ -> {:observe, "Unknown severity."}
    end
  end
end
