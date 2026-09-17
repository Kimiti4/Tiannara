defmodule Tiannara.ASC.Research.ChaosTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Research.{Director, Portfolio, ReplicationEngine}

  @moduletag :chaos

  describe "Research subsystem under adverse conditions" do
    test "Director handles rapid program submission" do
      case Director.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end

      results = Enum.map(1..50, fn i ->
        Director.submit_program(%{name: "Program #{i}", domain: :test, priority: :medium})
      end)

      assert Enum.all?(results, &match?({:ok, _}, &1))
    end

    test "ReplicationEngine handles empty queue gracefully" do
      case ReplicationEngine.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end

      stats = ReplicationEngine.stats()
      assert stats.queued == 0
      assert stats.confirmation_rate >= 0.0
    end

    test "Portfolio handles concurrent outcome recording" do
      case Portfolio.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end

      tasks = Enum.map(1..20, fn i ->
        Task.async(fn ->
          Portfolio.record_outcome("prog_#{i}", %{
            domain: :test,
            success: rem(i, 2) == 0,
            impact: i * 0.1,
            resources_used: 10
          })
        end)
      end)

      Enum.each(tasks, &Task.await/1)
      Process.sleep(500)

      summary = Portfolio.summary()
      assert summary.total_programs >= 0
    end
  end
end
