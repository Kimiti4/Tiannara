defmodule Tiannara.TWP.ResurrectionEngine do
  @moduledoc """
  Restores an archived branch if new evidence dramatically shifts its probability.
  """
  require Logger

  def resurrect(branch_id, new_evidence) do
    if new_evidence > 0.8 do
      Logger.info("🧟 [TWP] Resurrecting Branch #{branch_id} due to new compelling evidence.")
      Tiannara.Metrics.Aggregator.push_event([:tiannara, :twp, :resurrection_rate], 1.0)
      {:ok, :resurrected}
    else
      {:error, :insufficient_evidence}
    end
  end
end
