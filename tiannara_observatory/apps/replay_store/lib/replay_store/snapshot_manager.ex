defmodule ReplayStore.SnapshotManager do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_full(domain, data, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:create_full, domain, data, metadata})
  end

  def create_incremental(domain, base_id, delta) do
    GenServer.call(__MODULE__, {:create_incremental, domain, base_id, delta})
  end

  def get(snapshot_id) do
    GenServer.call(__MODULE__, {:get, snapshot_id})
  end

  def list_by_domain(domain) do
    GenServer.call(__MODULE__, {:list, domain})
  end

  def verify(snapshot_id) do
    GenServer.call(__MODULE__, {:verify, snapshot_id})
  end

  @impl true
  def init(_opts) do
    {:ok,
     %{
       snapshots: %{},
       domain_index: %{},
       compression_stats: %{total_bytes: 0, compressed_bytes: 0}
     }}
  end

  @impl true
  def handle_call({:create_full, domain, data, metadata}, _from, state) do
    id = Ecto.UUID.generate()
    binary = :erlang.term_to_binary(data)
    compressed = :zlib.gzip(binary)
    checksum = :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)

    snapshot = %{
      id: id,
      domain: domain,
      type: :full,
      generation: next_generation(domain, state),
      data: data,
      binary_size: byte_size(binary),
      compressed_size: byte_size(compressed),
      compression_ratio:
        if(byte_size(binary) > 0,
          do: Float.round(byte_size(compressed) / byte_size(binary), 4),
          else: 1.0
        ),
      checksum: checksum,
      integrity_hash: compute_integrity_hash(id, domain, checksum),
      constitution_version: Shared.Constants.constitution_version(),
      metadata: Map.merge(metadata, %{created_at: DateTime.utc_now()}),
      timestamp: DateTime.utc_now()
    }

    {:reply, {:ok, snapshot}, put_snapshot(state, snapshot)}
  end

  @impl true
  def handle_call({:create_incremental, domain, base_id, delta}, _from, state) do
    case Map.get(state.snapshots, base_id) do
      nil ->
        {:reply, {:error, :base_snapshot_not_found}, state}

      base ->
        id = Ecto.UUID.generate()
        binary = :erlang.term_to_binary(delta)
        compressed = :zlib.gzip(binary)

        snapshot = %{
          id: id,
          domain: domain,
          type: :incremental,
          base_id: base_id,
          generation: base.generation + 1,
          data: delta,
          binary_size: byte_size(binary),
          compressed_size: byte_size(compressed),
          compression_ratio:
            if(byte_size(binary) > 0,
              do: Float.round(byte_size(compressed) / byte_size(binary), 4),
              else: 1.0
            ),
          checksum: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower),
          integrity_hash: compute_integrity_hash(id, domain, base.checksum),
          constitution_version: Shared.Constants.constitution_version(),
          timestamp: DateTime.utc_now()
        }

        {:reply, {:ok, snapshot}, put_snapshot(state, snapshot)}
    end
  end

  @impl true
  def handle_call({:get, id}, _from, %{snapshots: s} = state) do
    {:reply, Map.get(s, id), state}
  end

  @impl true
  def handle_call({:list, domain}, _from, %{domain_index: idx} = state) do
    ids = Map.get(idx, domain, [])
    snapshots = Enum.map(ids, fn id -> Map.get(state.snapshots, id) end) |> Enum.reject(&is_nil/1)
    {:reply, snapshots, state}
  end

  @impl true
  def handle_call({:verify, id}, _from, %{snapshots: s} = state) do
    case Map.get(s, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      snap ->
        stored = snap.checksum
        binary = :erlang.term_to_binary(snap.data)
        computed = :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
        valid = stored == computed

        {:reply, %{id: id, valid: valid, stored_checksum: stored, computed_checksum: computed},
         state}
    end
  end

  defp next_generation(domain, state) do
    Map.get(state.domain_index, domain, [])
    |> List.first()
    |> then(fn
      nil ->
        1

      last_id ->
        case Map.get(state.snapshots, last_id) do
          nil -> 1
          s -> s.generation + 1
        end
    end)
  end

  defp put_snapshot(state, snapshot) do
    existing = Map.get(state.domain_index, snapshot.domain, [])

    updated_state = %{
      state
      | snapshots: Map.put(state.snapshots, snapshot.id, snapshot),
        domain_index: Map.put(state.domain_index, snapshot.domain, [snapshot.id | existing])
    }

    compression_stats = %{
      total_bytes: state.compression_stats.total_bytes + snapshot.binary_size,
      compressed_bytes: state.compression_stats.compressed_bytes + snapshot.compressed_size
    }

    %{updated_state | compression_stats: compression_stats}
  end

  defp compute_integrity_hash(id, domain, checksum) do
    :crypto.hash(
      :sha256,
      "#{id}:#{domain}:#{checksum}:#{Shared.Constants.constitution_version()}"
    )
    |> Base.encode16(case: :lower)
  end
end
