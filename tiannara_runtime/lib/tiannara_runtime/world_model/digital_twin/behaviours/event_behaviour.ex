defprotocol TiannaraRuntime.WorldModel.DigitalTwin.Behaviours.EventBehaviour do
  @moduledoc """
  Phase 17.7.1 — EventBehaviour protocol.
  Describes how events are triggered and applied.
  """
  def trigger(event, twin)
  def apply(event, twin)
  def validate(event)
end
