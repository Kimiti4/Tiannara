defmodule Tiannara.ASC.Research.PortfolioPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.ASC.Research.Portfolio

  setup do
    case Portfolio.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
    :ok
  end

  describe "Portfolio invariants" do
    property "success rate is always in [0.0, 1.0]" do
      check all successes <- integer(0..20),
                failures <- integer(0..20),
                max_runs: 20 do
        Enum.each(1..successes, fn _ ->
          Portfolio.record_outcome("prog_test", %{domain: :test, success: true, impact: 1.0, resources_used: 10})
        end)

        Enum.each(1..failures, fn _ ->
          Portfolio.record_outcome("prog_test", %{domain: :test, success: false, impact: 0.0, resources_used: 10})
        end)

        Process.sleep(50)

        rate = Portfolio.success_rate()
        assert rate >= 0.0
        assert rate <= 1.0
      end
    end
  end
end
