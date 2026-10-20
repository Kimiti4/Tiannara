defmodule Tiannara.Meta.Evolution.PhysicsMutatorTest do
  use ExUnit.Case

  alias Tiannara.Meta.Evolution.PhysicsMutator

  test "mutates constants safely" do
    law = %{
      oir_ast: {:const, 10.0}
    }

    result = PhysicsMutator.mutate(law)

    assert result != nil
    # Check if mutated_ast is still a :const but possibly different value
    {:const, val} = result.oir_ast
    assert is_number(val)
  end
end
