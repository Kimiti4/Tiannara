defmodule TiannaraRuntime.NATS.Publisher do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    state = %{
      published_count: 0,
      buffer: []
    }
    {:ok, state}
  end

  def publish(subject, payload) when is_binary(subject) do
    GenServer.cast(__MODULE__, {:publish, subject, payload})
  end

  @impl true
  def handle_cast({:publish, subject, payload}, state) do
    TiannaraRuntime.NATS.Bus.publish(subject, payload)
    new_state = %{state | published_count: state.published_count + 1}
    {:noreply, new_state}
  end
end
