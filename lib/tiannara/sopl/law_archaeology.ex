defmodule Tiannara.SOPL.LawRuin do
  @moduledoc "Captures the footprint of a collapsed or outperformed LawGenome."
  defstruct [
    :id,
    :law_genome,
    :fitness_history,
    :collapse_signature,
    :produced_species,
    :produced_discoveries,
    :produced_diseases,
    :archived_at
  ]
end

defmodule Tiannara.SOPL.LawArchaeology do
  @moduledoc """
  SOPL-1: Law Archaeology
  
  Extinction does not mean forgetting. When a LawGenome is outperformed,
  we store its ruin. In future phases (SOPL-3 Law Recombination), these 
  historical laws can be rediscovered and recombined.
  """
  
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  
  def init(_), do: {:ok, %{ruins: []}}

  def archive_ruin(%Tiannara.SOPL.LawRuin{} = ruin) do
    GenServer.cast(__MODULE__, {:archive, ruin})
  end

  def get_ruins, do: GenServer.call(__MODULE__, :get_ruins)

  def handle_cast({:archive, ruin}, state) do
    Logger.info("🏛️ [SOPL] Archived LawRuin for #{ruin.law_genome.id}. Collapse: #{ruin.collapse_signature}")
    {:noreply, %{state | ruins: [ruin | state.ruins]}}
  end

  def handle_call(:get_ruins, _from, state) do
    {:reply, state.ruins, state}
  end
end
