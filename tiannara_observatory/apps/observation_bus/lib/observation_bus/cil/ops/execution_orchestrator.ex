defmodule ObservationBus.CIL.Ops.ExecutionOrchestrator do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def status, do: GenServer.call(__MODULE__, :status)
  def execute(plan_id), do: GenServer.cast(__MODULE__, {:execute, plan_id})

  @impl true
  def init(_opts) do
    state = %{
      active_operations: [],
      execution_queue: ["op_3", "op_5"],
      completed: ["op_1"],
      failed: [],
      status: :operational,
      started_at: DateTime.utc_now()
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast({:execute, plan_id}, state) do
    queue = state.execution_queue ++ [plan_id]
    {:noreply, %{state | execution_queue: queue}}
  end
end
