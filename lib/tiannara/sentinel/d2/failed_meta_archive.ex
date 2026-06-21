defmodule Tiannara.Sentinel.D2.FailedMetaOperator do
  @moduledoc "Record of a failed meta-operator."
  defstruct [
    :operator_set,
    :failure_reason,
    :acm_vulnerability,
    :collapse_signature,
    :predicted_fitness,
    :observed_fitness,
    :timestamp
  ]
end

defmodule Tiannara.Sentinel.D2.FailedMetaArchive do
  @moduledoc """
  Phase 9.75: The Shadow Archive.
  Graveyard for Meta-Operators that failed ESG validation or collapsed post-deployment.
  """
  use GenServer
  require Logger
  alias Tiannara.Sentinel.D2.FailedMetaOperator

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Records a failed meta-operator mutation."
  def record_failure(record = %FailedMetaOperator{}) do
    GenServer.cast(__MODULE__, {:record_failure, record})
  end

  @doc "Checks if an operator set has historically failed for similar reasons."
  def has_failed_before?(operator_set) do
    GenServer.call(__MODULE__, {:has_failed?, operator_set})
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting D.2 FailedMetaArchive")
    {:ok, %{failures: []}}
  end

  @impl true
  def handle_cast({:record_failure, record}, state) do
    Logger.debug("🪦 [FailedMetaArchive] Archiving failed meta-operator (Reason: #{record.failure_reason})")
    {:noreply, %{state | failures: [record | state.failures]}}
  end

  @impl true
  def handle_call({:has_failed?, signature}, _from, state) do
    # Check if this exact signature is in the graveyard
    found = Enum.any?(state.failures, fn f -> Enum.sort(f.operator_set) == Enum.sort(signature) end)
    {:reply, found, state}
  end
end
