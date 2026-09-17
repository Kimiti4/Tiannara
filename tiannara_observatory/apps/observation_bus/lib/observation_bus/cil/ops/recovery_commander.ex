defmodule ObservationBus.CIL.Ops.RecoveryCommander do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def status, do: GenServer.call(__MODULE__, :status)
  def rollback(operation_id), do: GenServer.cast(__MODULE__, {:rollback, operation_id})
  def recover(target), do: GenServer.cast(__MODULE__, {:recover, target})

  @impl true
  def init(_opts) do
    state = %{
      recovery_capability: :automatic,
      recovery_history: [
        %{id: "rc_1", operation: "op_1", type: :rollback, status: :completed, duration_seconds: 45, recovered_at: DateTime.add(DateTime.utc_now(), -3600, :second)},
        %{id: "rc_2", operation: "cluster_b", type: :state_recovery, status: :completed, duration_seconds: 120, recovered_at: DateTime.add(DateTime.utc_now(), -7200, :second)},
      ],
      active_recoveries: [],
      rollback_capability: true,
      state_recovery_capability: true,
      mission_recovery_capability: true,
      cluster_recovery_capability: true
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast({:rollback, operation_id}, state) do
    recovery = %{id: "rc_#{length(state.recovery_history) + 1}", operation: operation_id, type: :rollback, status: :initiated, duration_seconds: nil, recovered_at: DateTime.utc_now()}
    {:noreply, %{state | active_recoveries: [recovery | state.active_recoveries]}}
  end

  def handle_cast({:recover, target}, state) do
    recovery = %{id: "rc_#{length(state.recovery_history) + 1}", operation: target, type: :state_recovery, status: :initiated, duration_seconds: nil, recovered_at: DateTime.utc_now()}
    {:noreply, %{state | active_recoveries: [recovery | state.active_recoveries]}}
  end
end
