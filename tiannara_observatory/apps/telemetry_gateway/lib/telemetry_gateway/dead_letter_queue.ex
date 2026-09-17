defmodule TelemetryGateway.DeadLetterQueue do
  use GenServer

  @max_entries 100_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def enqueue(event, reason, detail \\ nil) do
    GenServer.cast(__MODULE__, {:enqueue, event, reason, detail})
  end

  def list(opts \\ []) do
    GenServer.call(__MODULE__, {:list, opts})
  end

  def count do
    GenServer.call(__MODULE__, :count)
  end

  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  @impl true
  def init(_opts) do
    {:ok, %{entries: :queue.new(), count: 0}}
  end

  @impl true
  def handle_cast({:enqueue, event, reason, detail}, %{entries: q, count: c} = state) do
    if c < @max_entries do
      entry = %{
        id: Ecto.UUID.generate(),
        event_id: event[:id] || event.id,
        domain: event[:domain] || event.domain,
        reason: reason,
        detail: detail,
        payload: event[:payload] || event.payload,
        source: event[:source] || event.source,
        timestamp: DateTime.utc_now()
      }

      TelemetryGateway.TelemetryAuditor.record(:dead_letter, reason)

      {:noreply, %{state | entries: :queue.in(entry, q), count: c + 1}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:clear, _state) do
    {:noreply, %{entries: :queue.new(), count: 0}}
  end

  @impl true
  def handle_call({:list, _opts}, _from, %{entries: q} = state) do
    entries = :queue.to_list(q) |> Enum.reverse()
    {:reply, entries, state}
  end

  @impl true
  def handle_call(:count, _from, %{count: c} = state) do
    {:reply, c, state}
  end
end
