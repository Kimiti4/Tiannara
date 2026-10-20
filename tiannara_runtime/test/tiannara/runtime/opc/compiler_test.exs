defmodule Tiannara.Runtime.OPC.CompilerTest do
  use ExUnit.Case

  alias Tiannara.Runtime.OPC.Compiler

  test "compiles observer input to GPU shaders" do
    input = %{
      observer: "obs_001",
      intent: :gravity_mutation,
      constraints: [:local_only],
      scope: :local
    }

    ir = Compiler.compile(input)

    assert ir.observer_id == "obs_001"
    assert length(ir.nodes) == 1
    assert length(ir.compiled_rules) == 1
    assert length(ir.gpu_shaders) == 1
    
    shader = hd(ir.gpu_shaders)
    assert shader =~ "#version 310 es"
    assert shader =~ "void main()"
  end

  test "raises on semantic validation error (high entropy)" do
    # Creating a large input to trigger high entropy
    large_constraints = Enum.map(1..2000, fn i -> :"constraint_#{i}" end)
    
    input = %{
      observer: "obs_002",
      intent: :complex_mutation,
      constraints: large_constraints,
      scope: :local
    }

    assert_raise RuntimeError, ~r/:entropy_overflow/, fn ->
      Compiler.compile(input)
    end
  end
end
