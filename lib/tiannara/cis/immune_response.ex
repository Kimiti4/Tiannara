defmodule Tiannara.CIS.ImmuneResponse do
  @moduledoc """
  CIS intervention boundary.

  CIS can propose and evaluate interventions, but it cannot claim a live
  intervention succeeded without a real execution provider and measured result.
  """

  def deploy(_pathogen_type) do
    {:error, :live_intervention_executor_unavailable}
  end
end
