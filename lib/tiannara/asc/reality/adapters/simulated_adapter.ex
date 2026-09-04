defmodule Tiannara.ASC.Reality.Adapters.SimulatedAdapter do
  use GenServer

  alias Tiannara.ASC.Reality.PhysicalAdapter

  @behaviour PhysicalAdapter

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl PhysicalAdapter
  def capabilities do
    %{
      hardware: :simulated,
      supported_actions: [:initialize, :calibrate, :run_diagnostics, :deploy_firmware, :actuate],
      max_concurrent_actions: 3,
      estop_supported: true
    }
  end

  @impl PhysicalAdapter
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl PhysicalAdapter
  def execute_action(action) do
    GenServer.call(__MODULE__, {:execute_action, action})
  end

  @impl PhysicalAdapter
  def emergency_stop do
    GenServer.call(__MODULE__, :emergency_stop)
  end

  def clear_estop do
    GenServer.call(__MODULE__, :clear_estop)
  end

  @impl true
  def init(:ok) do
    {:ok, %{mode: :idle, active: false, executed_actions: [], estop_count: 0, last_action: nil}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply,
     %{
       mode: state.mode,
       active: state.active,
       executed_actions: length(state.executed_actions),
       estop_count: state.estop_count
     }, state}
  end

  def handle_call({:execute_action, action}, _from, state) do
    if state.mode == :estop do
      {:reply, {:error, :estop_active}, state}
    else
      new_state = %{
        state
        | active: true,
          executed_actions: [action | state.executed_actions],
          last_action: action
      }

      {:reply, {:ok, %{action: action, result: :success, timestamp: DateTime.utc_now()}},
       new_state}
    end
  end

  def handle_call(:emergency_stop, _from, state) do
    {:reply, :ok, %{state | mode: :estop, active: false, estop_count: state.estop_count + 1}}
  end

  def handle_call(:clear_estop, _from, state) do
    {:reply, :ok, %{state | mode: :idle, active: false}}
  end
end
