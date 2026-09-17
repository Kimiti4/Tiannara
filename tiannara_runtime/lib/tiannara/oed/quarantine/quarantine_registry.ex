defmodule Tiannara.OED.Quarantine.QuarantineRegistry do
  @moduledoc """
  🗃️ Quarantine Subsystem Quarantine Registry.

  Manages indexing and lookup of suspended configuration rules and theories
  segregated from active execution pipelines.
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a theory into the quarantine index.
  """
  @spec quarantine(theory :: map(), reason :: String.t()) :: :ok
  def quarantine(theory, reason) do
    GenServer.call(__MODULE__, {:quarantine, theory, reason})
  end

  @doc """
  Lists all currently quarantined theories.
  """
  @spec list_quarantined() :: [map()]
  def list_quarantined do
    GenServer.call(__MODULE__, :list_quarantined)
  end

  @doc """
  Removes a theory from the quarantine registry after rehabilitation or deletion.
  """
  @spec release(id :: atom()) :: :ok
  def release(id) do
    GenServer.call(__MODULE__, {:release, id})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:quarantine, theory, reason}, _from, state) do
    id = theory.type
    record = %{theory: theory, reason: reason, timestamp: System.system_time(:millisecond)}
    new_state = Map.put(state, id, record)
    Logger.warning("🗃️ [Quarantine Registry] Quarantined theory #{id} (reason: #{reason})")
    {:reply, :ok, new_state}
  end

  def handle_call(:list_quarantined, _from, state) do
    records = Map.values(state)
    {:reply, records, state}
  end

  def handle_call({:release, id}, _from, state) do
    new_state = Map.delete(state, id)
    Logger.info("🗃️ [Quarantine Registry] Released theory #{id} from quarantine")
    {:reply, :ok, new_state}
  end
end
