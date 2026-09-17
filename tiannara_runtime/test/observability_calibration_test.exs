defmodule TiannaraRuntime.Observability.CalibrationRunnerTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.Observability.CalibrationRunner

  setup do
    start_supervised!(CalibrationRunner)
    :ok
  end

  test "initializes default 12 worlds with operational status" do
    worlds = CalibrationRunner.get_world_metrics()
    assert map_size(worlds) == 12

    for {id, world} <- worlds do
      assert String.starts_with?(id, "world_")
      assert world.status == :operational
      assert is_number(world.entropy)
      assert is_number(world.coherence)
      assert is_number(world.semantic_diversity)
      assert is_number(world.attractor_convergence)
      assert is_number(world.stabilizer_overreach)
      assert is_number(world.msg_pressure)
      assert is_integer(world.active_branches)
      assert is_integer(world.active_civilizations)
      assert is_integer(world.agent_count)
    end
  end

  test "retrieves a single world metrics successfully" do
    assert {:ok, world} = CalibrationRunner.get_world_metrics("world_1")
    assert world.id == "world_1"

    assert {:error, :not_found} = CalibrationRunner.get_world_metrics("world_invalid")
  end

  test "successfully applies mild_diversity_boost intervention" do
    {:ok, initial} = CalibrationRunner.get_world_metrics("world_1")

    CalibrationRunner.trigger_intervention("world_1", "mild_diversity_boost")
    
    {:ok, updated} = CalibrationRunner.get_world_metrics("world_1")
    
    assert updated.semantic_diversity >= initial.semantic_diversity
    assert updated.attractor_convergence <= initial.attractor_convergence
    assert updated.stabilizer_overreach <= initial.stabilizer_overreach
  end

  test "successfully applies entropy_injection intervention" do
    {:ok, initial} = CalibrationRunner.get_world_metrics("world_2")

    CalibrationRunner.trigger_intervention("world_2", "entropy_injection")
    
    {:ok, updated} = CalibrationRunner.get_world_metrics("world_2")
    
    assert updated.entropy >= initial.entropy
    assert updated.semantic_diversity >= initial.semantic_diversity
    assert updated.stabilizer_overreach <= initial.stabilizer_overreach
  end

  test "successfully applies heavy_suppression intervention" do
    {:ok, initial} = CalibrationRunner.get_world_metrics("world_3")

    CalibrationRunner.trigger_intervention("world_3", "heavy_suppression")
    
    {:ok, updated} = CalibrationRunner.get_world_metrics("world_3")
    
    assert updated.entropy <= initial.entropy
    assert updated.stabilizer_overreach >= initial.stabilizer_overreach
  end
end
