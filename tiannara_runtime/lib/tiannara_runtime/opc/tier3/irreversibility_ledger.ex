defmodule Tiannara.OPC.Tier3.IrreversibilityLedger do
  @moduledoc """
  Tier 3 OPC: Irreversibility Ledger.
  
  An append-only ontology log that serves as the Exploit Lineage Memory.
  Stores the structure of irreversible mutations and adversarial attacks,
  allowing the Meta-Ecology to remember exploits and adapt immune responses.
  """
  
  use GenServer
  require Logger
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Commits a mutation to the lineage memory.
  """
  def record_mutation(mutation, meta \\ %{}) do
    GenServer.call(__MODULE__, {:record, mutation, meta})
  end
  
  @doc """
  Retrieves all known mutations of a given type.
  """
  def get_lineage(type) do
    GenServer.call(__MODULE__, {:get_lineage, type})
  end
  
  # ── GenServer Callbacks ───────────────────────────────────────────────────
  
  @impl true
  def init(_opts) do
    Logger.info("📚 [Tier 3 Ledger] Irreversibility Ledger initialized. Tracking permanent reality commits.")
    {:ok, []}
  end
  
  @impl true
  def handle_call({:record, mutation, meta}, _from, state) do
    Logger.info("📜 [Tier 3 Ledger] Appending mutation #{mutation.id} to immutable lineage.")
    entry = %{
      timestamp: System.os_time(:second),
      mutation: mutation,
      metadata: meta
    }
    
    {:reply, :ok, [entry | state]}
  end
  
  @impl true
  def handle_call({:get_lineage, type}, _from, state) do
    filtered = Enum.filter(state, fn entry -> entry.mutation.type == type end)
    {:reply, filtered, state}
  end
end
