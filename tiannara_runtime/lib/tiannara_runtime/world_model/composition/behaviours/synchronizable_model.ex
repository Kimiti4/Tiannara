defprotocol TiannaraRuntime.WorldModel.Composition.Behaviours.SynchronizableModel do
  @moduledoc """
  Phase 17.6.1 — SynchronizableModel protocol.
  Describes how a world model synchronizes state with other models.
  """

  @doc "Returns the current state snapshot for synchronization."
  def sync_state(model)

  @doc "Applies received state from another model."
  def apply_sync(model, source_model_id, state)

  @doc "Returns the temporal mode of this model (discrete, continuous, event_driven)."
  def temporal_mode(model)
end
