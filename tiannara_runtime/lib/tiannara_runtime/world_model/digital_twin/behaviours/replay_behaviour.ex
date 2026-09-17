defprotocol TiannaraRuntime.WorldModel.DigitalTwin.Behaviours.ReplayBehaviour do
  @moduledoc """
  Phase 17.7.1 — ReplayBehaviour protocol.
  Describes how replay is verified and executed.
  """
  def checkpoint(twin, tick)
  def verify(twin, original)
  def replay(twin)
end
