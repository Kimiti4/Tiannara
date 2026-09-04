defmodule Tiannara.ASC.Research.ResearchRegistry do
  @moduledoc """
  Phase 11: Stub for ResearchRegistry.
  """
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def register_program(program) do
    GenServer.call(__MODULE__, {:register, program})
  end

  def handle_call({:register, program}, _from, state) do
    prog_id = "program_#{program.domain}"
    Logger.info("📚 [ResearchRegistry] Registered new research program for domain: #{program.domain}")
    updated = Map.put(state, prog_id, program)
    {:reply, prog_id, updated}
  end

  # Phase 16 Stubs
  def get_all_programs do
    # Simulated mock programs to test Immune System (Epistemic Closure)
    [
      %{id: "prog_healthy", name: "Network Optimization", internal_citation_ratio: 0.1, laws_generated: 2},
      %{id: "prog_echo_chamber", name: "Quantum Theory 88", internal_citation_ratio: 0.95, laws_generated: 12}
    ]
  end

  def freeze_program(prog_id) do
    Logger.warning("🧊 [ResearchRegistry] Program #{prog_id} frozen by Immune System. Budget reduced to 0.")
  end

  def update_program_metrics(_program_id, _metrics), do: :ok
  def allocate_resources(budget) do
    programs = get_programs_by_fitness()
    case programs do
      [] -> %{}
      list ->
        count = length(list)
        per_prog = div(budget, count)
        Map.new(list, fn p -> {p.id, per_prog} end)
    end
  end

  def get_programs do
    GenServer.call(__MODULE__, :get_programs)
  end

  def get_programs_by_fitness do
    case GenServer.call(__MODULE__, :get_programs) do
      prog_map when prog_map == %{} -> []
      prog_map ->
        prog_map
        |> Map.values()
        |> Enum.sort_by(& &1.program_fitness, :desc)
    end
  end

  def handle_call(:get_programs, _from, state), do: {:reply, state, state}

  def get_surviving_genomes, do: []
  def apply_engineering_roi(_program_id, _roi), do: {:ok, :stub}
  def store_surviving_genomes(_genomes), do: {:ok, :stub}
end
