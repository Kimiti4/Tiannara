defmodule Tiannara.Executive.ExecutiveMemory do
  @moduledoc """
  Executive Memory — the canonical DETS-backed knowledge store for the Tiannara ASC runtime.

  Provides a GenServer API for durable, auditable storage with:
  - ETS hot cache for fast reads
  - DETS persistent backing with corruption detection and auto-repair
  - Periodic flush (5 min), checkpoint (30 min), maintenance (15 min), GC (6 h)
  - Constitutional audit on every write
  - Fault injection hooks for testing
  - Telemetry on all operations
  """

  use GenServer

  require Logger

  alias Tiannara.Executive.{
    State,
    ETSCache,
    DetsStore,
    Recovery,
    Persistence,
    Migration,
    Snapshot,
    GC,
    Auditor,
    Telemetry,
    CorruptionDetector,
    Transaction,
    Lineage,
    Event,
    EventBus
  }

  @default_flush_interval 300_000
  @default_checkpoint_interval 1_800_000
  @default_maintenance_interval 900_000
  @default_gc_interval 21_600_000

  # ── Public API ──────────────────────────────────────────────

  @doc "Stores a value under the given key."
  def put(key, value, attrs \\ %{}) do
    GenServer.call(__MODULE__, {:put, key, value, attrs})
  end

  # Attrs arrive as a map by contract; a keyword list is accepted and
  # normalized so no caller can crash the auditor (:memory_class is
  # translated onto the contract key :class).
  defp normalize_attrs(attrs) when is_list(attrs) do
    attrs
    |> Map.new()
    |> normalize_attrs()
  end

  defp normalize_attrs(attrs) when is_map(attrs) do
    if Map.has_key?(attrs, :class) do
      attrs
    else
      Map.put_new(attrs, :class, Map.get(attrs, :memory_class, :operational))
    end
  end

  @doc "Retrieves the value for a key (from ETS cache, fallback to DETS)."
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @doc "Deletes a key from the store."
  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  @doc "Returns all keys in the store."
  def keys do
    GenServer.call(__MODULE__, :keys)
  end

  @doc "Returns the number of stored entries."
  def size do
    GenServer.call(__MODULE__, :size)
  end

  @doc "Flushes the ETS cache to DETS."
  def flush do
    GenServer.call(__MODULE__, :flush)
  end

  @doc "Returns a health check map."
  def health do
    GenServer.call(__MODULE__, :health)
  end

  @doc "Returns basic diagnostics."
  def diagnostics do
    GenServer.call(__MODULE__, :diagnostics)
  end

  @doc "Returns deep diagnostics (may be expensive)."
  def deep_diagnostics do
    GenServer.call(__MODULE__, :deep_diagnostics)
  end

  @doc "Returns current metrics."
  def metrics do
    GenServer.call(__MODULE__, :metrics)
  end

  @doc "Attempts recovery of the store."
  def recover do
    GenServer.call(__MODULE__, :recover)
  end

  @doc "Rebuilds the DETS store from scratch."
  def rebuild do
    GenServer.call(__MODULE__, :rebuild)
  end

  @doc "Compacts the DETS file to reclaim space."
  def compact do
    GenServer.call(__MODULE__, :compact)
  end

  @doc "Creates a point-in-time snapshot."
  def snapshot do
    GenServer.call(__MODULE__, :snapshot)
  end

  @doc "Runs garbage collection."
  def gc do
    GenServer.call(__MODULE__, :gc)
  end

  @doc "Injects a fault for testing."
  def inject_fault(type, config) do
    GenServer.call(__MODULE__, {:inject_fault, type, config})
  end

  @doc "Clears all injected faults."
  def clear_faults do
    GenServer.call(__MODULE__, :clear_faults)
  end

  # ── GenServer callbacks ─────────────────────────────────────

  @impl true
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    dets_dir = Keyword.get(opts, :dets_dir, "/tmp/tiannara/executive_memory")
    dets_file = Keyword.get(opts, :dets_file, Path.join(dets_dir, "executive_memory.dets"))
    snapshot_dir = Keyword.get(opts, :snapshot_dir, Path.join(dets_dir, "snapshots"))
    flush_interval = Keyword.get(opts, :flush_interval, @default_flush_interval)
    checkpoint_interval = Keyword.get(opts, :checkpoint_interval, @default_checkpoint_interval)
    maintenance_interval = Keyword.get(opts, :maintenance_interval, @default_maintenance_interval)
    gc_interval = Keyword.get(opts, :gc_interval, @default_gc_interval)

    File.mkdir_p!(dets_dir)
    File.mkdir_p!(snapshot_dir)

    state =
      State.new(
        name: name,
        dets_file: dets_file,
        dets_dir: dets_dir,
        snapshot_dir: snapshot_dir,
        flush_interval: flush_interval,
        checkpoint_interval: checkpoint_interval,
        maintenance_interval: maintenance_interval,
        gc_interval: gc_interval
      )

    state = startup(state)
    {:ok, state}
  end

  @impl true
  def handle_call({:put, key, value, attrs}, _from, state) do
    state = maybe_inject_fault(:write_failure, state)
    attrs = normalize_attrs(attrs)

    audit_result = Auditor.audit(key, attrs)

    case audit_result do
      :ok ->
        lineage = Map.get(attrs, :lineage, Lineage.new("system", :hypothesis))
        class = Map.get(attrs, :class, :operational)

        entry = %{
          value: value,
          lineage: lineage,
          class: class,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }

        ETSCache.put(state.name, key, entry)
        :dets.insert(state.dets_ref, {key, entry})

        tx = Transaction.begin(key, nil, entry, :put, attrs)
        :dets.insert(state.dets_ref, Transaction.to_record(tx))

        event = Event.new("memory.put", %{key: key, class: class})
        EventBus.publish(event)

        state = State.increment_metric(state, :total_writes)
        Telemetry.emit_write(state.name, :ok)
        {:reply, :ok, state}

      {:error, reason} ->
        Telemetry.emit_write(state.name, {:error, reason})
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    state = maybe_inject_fault(:read_delay, state)
    state = State.increment_metric(state, :total_reads)

    case ETSCache.get(state.name, key) do
      {:ok, entry} ->
        Telemetry.emit_read(state.name, :ok)
        {:reply, {:ok, entry}, state}

      :error ->
        case DetsStore.lookup(state.dets_ref, key) do
          {:ok, entry} ->
            ETSCache.put(state.name, key, entry)
            Telemetry.emit_read(state.name, :ok)
            {:reply, {:ok, entry}, state}

          :error ->
            Telemetry.emit_read(state.name, :error)
            {:reply, :error, state}
        end
    end
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    ETSCache.delete(state.name, key)
    :dets.delete(state.dets_ref, key)

    tx = Transaction.begin(key, nil, nil, :delete)
    :dets.insert(state.dets_ref, Transaction.to_record(tx))

    event = Event.new("memory.delete", %{key: key})
    EventBus.publish(event)

    state = State.increment_metric(state, :total_deletes)
    Telemetry.emit_delete(state.name, :ok)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:keys, _from, state) do
    dets_keys = DetsStore.keys(state.dets_ref)
    ets_keys = ETSCache.keys(state.name)
    {:reply, Enum.uniq(dets_keys ++ ets_keys), state}
  end

  @impl true
  def handle_call(:size, _from, state) do
    {:reply, DetsStore.count(state.dets_ref), state}
  end

  @impl true
  def handle_call(:flush, _from, state) do
    state = Persistence.flush(state)
    state = put_in(state.last_flush, DateTime.utc_now())
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:health, _from, state) do
    info = DetsStore.info(state.dets_ref)
    ets_size = ETSCache.size(state.name)

    health = %{
      status: state.status,
      dets_size: elem(info, 0),
      dets_record_count: elem(info, 1),
      cache_size: ets_size,
      corruption_detected: state.corruption_detected,
      last_flush: state.last_flush,
      last_checkpoint: state.last_checkpoint,
      last_maintenance: state.last_maintenance,
      last_gc: state.last_gc,
      metrics: state.metrics,
      fault_injection_enabled: state.fault_injection.enabled,
      timestamp: DateTime.utc_now()
    }

    Telemetry.emit_health(state.status)
    {:reply, health, state}
  end

  @impl true
  def handle_call(:diagnostics, _from, state) do
    info = DetsStore.info(state.dets_ref)

    {:reply,
     %{
       status: state.status,
       dets_info: elem(info, 0),
       record_count: elem(info, 1),
       cache_size: ETSCache.size(state.name),
       corruption_detected: state.corruption_detected,
       last_flush: state.last_flush,
       last_checkpoint: state.last_checkpoint,
       last_maintenance: state.last_maintenance,
       last_gc: state.last_gc,
       fault_injection: state.fault_injection
     }, state}
  end

  @impl true
  def handle_call(:deep_diagnostics, _from, state) do
    dtst = DetsStore.info(state.dets_ref)
    deep_check = CorruptionDetector.deep_check(state.dets_ref)

    {:reply,
     %{
       dets_info: elem(dtst, 0),
       record_count: elem(dtst, 1),
       deep_check: deep_check,
       metrics: state.metrics,
       corruption_detected: state.corruption_detected
     }, state}
  end

  @impl true
  def handle_call(:metrics, _from, state) do
    {:reply, state.metrics, state}
  end

  @impl true
  def handle_call(:recover, _from, state) do
    Logger.info("[ExecutiveMemory] Manual recovery requested")

    # Close current DETS safely
    if state.dets_ref do
      DetsStore.close(state.dets_ref)
    end

    case Recovery.startup_recovery(state.dets_file) do
      {:ok, ref} ->
        Migration.migrate(ref)
        ETSCache.destroy(state.name)
        ets = ETSCache.create(state.name)
        state = %{state | dets_ref: ref, ets_table: ets, status: :active}
        state = State.record_recovery(state)
        Telemetry.emit_recovery()
        {:reply, :ok, state}

      {:error, reason} ->
        state = State.degrade(state, reason)
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:rebuild, _from, state) do
    Logger.warning("[ExecutiveMemory] Manual rebuild requested")
    if state.dets_ref, do: DetsStore.close(state.dets_ref)
    ETSCache.destroy(state.name)

    case Recovery.rebuild(state.dets_file) do
      {:ok, ref} ->
        Migration.migrate(ref)
        ets = ETSCache.create(state.name)
        state = %{state | dets_ref: ref, ets_table: ets, status: :active}
        state = State.record_recovery(state)
        Telemetry.emit_recovery()
        {:reply, :ok, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:compact, _from, state) do
    Logger.info("[ExecutiveMemory] Manual compaction requested")
    sizes = DetsStore.compact(state.dets_ref, state.dets_file)
    Telemetry.emit_compaction(state.name, sizes)
    state = State.increment_metric(state, :total_compactions)
    {:reply, {:ok, sizes}, state}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    snapshot_path = Snapshot.create(state.name, state.dets_ref, state.snapshot_dir)
    Snapshot.prune(state.snapshot_dir, 5)
    Telemetry.emit_snapshot_created()
    state = State.increment_metric(state, :snapshot_count)
    {:reply, {:ok, snapshot_path}, state}
  end

  @impl true
  def handle_call(:gc, _from, state) do
    Logger.info("[ExecutiveMemory] Manual GC requested")
    result = GC.run(state.name, state.dets_ref)

    # Rewarm ETS cache from DETS
    ETSCache.destroy(state.name)
    ets = ETSCache.create(state.name)

    DetsStore.fold(state.dets_ref, [], fn {k, v}, acc -> [{k, v} | acc] end)
    |> Enum.each(fn {k, v} -> ETSCache.put(state.name, k, v) end)

    state = %{state | ets_table: ets}
    state = State.increment_metric(state, :gc_runs)
    Telemetry.emit_gc(state.name)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:inject_fault, type, config}, _from, state) do
    new_config = Map.merge(state.fault_injection, config)
    state = State.enable_fault_injection(state, new_config)
    Logger.warning("[ExecutiveMemory] Fault injection enabled: #{type} #{inspect(config)}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:clear_faults, _from, state) do
    state = State.disable_fault_injection(state)
    Logger.info("[ExecutiveMemory] Fault injection cleared")
    {:reply, :ok, state}
  end

  # ── Periodic timers ─────────────────────────────────────────

  @impl true
  def handle_info(:flush, state) do
    Logger.info("[ExecutiveMemory] Periodic flush")
    state = Persistence.flush(state)

    state = %{
      state
      | last_flush: DateTime.utc_now(),
        flush_ref: schedule_flush(state.flush_interval)
    }

    {:noreply, state}
  end

  @impl true
  def handle_info(:checkpoint, state) do
    Logger.info("[ExecutiveMemory] Periodic checkpoint")
    state = Persistence.checkpoint(state)
    {:noreply, state}
  end

  @impl true
  def handle_info(:maintenance, state) do
    Logger.info("[ExecutiveMemory] Periodic maintenance")
    state = run_maintenance(state)

    state = %{
      state
      | last_maintenance: DateTime.utc_now(),
        maintenance_ref: schedule_maintenance(state.maintenance_interval)
    }

    {:noreply, state}
  end

  @impl true
  def handle_info(:gc, state) do
    Logger.info("[ExecutiveMemory] Periodic GC")
    GC.run(state.name, state.dets_ref)
    state = State.increment_metric(state, :gc_runs)
    state = %{state | last_gc: DateTime.utc_now(), gc_ref: schedule_gc(state.gc_interval)}
    Telemetry.emit_gc(state.name)
    {:noreply, state}
  end

  @impl true
  def handle_info(:check_integrity, state) do
    Logger.info("[ExecutiveMemory] Integrity check")
    check_result = CorruptionDetector.verify_table(state.dets_ref)

    unless check_result do
      Logger.error("[ExecutiveMemory] Integrity check failed!")
      state = State.record_corruption(state)
      {:noreply, state}
    end

    {:noreply, state}
  end

  # ── Termination ─────────────────────────────────────────────

  @impl true
  def terminate(reason, state) do
    Logger.info("[ExecutiveMemory] Shutting down: #{inspect(reason)}")

    if state.dets_ref do
      Persistence.checkpoint(state, :shutdown)
      DetsStore.close(state.dets_ref)
    end

    if state.ets_table do
      ETSCache.destroy(state.name)
    end

    Telemetry.emit_shutdown(reason)
    :ok
  end

  # ── Private helpers ─────────────────────────────────────────

  defp startup(state) do
    Logger.info("[ExecutiveMemory] Starting up: #{state.dets_file}")

    {dets_ref, status} =
      case Recovery.startup_recovery(state.dets_file) do
        {:ok, nil} ->
          Logger.info("[ExecutiveMemory] Starting fresh store")
          {:ok, ref} = DetsStore.open(state.dets_file)
          {ref, :active}

        {:ok, ref} ->
          Migration.migrate(ref)
          {ref, :active}

        {:error, _reason} ->
          Logger.error("[ExecutiveMemory] Could not open DETS, creating new")
          {:ok, ref} = DetsStore.open(state.dets_file)
          Migration.migrate(ref)
          {ref, :degraded}
      end

    ets = ETSCache.create(state.name)
    warm_from_dets(ets, dets_ref)

    state = %{state | dets_ref: dets_ref, ets_table: ets, status: status}

    state =
      if CorruptionDetector.deep_check(dets_ref).ok? do
        state
      else
        Logger.error("[ExecutiveMemory] Corruption detected during startup")
        State.record_corruption(state)
      end

    state = State.activate(state)

    state = %{
      state
      | flush_ref: schedule_flush(state.flush_interval),
        maintenance_ref: schedule_maintenance(state.maintenance_interval),
        gc_ref: schedule_gc(state.gc_interval)
    }

    Telemetry.emit_startup(:ok)
    Logger.info("[ExecutiveMemory] Startup complete: #{state.status}")

    event = Event.new("memory.ready", %{status: state.status})
    EventBus.publish(event)

    state
  end

  defp warm_from_dets(_ets, dets_ref) do
    try do
      DetsStore.fold(dets_ref, 0, fn {k, v}, count ->
        ETSCache.put(:tiannara_executive_memory, k, v)
        count + 1
      end)
    rescue
      _ -> Logger.warning("[ExecutiveMemory] Could not warm ETS cache from DETS")
    end
  end

  defp schedule_flush(interval), do: Process.send_after(self(), :flush, interval)
  defp schedule_maintenance(interval), do: Process.send_after(self(), :maintenance, interval)
  defp schedule_gc(interval), do: Process.send_after(self(), :gc, interval)

  defp run_maintenance(state) do
    Logger.info("[ExecutiveMemory] Running maintenance")

    if CorruptionDetector.verify_table(state.dets_ref) do
      deep_check = CorruptionDetector.deep_check(state.dets_ref)

      if deep_check.ok? do
        Logger.info(
          "[ExecutiveMemory] Maintenance: integrity OK (#{deep_check.valid}/#{deep_check.total})"
        )
      else
        Logger.error(
          "[ExecutiveMemory] Maintenance: corruption detected (#{deep_check.corrupt}/#{deep_check.total})"
        )

        state = State.record_corruption(state)
        Recovery.create_backup(state.dets_file)

        Tiannara.Executive.Telemetry.emit([:tiannara, :executive], :needs_repair, %{
          file: state.dets_file,
          corrupt: deep_check.corrupt,
          total: deep_check.total,
          detected_at: DateTime.utc_now()
        })
      end
    else
      Logger.error("[ExecutiveMemory] Maintenance: table verification failed")
    end

    Persistence.checkpoint(state, :maintenance)
    Snapshot.create(state.name, state.dets_ref, state.snapshot_dir)
    Snapshot.prune(state.snapshot_dir, 5)
    state
  end

  defp maybe_inject_fault(:read_delay, state) do
    if state.fault_injection.enabled do
      delay = Map.get(state.fault_injection, :read_delay_ms, 0)
      if delay > 0, do: Process.sleep(delay)
    end

    state
  end

  defp maybe_inject_fault(:write_failure, state) do
    if state.fault_injection.enabled do
      rate = Map.get(state.fault_injection, :write_failure_rate, 0)

      if rate > 0 and :rand.uniform() < rate do
        Telemetry.emit_write(state.name, {:error, :injected_fault})
        throw(:injected_write_failure)
      end
    end

    state
  end

  defp maybe_inject_fault(_, state), do: state
end
