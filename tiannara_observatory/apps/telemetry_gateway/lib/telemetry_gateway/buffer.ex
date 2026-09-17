defmodule TelemetryGateway.Buffer do
  use GenServer

  @max_size 10_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def push(event) do
    GenServer.cast(__MODULE__, {:push, event})
  end

  def pop(count \\ 100) do
    GenServer.call(__MODULE__, {:pop, count})
  end

  def size do
    GenServer.call(__MODULE__, :size)
  end

  @impl true
  def init(_opts) do
    {:ok, %{buffer: :queue.new(), size: 0}}
  end

  @impl true
  def handle_cast({:push, event}, %{buffer: buf, size: s} = state) do
    if s < @max_size do
      {:noreply, %{state | buffer: :queue.in(event, buf), size: s + 1}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_call({:pop, count}, _from, %{buffer: buf, size: s} = state) do
    {popped, remaining} = do_pop(buf, count, [])
    {:reply, popped, %{state | buffer: remaining, size: max(s - length(popped), 0)}}
  end

  @impl true
  def handle_call(:size, _from, %{size: s} = state) do
    {:reply, s, state}
  end

  defp do_pop(queue, 0, acc), do: {Enum.reverse(acc), queue}

  defp do_pop(queue, _n, acc) do
    case :queue.out(queue) do
      {{:value, item}, rest} -> do_pop(rest, 0, [item | acc])
      {:empty, queue} -> {Enum.reverse(acc), queue}
    end
  end
end
