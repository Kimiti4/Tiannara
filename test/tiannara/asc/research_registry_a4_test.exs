defmodule Tiannara.ASC.ResearchRegistryA4Test do
  @moduledoc """
  Production-readiness scan A4: `get_all_programs/0` must read real registry
  state and must never serve the fabricated `prog_healthy`/`prog_echo_chamber`
  fixtures again; the echo-chamber predicate must not flag programs that do
  not self-report the metric.
  """
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Immunity.PathogenScanner
  alias Tiannara.ASC.Research.{ResearchGenome, ResearchProgram, ResearchRegistry}

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

  describe "get_all_programs/0 (scan A4)" do
    test "returns registered programs from GenServer state, not fabricated fixtures" do
      program = %ResearchProgram{
        name: "Transfer Physics",
        domain: :transfer_physics,
        methodology: :targeted_experimentation
      }

      ResearchRegistry.register_program(program)
      programs = ResearchRegistry.get_all_programs()

      assert is_list(programs)
      assert Enum.all?(programs, &is_map/1)
      refute Enum.any?(programs, &(Map.get(&1, :id) in ["prog_healthy", "prog_echo_chamber"]))
      assert Enum.any?(programs, &(Map.get(&1, :name) == "Transfer Physics"))
    end

    test "registered genomes round-trip through the reader" do
      genome = %ResearchGenome{domain: :meta_science, methodology: :evolution}
      ResearchRegistry.register_program(genome)

      programs = ResearchRegistry.get_all_programs()

      assert Enum.any?(
               programs,
               &(Map.get(&1, :domain) == :meta_science and
                   Map.get(&1, :methodology) == :evolution)
             )
    end

    test "fixture programs are never registered in state" do
      state = ResearchRegistry.get_programs()

      refute Map.has_key?(state, "prog_healthy")
      refute Map.has_key?(state, "prog_echo_chamber")
      refute Enum.any?(Map.values(state), &(Map.get(&1, :id) in ["prog_healthy", "prog_echo_chamber"]))
    end
  end

  describe "echo_chamber?/1 (scan A4)" do
    test "flags self-reported high-citation programs" do
      assert PathogenScanner.echo_chamber?(
               %{
                 id: "prog_echo",
                 name: "Quantum Theory 88",
                 internal_citation_ratio: 0.95,
                 laws_generated: 12
               }
             )
    end

    test "does not flag low citation ratios or too few laws" do
      refute PathogenScanner.echo_chamber?(
               %{id: "p1", internal_citation_ratio: 0.1, laws_generated: 2}
             )

      refute PathogenScanner.echo_chamber?(
               %{id: "p2", internal_citation_ratio: 0.95, laws_generated: 3}
             )
    end

    test "programs that do not report the metric are not evaluable and not flagged" do
      refute PathogenScanner.echo_chamber?(
               %ResearchProgram{name: "Transfer Physics", domain: :transfer_physics}
             )

      refute PathogenScanner.echo_chamber?(%ResearchGenome{domain: :transfer_physics})
      refute PathogenScanner.echo_chamber?(%{id: "no_ratio", laws_generated: 99})
    end
  end
end
