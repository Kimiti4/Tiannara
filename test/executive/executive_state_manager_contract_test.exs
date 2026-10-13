defmodule Tiannara.Executive.ExecutiveStateManagerContractTest do
  use ExUnit.Case, async: false

  alias Tiannara.CEL.Services.{ExecutiveMetrics, ExecutiveStateManager}

  test "executive metrics can collect KPIs without crashing when querying state" do
    if Process.whereis(ExecutiveStateManager) == nil do
      start_supervised!({ExecutiveStateManager, []})
    end

    if Process.whereis(ExecutiveMetrics) == nil do
      start_supervised!({ExecutiveMetrics, []})
    end

    Process.sleep(250)

    assert Process.alive?(Process.whereis(ExecutiveMetrics))
    assert is_map(ExecutiveMetrics.get_kpis())
  end
end
