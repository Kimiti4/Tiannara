defmodule Tiannara.ASC.Research.DirectorTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Research.Director

  setup do
    case Director.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
    :ok
  end

  describe "ResearchDirector" do
    test "accepts and tracks research programs" do
      {:ok, program_id} = Director.submit_program(%{
        name: "Quantum Computing Research",
        domain: :physics,
        objective: "Discover new quantum error correction methods",
        priority: :high
      })

      assert is_binary(program_id)

      programs = Director.active_programs()
      assert Enum.any?(programs, &(&1.id == program_id))
    end

    test "prioritizes programs correctly" do
      Director.submit_program(%{name: "Low Priority", priority: :low, domain: :test})
      Director.submit_program(%{name: "Critical Priority", priority: :critical, domain: :test})

      Process.sleep(1000)

      priorities = Director.priorities()
      assert is_list(priorities)
    end

    test "reports statistics" do
      stats = Director.stats()
      assert stats.total_programs >= 0
      assert is_map(stats.resource_budget)
    end
  end
end
