defmodule Tiannara.ASC.Reality.StagedRolloutManager do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def plan(deployment_id, artifact, target, params \\ %{}) do
    GenServer.call(__MODULE__, {:plan, deployment_id, artifact, target, params})
  end

  def advance_ring(deployment_id) do
    GenServer.call(__MODULE__, {:advance_ring, deployment_id})
  end

  def pause_rollout(deployment_id) do
    GenServer.call(__MODULE__, {:pause, deployment_id})
  end

  def resume_rollout(deployment_id) do
    GenServer.call(__MODULE__, {:resume, deployment_id})
  end

  def get_status(deployment_id) do
    GenServer.call(__MODULE__, {:status, deployment_id})
  end

  @impl true
  def init(:ok) do
    {:ok, %{rollouts: %{}, ring_progress: %{}}}
  end

  @impl true
  def handle_call({:plan, deployment_id, artifact, target, params}, _from, state) do
    rings = case target do
      :digital -> [:canary_1_percent, :canary_5_percent, :regional_20_percent, :global_100_percent]
      :physical -> [:test_lab, :pilot_facility, :regional_rollout, :general_availability]
      _ -> [:canary_1_percent, :canary_5_percent, :global_100_percent]
    end

    rollout_speed = params[:rollout_speed] || :gradual
    gate_criteria = case rollout_speed do
      :fast -> %{min_uptime_hours: 1, max_error_rate: 0.05, min_health_score: 0.8}
      :gradual -> %{min_uptime_hours: 24, max_error_rate: 0.01, min_health_score: 0.95}
      :conservative -> %{min_uptime_hours: 72, max_error_rate: 0.001, min_health_score: 0.99}
    end

    plan = %{
      deployment_id: deployment_id,
      artifact: artifact,
      target: target,
      rings: rings,
      current_ring: hd(rings),
      status: :planned,
      gate_criteria: gate_criteria,
      rollout_speed: rollout_speed,
      progress: %{completed_rings: [], current_ring_index: 0, total_rings: length(rings)},
      timeline: %{
        planned_start: DateTime.utc_now(),
        estimated_duration_hours: length(rings) * 24
      }
    }

    {:reply, {:ok, plan},
     %{state | rollouts: Map.put(state.rollouts, deployment_id, plan)}}
  end

  def handle_call({:advance_ring, deployment_id}, _from, state) do
    case Map.get(state.rollouts, deployment_id) do
      nil -> {:reply, {:error, :not_found}, state}
      rollout ->
        current_idx = rollout.progress.current_ring_index
        total = rollout.progress.total_rings

        if current_idx + 1 >= total do
          completed = %{rollout | status: :completed,
            progress: %{rollout.progress | completed_rings: rollout.rings}}
          {:reply, {:ok, :already_complete, completed},
           %{state | rollouts: Map.put(state.rollouts, deployment_id, completed)}}
        else
          next_idx = current_idx + 1
          completed_rings = [Enum.at(rollout.rings, current_idx) | rollout.progress.completed_rings]
          updated = %{rollout |
            current_ring: Enum.at(rollout.rings, next_idx),
            progress: %{rollout.progress |
              completed_rings: completed_rings,
              current_ring_index: next_idx}
          }
          {:reply, {:ok, updated.current_ring, updated},
           %{state | rollouts: Map.put(state.rollouts, deployment_id, updated)}}
        end
    end
  end

  def handle_call({:pause, deployment_id}, _from, state) do
    case Map.get(state.rollouts, deployment_id) do
      nil -> {:reply, {:error, :not_found}, state}
      rollout ->
        updated = %{rollout | status: :paused}
        {:reply, {:ok, updated}, %{state | rollouts: Map.put(state.rollouts, deployment_id, updated)}}
    end
  end

  def handle_call({:resume, deployment_id}, _from, state) do
    case Map.get(state.rollouts, deployment_id) do
      nil -> {:reply, {:error, :not_found}, state}
      rollout ->
        updated = %{rollout | status: :in_progress}
        {:reply, {:ok, updated}, %{state | rollouts: Map.put(state.rollouts, deployment_id, updated)}}
    end
  end

  def handle_call({:status, deployment_id}, _from, state) do
    {:reply, Map.get(state.rollouts, deployment_id), state}
  end
end
