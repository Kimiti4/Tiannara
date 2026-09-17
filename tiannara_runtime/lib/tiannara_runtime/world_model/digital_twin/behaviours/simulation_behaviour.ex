defprotocol TiannaraRuntime.WorldModel.DigitalTwin.Behaviours.SimulationBehaviour do
  @moduledoc """
  Phase 17.7.1 — SimulationBehaviour protocol.
  Describes how a simulation scenario executes.
  """
  def setup(scenario)
  def execute(scenario, twin)
  def teardown(scenario, twin)
end
