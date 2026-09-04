defmodule Tiannara.CIS.OverreactionMonitor do
  @moduledoc """
  Prevents the immune system from causing autoimmune collapse.
  """

  def veto_intervention?(:valid_innovation, _payload) do
    Tiannara.Metrics.Aggregator.push_event([:tiannara, :cis, :false_positive_rate], 0.0)
    true
  end
  
  def veto_intervention?(_, _payload) do
    Tiannara.Metrics.Aggregator.push_event([:tiannara, :cis, :false_positive_rate], 0.01)
    false
  end
end
