defmodule TiannaraRuntime.LayerEnforcementTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Layer

  test "allows sanctioned authority edges" do
    assert :ok = Layer.assert_call!(:meta, :constraint)
    assert :ok = Layer.assert_call!(:constraint, :ecology)
    assert :ok = Layer.assert_call!(:ecology, :execution)
  end

  test "rejects forbidden lateral or upward calls" do
    assert_raise RuntimeError, fn -> Layer.assert_call!(:execution, :meta) end
    assert_raise RuntimeError, fn -> Layer.assert_call!(:ecology, :meta) end
    assert_raise RuntimeError, fn -> Layer.assert_call!(:constraint, :meta) end
  end
end
