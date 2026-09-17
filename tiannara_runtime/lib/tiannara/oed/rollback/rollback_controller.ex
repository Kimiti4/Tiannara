defmodule Tiannara.OED.Rollback.RollbackController do
  @moduledoc """
  🔄 Ontological Rollback Subsystem Controller.

  Coordinates rollback sequences to stable checkpoints if active reality
  experiences stability depletion or compromise.
  """

  use GenServer
  require Logger

  alias Tiannara.OED.Rollback.{OntologySnapshots, CausalReversal, ReintegrationGuard}

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Triggers a full reality rollback for a specific subsystem rule type.
  """
  @spec trigger_rollback(rule_type :: atom(), reason :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def trigger_rollback(rule_type, reason) do
    GenServer.call(__MODULE__, {:trigger_rollback, rule_type, reason})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    # Start snapshots and guards as child tasks or ensure they are active
    {:ok, %{}}
  end

  @impl true
  def handle_call({:trigger_rollback, rule_type, reason}, _from, state) do
    Logger.error("🚨 [Rollback Controller] TRIGGERING EMERGENCY ROLLBACK on #{rule_type} (reason: #{reason})")

    result =
      with {:ok, snapshot} <- OntologySnapshots.get_latest_snapshot(rule_type),
           :ok <- CausalReversal.reverse_timeline_split(rule_type),
           :ok <- ReintegrationGuard.assert_reintegration_safety(snapshot) do
        {:ok, snapshot}
      end

    {:reply, result, state}
  end
end
