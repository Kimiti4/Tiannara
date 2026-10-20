defmodule Tiannara.Meta.Epistemics.EpistemicThermodynamicsTest do
  use ExUnit.Case

  alias Tiannara.Meta.Epistemics.EpistemicThermodynamics

  test "pressure increases with knowledge mass" do
    p1 =
      EpistemicThermodynamics.compute_pressure(10, 0.1)

    p2 =
      EpistemicThermodynamics.compute_pressure(1000, 0.1)

    assert p2 > p1
  end
end
