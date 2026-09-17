defmodule TelemetryGateway.EventSequencer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def next_sequence do
    GenServer.call(__MODULE__, :next)
  end

  def assign(event) do
    GenServer.call(__MODULE__, {:assign, event})
  end

  @impl true
  def init(_opts) do
    {:ok, %{counter: 0}}
  end

  @impl true
  def handle_call(:next, _from, %{counter: c} = state) do
    {:reply, c + 1, %{state | counter: c + 1}}
  end

  @impl true
  def handle_call({:assign, event}, _from, %{counter: c} = state) do
    seq = c + 1

    ordered =
      Map.put(event, :sequence_number, seq)
      |> Map.put(:global_index, "#{System.system_time(:millisecond)}-#{seq}")

    {:reply, ordered, %{state | counter: seq}}
  end
end
