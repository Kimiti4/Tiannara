defmodule ObservationBus.CIL.Ops.OperationalReplay do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_events, do: GenServer.call(__MODULE__, :list)
  def replay(operation_id), do: GenServer.call(__MODULE__, {:replay, operation_id})

  @impl true
  def init(_opts) do
    events = [
      %{operation_id: "op_1", action: "proposed", timestamp: DateTime.add(DateTime.utc_now(), -86400, :second), actor: :planner},
      %{operation_id: "op_1", action: "simulated", timestamp: DateTime.add(DateTime.utc_now(), -82800, :second), result: :passed, actor: :authorization},
      %{operation_id: "op_1", action: "approved", timestamp: DateTime.add(DateTime.utc_now(), -79200, :second), actor: :constitution},
      %{operation_id: "op_1", action: "executed", timestamp: DateTime.add(DateTime.utc_now(), -75600, :second), result: :success, actor: :orchestrator},
      %{operation_id: "op_1", action: "verified", timestamp: DateTime.add(DateTime.utc_now(), -72000, :second), result: :passed, actor: :safety},
      %{operation_id: "op_2", action: "proposed", timestamp: DateTime.add(DateTime.utc_now(), -43200, :second), actor: :planner},
      %{operation_id: "op_2", action: "approved", timestamp: DateTime.add(DateTime.utc_now(), -39600, :second), actor: :constitution},
      %{operation_id: "op_3", action: "proposed", timestamp: DateTime.add(DateTime.utc_now(), -21600, :second), actor: :planner},
      %{operation_id: "op_3", action: "executing", timestamp: DateTime.add(DateTime.utc_now(), -18000, :second), actor: :orchestrator},
    ]
    {:ok, %{events: events}}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.events, state}
  def handle_call({:replay, operation_id}, _from, state) do
    events = Enum.filter(state.events, &(&1.operation_id == operation_id))
    {:reply, events, state}
  end
end
