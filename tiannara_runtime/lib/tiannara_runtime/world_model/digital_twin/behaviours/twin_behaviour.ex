defprotocol TiannaraRuntime.WorldModel.DigitalTwin.Behaviours.TwinBehaviour do
  @moduledoc """
  Phase 17.7.1 — TwinBehaviour protocol.
  Describes how a model operates within the digital twin.
  """
  def initialize(twin, model)
  def step(twin, model, clock)
  def shutdown(twin, model)
end
