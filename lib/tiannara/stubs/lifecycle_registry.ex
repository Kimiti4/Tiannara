defmodule TiannaraOS.LifecycleRegistry do
  use Tiannara.Stub, subsystem: :os, phase: "Omega+", priority: :high

  def track_entity(entity_type, entity_id, event_type, metadata) do
    stub_result(:track_entity, [entity_type, entity_id, event_type, metadata], {:ok, :tracked})
  end
end
