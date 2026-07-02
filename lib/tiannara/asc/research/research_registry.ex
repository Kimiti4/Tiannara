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

  def register_program(genome) do
    GenServer.cast(__MODULE__, {:register, genome})
  end

  def handle_cast({:register, genome}, state) do
    Logger.info("📚 [ResearchRegistry] Registered new research program for domain: #{genome.domain}")
    {:noreply, state}
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
end
