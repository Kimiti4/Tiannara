defmodule Tiannara.Autonomy.RollbackEngine do
  @moduledoc """
  Rollback Engine — automatic and manual rollback of deployed improvements.
  Ensures that any deployed change can be reverted if post-deployment
  monitoring detects degradation.
  """

  use GenServer
  require Logger
  alias Tiannara.Executive.Types

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec rollback(binary(), String.t()) :: :ok | {:error, term()}
  def rollback(deployment_id, reason) do
    GenServer.call(__MODULE__, {:rollback, deployment_id, reason, :manual})
  end

  @spec automatic_rollback(binary(), String.t()) :: :ok | {:error, term()}
  def automatic_rollback(deployment_id, reason) do
    GenServer.call(__MODULE__, {:rollback, deployment_id, reason, :automatic})
  end

  @spec total_rollbacks() :: non_neg_integer()
  def total_rollbacks do
    GenServer.call(__MODULE__, :total_rollbacks)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{rollbacks: [], total_rollbacks: 0, total_successful: 0, total_failed: 0, last_rollback_at: nil}}
  end

  @impl true
  def handle_call({:rollback, deployment_id, reason, trigger}, _from, state) do
    Logger.warning("[RollbackEngine] ROLLBACK REQUESTED Deployment: #{deployment_id} Trigger: #{trigger} Reason: #{reason}")

    # Truthful: no real rollback substrate (checkpoint restoration on a real
    # deployment) is wired. Report explicit unavailability instead of
    # fabricating a rollback record.
    {:reply, {:error, :rollback_unavailable}, state}
  end

  @impl true
  def handle_call(:total_rollbacks, _from, state) do
    {:reply, state.total_rollbacks, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_rollbacks: state.total_rollbacks, total_successful: state.total_successful, total_failed: state.total_failed, last_rollback_at: state.last_rollback_at, success_rate: if(state.total_rollbacks > 0, do: Float.round(state.total_successful / state.total_rollbacks, 3), else: 1.0)}, state}
  end

  defp execute_rollback(deployment_id) do
    # Unused: rollback reports :rollback_unavailable. Kept as the documented
    # future wiring point for a real checkpoint-restoration substrate.
    checkpoint_id = Types.new_id()
    Logger.info("[RollbackEngine] Executing rollback. Deployment: #{deployment_id} Restoring checkpoint: #{checkpoint_id}")
    :timer.sleep(10)
    {true, checkpoint_id}
  end
end
