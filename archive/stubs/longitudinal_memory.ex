defmodule Tiannara.Meta.Epistemics.LongitudinalMemory do
  use Tiannara.Stub, subsystem: :meta, phase: "Omega+", priority: :high

  def get_compressed_state(world_id) do
    stub_result(:get_compressed_state, [world_id], %{leoc: [1.0, 0.0, 0.0, 0.0]})
  end
end
