defmodule Tiannara.ASC.Agency.OrchestratorTest do
  use ExUnit.Case, async: true

  test "refuses to fabricate observations when no provider exists" do
    assert {:error, :observation_backend_unavailable} =
             Tiannara.ASC.Agency.Orchestrator.run_cycle(%{}, :audit)
  end

  test "requires real providers for the complete research loop" do
    ctx = %{
      observation_provider: fn _ -> {:ok, [%{id: "o1", data: %{value: 1}}]} end,
      hypothesis_provider: fn _obs, _ctx -> {:ok, [%{id: "h1"}]} end,
      experiment_provider: fn _h, _ctx -> {:ok, %{id: "r1", status: :observed}} end
    }

    assert {:error, :knowledge_integration_backend_unavailable} =
             Tiannara.ASC.Agency.Orchestrator.run_cycle(ctx, :audit)
  end
end
