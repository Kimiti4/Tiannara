defmodule Tiannara.Telemetry.WorldState.World do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field :id, 1, type: :uint64
  field :x, 2, type: :float
  field :y, 3, type: :float
  field :z, 4, type: :float
  field :entropy, 5, type: :float
  field :status_color, 6, type: :uint32
  field :scale, 7, type: :float
end

defmodule Tiannara.Telemetry.WorldState do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field :tick, 1, type: :uint64
  field :worlds, 2, repeated: true, type: Tiannara.Telemetry.WorldState.World
end
