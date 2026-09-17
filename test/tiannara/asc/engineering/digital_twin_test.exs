defmodule Tiannara.ASC.Engineering.DigitalTwinTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Engineering.DigitalTwinManager

  setup do
    case DigitalTwinManager.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
    :ok
  end

  test "creates a digital twin" do
    design = %{id: "design_1", name: "Test Design", constraints: %{max_latency_ms: 500, max_memory_mb: 256, availability_target: 0.99}, components: [%{id: "core"}]}

    {:ok, twin_id} = DigitalTwinManager.create_twin(design)
    assert is_binary(twin_id)

    twins = DigitalTwinManager.twins()
    assert Enum.any?(twins, &(&1.id == twin_id))
  end

  test "simulates a scenario on a twin" do
    design = %{id: "design_2", name: "Sim Design", constraints: %{max_latency_ms: 1000, max_memory_mb: 512, availability_target: 0.99}, components: []}

    {:ok, twin_id} = DigitalTwinManager.create_twin(design)
    {:ok, result} = DigitalTwinManager.simulate(twin_id, %{load_factor: 2.0, duration_hours: 48})

    assert result.predicted_state in [:nominal, :degraded]
    assert result.predicted_latency_ms > 0
  end

  test "returns error for non-existent twin" do
    assert {:error, :twin_not_found} = DigitalTwinManager.simulate("nonexistent", %{})
  end
end
