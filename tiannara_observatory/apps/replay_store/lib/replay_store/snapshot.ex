defmodule ReplayStore.Snapshot do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create(domain, data) do
    GenServer.call(__MODULE__, {:create, domain, data})
  end

  def get(snapshot_id) do
    GenServer.call(__MODULE__, {:get, snapshot_id})
  end

  @impl true
  def init(_opts) do
    {:ok, %{snapshots: %{}}}
  end

  @impl true
  def handle_call({:create, domain, data}, _from, %{snapshots: s} = state) do
    id = Ecto.UUID.generate()

    snapshot = %{
      id: id,
      domain: domain,
      data: data,
      timestamp: DateTime.utc_now(),
      checksum: :erlang.md5(:erlang.term_to_binary(data))
    }

    {:reply, {:ok, id}, %{state | snapshots: Map.put(s, id, snapshot)}}
  end

  @impl true
  def handle_call({:get, id}, _from, %{snapshots: s} = state) do
    {:reply, Map.get(s, id), state}
  end
end
