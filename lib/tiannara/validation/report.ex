defmodule Tiannara.Validation.Report do
  @moduledoc """
  Stores the outcome of a validation campaign.
  """
  defstruct [
    :campaign_id,
    :final_score,
    :passed,
    :snapshot
  ]
end
