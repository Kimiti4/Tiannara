defmodule Tiannara.ASC.Civilization.Queries do
  alias Tiannara.ASC.Civilization.{WorldModel, GlobalRiskEngine, SustainabilityEngine, Director}

  def state, do: WorldModel.current_state()

  def global_risk do
    {:ok, risk} = GlobalRiskEngine.assess(state())
    risk
  end

  def sustainability do
    {:ok, result} = SustainabilityEngine.evaluate(state())
    result
  end

  def plan, do: Director.current_plan()
  def decisions, do: Director.decisions()
end
