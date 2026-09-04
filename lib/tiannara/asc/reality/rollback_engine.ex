defmodule Tiannara.ASC.Reality.RollbackEngine do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def create_snapshot(deployment_id) do
    GenServer.call(__MODULE__, {:create_snapshot, deployment_id})
  end

  def rollback(deployment_id, point \\ :pre_deployment) do
    GenServer.call(__MODULE__, {:rollback, deployment_id, point})
  end

  def list_snapshots(deployment_id) do
    GenServer.call(__MODULE__, {:list_snapshots, deployment_id})
  end

  def get_rollback_history do
    GenServer.call(__MODULE__, :get_history)
  end

  @impl true
  def init(:ok) do
    {:ok, %{snapshots: %{}, rollbacks: [], state_checkpoints: %{}}}
  end

  @impl true
  def handle_call({:create_snapshot, deployment_id}, _from, state) do
    snapshot = %{
      id: "snap-#{:erlang.system_time(:millisecond)}",
      deployment_id: deployment_id,
      timestamp: DateTime.utc_now(),
      state_snapshot: capture_system_state(deployment_id),
      artefacts: [:runtime_config, :active_connections, :data_state],
      metadata: %{pre_deployment: true}
    }

    existing = Map.get(state.snapshots, deployment_id, [])
    {:reply, {:ok, snapshot},
     %{state | snapshots: Map.put(state.snapshots, deployment_id, [snapshot | existing])}}
  end

  def handle_call({:rollback, deployment_id, point}, _from, state) do
    snapshots = Map.get(state.snapshots, deployment_id, [])

    target_snapshot = case point do
      :pre_deployment -> List.last(snapshots)
      :latest -> List.first(snapshots)
      specific when is_map(specific) -> specific
      _ -> List.last(snapshots)
    end

    case target_snapshot do
      nil ->
        {:reply, {:error, :no_snapshot_available}, state}
      snapshot ->
        rollback_record = %{
          deployment_id: deployment_id,
          rolled_back_to: snapshot.id,
          timestamp: DateTime.utc_now(),
          status: :completed,
          restored_artefacts: snapshot.artefacts
        }

        {:reply, {:ok, rollback_record},
         %{state | rollbacks: [rollback_record | state.rollbacks]}}
    end
  end

  def handle_call({:list_snapshots, deployment_id}, _from, state) do
    {:reply, Map.get(state.snapshots, deployment_id, []), state}
  end

  def handle_call(:get_history, _from, state) do
    {:reply, state.rollbacks, state}
  end

  defp capture_system_state(deployment_id) do
    %{
      id: deployment_id,
      captured_at: DateTime.utc_now(),
      version: :erlang.system_time(:second)
    }
  end
end
