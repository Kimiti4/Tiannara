defmodule Tiannara.Validation.Scorecard do
  @moduledoc """
  A consolidated summary of all recent validation campaigns.
  """
  
  def render(reports) do
    # Formats a summary for Mission Control
    Enum.map(reports, fn report ->
      %{
        campaign: report.campaign_id,
        passed: report.passed,
        score: report.final_score
      }
    end)
  end
end
