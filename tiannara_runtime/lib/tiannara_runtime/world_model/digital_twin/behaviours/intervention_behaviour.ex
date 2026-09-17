defprotocol TiannaraRuntime.WorldModel.DigitalTwin.Behaviours.InterventionBehaviour do
  @moduledoc """
  Phase 17.7.1 — InterventionBehaviour protocol.
  Describes how interventions are scheduled and applied.
  """
  def schedule(intervention, twin)
  def apply(intervention, twin)
  def condition_met?(intervention, twin)
end
