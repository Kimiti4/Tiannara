defmodule ObservatoryCore.Lifecycle.StateMachine do
  @moduledoc """
  Observable lifecycle state machine.

  States: initializing → booting → validating → recovering → operational →
          degraded → maintenance → certification → shutdown → archived

  Every transition emits telemetry.
  """

  use GenServer

  @valid_transitions %{
    initializing: [:booting],
    booting: [:validating, :recovering],
    validating: [:operational, :recovering],
    recovering: [:validating, :operational],
    operational: [:degraded, :maintenance, :certification, :shutdown],
    degraded: [:operational, :maintenance, :shutdown],
    maintenance: [:operational, :shutdown],
    certification: [:operational, :degraded, :shutdown],
    shutdown: [:archived],
    archived: []
  }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def transition(to) do
    GenServer.call(__MODULE__, {:transition, to})
  end

  def state, do: GenServer.call(__MODULE__, :state)

  @impl true
  def init(_opts) do
    emit(:initialized, %{from: nil, to: :initializing})
    {:ok, %{current: :initializing, history: []}}
  end

  @impl true
  def handle_call({:transition, to}, _from, %{current: from} = state) do
    allowed = Map.get(@valid_transitions, from, [])

    if to in allowed do
      emit(:transition, %{from: from, to: to})
      new_history = [%{from: from, to: to, at: DateTime.utc_now()} | state.history]
      {:reply, :ok, %{state | current: to, history: new_history}}
    else
      emit(:invalid_transition, %{from: from, to: to})
      {:reply, {:error, :invalid_transition}, state}
    end
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state.current, state}
  end

  defp emit(event, metadata) do
    :telemetry.execute([:observatory, :lifecycle, event], %{}, metadata)
  end
end
