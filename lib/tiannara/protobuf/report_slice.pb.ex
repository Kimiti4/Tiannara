defmodule Tiannara.Telemetry.ReportSlice.Coordinate do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field :id, 1, type: :uint64
  field :x, 2, type: :float
  field :y, 3, type: :float
  field :z, 4, type: :float
  field :pressure, 5, type: :float
  field :entropy, 6, type: :float
end

defmodule Tiannara.Telemetry.ReportSlice do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field :epoch_range, 1, repeated: true, type: :uint64
  field :avg_entropy, 2, type: :float
  field :peak_pressure, 3, type: :float
  field :mutation_count, 4, type: :uint32
  field :sample_coordinates, 5, repeated: true, type: Tiannara.Telemetry.ReportSlice.Coordinate
end
