defmodule Tiannara.ASC.ResearchRegistryA4bTest do
  @moduledoc """
  Production-readiness scan A4b: the registry's declared stubs must be real
  or fail closed — `update_program_metrics/2` persists real telemetry
  deltas, `freeze_program/1` actually freezes (and allocation excludes
  frozen programs), surviving genomes round-trip through registry state,
  and `apply_engineering_roi/2` fails closed with a named error instead of
  returning `{:ok, :stub}` under callers' "ROI fed back" logs.
  """
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Research.{ResearchProgram, ResearchRegistry}

  setup do
    case Process.whereis(ResearchRegistry) do
      nil ->
        {:ok, pid} = ResearchRegistry.start_link([])

        on_exit(fn ->
          if Process.alive?(pid), do: GenServer.stop(pid)
        end)

        %{pid: pid}

      pid ->
        %{pid: pid}
    end
  end

  defp register_test_program(tag) do
    domain = String.to_atom("a4b_#{tag}_#{System.unique_integer([:positive])}")

    program = %ResearchProgram{
      name: "A4b #{tag}",
      domain: domain,
      methodology: :targeted_experimentation,
      budget: 1000
    }

    prog_id = ResearchRegistry.register_program(program)
    prog_id
  end

  defp fetch_program(prog_id) do
    ResearchRegistry.get_all_programs()
    |> Enum.find(&(Map.get(&1, :id) == prog_id))
  end

  describe "update_program_metrics/2 (scan A4b)" do
    test "persists real telemetry deltas into the stored program" do
      prog_id = register_test_program(:metrics)

      assert {:ok, updated} =
               ResearchRegistry.update_program_metrics(prog_id, %{
                 laws_generated: 3,
                 utility_generated: 12.5,
                 compute_consumed: 4
               })

      assert updated.laws_generated == 3
      assert updated.utility_generated == 12.5
      assert updated.compute_consumed == 4

      stored = fetch_program(prog_id)
      assert stored.id == prog_id
      assert stored.laws_generated == 3

      assert {:ok, _} = ResearchRegistry.update_program_metrics(prog_id, %{laws_generated: 2})
      assert fetch_program(prog_id).laws_generated == 5
    end

    test "accumulates the full delta, including keys with no struct home" do
      prog_id = register_test_program(:delta_store)

      assert {:ok, _} =
               ResearchRegistry.update_program_metrics(prog_id, %{
                 laws_generated: 1,
                 information_gain: 9.0
               })

      assert {:ok, metrics} = ResearchRegistry.get_program_metrics(prog_id)
      assert metrics.information_gain == 9.0
      assert metrics.laws_generated == 1
    end

    test "fails closed for unknown programs and invalid deltas" do
      assert {:error, :not_found} =
               ResearchRegistry.update_program_metrics("program_no_such_program", %{laws_generated: 1})

      assert {:error, :invalid_delta} =
               ResearchRegistry.update_program_metrics("program_no_such_program", :not_a_map)

      assert {:error, :not_found} = ResearchRegistry.get_program_metrics("program_no_such_program")
    end
  end

  describe "freeze_program/1 (scan A4b)" do
    test "actually freezes: budget 0, fitness 0.0, excluded from allocation" do
      frozen_id = register_test_program(:freeze)
      other_id = register_test_program(:freeze_other)

      assert {:ok, frozen} = ResearchRegistry.freeze_program(frozen_id)
      assert frozen.frozen
      assert frozen.budget == 0
      assert frozen.program_fitness == 0.0

      stored = fetch_program(frozen_id)
      assert stored.frozen
      assert stored.budget == 0

      allocations = ResearchRegistry.allocate_resources(10_000)
      refute Map.has_key?(allocations, frozen_id)
      assert Map.has_key?(allocations, other_id)
    end

    test "fails closed for unknown ids instead of pretending to freeze" do
      assert {:error, :not_found} = ResearchRegistry.freeze_program("program_no_such_program")
    end
  end

  describe "surviving-genome storage (scan A4b)" do
    test "store/get round-trip through registry state replaces the previous set" do
      genome = %Tiannara.ASC.MetaScience.ResearchGenome{
        id: "genome_a4b_#{System.unique_integer([:positive])}",
        name: "A4b Genome",
        status: :active
      }

      assert {:ok, 1} = ResearchRegistry.store_surviving_genomes([genome])
      assert [stored] = ResearchRegistry.get_surviving_genomes()
      assert stored.id == genome.id

      assert {:ok, 0} = ResearchRegistry.store_surviving_genomes([])
      assert ResearchRegistry.get_surviving_genomes() == []
    end

    test "rejects non-list payloads" do
      assert {:error, :invalid_genomes} = ResearchRegistry.store_surviving_genomes(:not_a_list)
    end
  end

  describe "apply_engineering_roi/2 (scan A4b)" do
    test "fails closed with a named error — no fabricated feedback" do
      assert {:error, :not_implemented} =
               ResearchRegistry.apply_engineering_roi("genome_x", 0.42)
    end
  end
end
