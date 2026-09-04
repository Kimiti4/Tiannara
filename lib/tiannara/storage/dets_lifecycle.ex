defmodule Tiannara.Storage.DetsLifecycle do
  @moduledoc """
  Size-bound management for DETS-backed stores.

  DETS cannot shrink its own file (the ~2 GB ceiling is a format property),
  so every registered store is swept on an interval: a size metric is emitted
  for each, a warning fires at `:dets_warn_bytes` (default 1.5 GB), and
  rotation — run INSIDE the owning store's GenServer — is triggered at
  `:dets_rotate_bytes` (default 1.8 GB, before the wall). Optional TTL
  pruning runs at `:dets_prune_interval_ms` (default 6h).

  Store contract (each registered module MUST implement):
    - `dets_path/0` — path to the store file
    - `rotate/0`    — `GenServer.call(__MODULE__, :rotate)`; rotates in-process
    - `prune/0`     — `GenServer.call(__MODULE__, :prune)`; TTL hygiene

  Registration is best-effort: if the lifecycle is not running yet the
  registration is dropped and retried on the next sweep (stores re-register
  on every boot, so a missed registration is self-healing only if the sweep
  retries — see `register/1` retry via `sweep/1`).
  """

  use GenServer
  require Logger

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc "Registers a store (map with `:id` and `:module`) for lifecycle management."
  def register(store) do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, {:register, store})
    else
      {:error, :not_running}
    end
  end

  @doc "List of registered store ids."
  def registered, do: GenServer.call(__MODULE__, :registered)

  @doc "Removes a store (by id) from lifecycle management."
  def unregister(id) do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, {:unregister, id})
    else
      {:error, :not_running}
    end
  end

  @doc "Runs a sweep immediately (used by tests)."
  def sweep_now, do: GenServer.call(__MODULE__, :sweep_now)

  @impl true
  def init(_opts) do
    schedule_sweep()
    schedule_prune()
    {:ok, %{stores: %{}, warned: %{}, last_pruned: nil}}
  end

  @impl true
  def handle_call({:register, %{module: module} = store}, _from, state) do
    id = Map.get(store, :id, module)
    path = Map.get(store, :path) || module.dets_path()
    store = store |> Map.put(:id, id) |> Map.put(:path, path)
    {:reply, :ok, put_in(state, [:stores, id], store)}
  end

  def handle_call(:registered, _from, state), do: {:reply, Map.keys(state.stores), state}

  def handle_call({:unregister, id}, _from, state),
    do: {:reply, :ok, %{state | stores: Map.delete(state.stores, id)}}

  def handle_call(:sweep_now, _from, state) do
    {:reply, :ok, do_sweep(state)}
  end

  @impl true
  def handle_info(:sweep, state) do
    schedule_sweep()
    {:noreply, do_sweep(state)}
  end

  def handle_info(:prune, state) do
    schedule_prune()
    {:noreply, do_prune(state)}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp schedule_sweep do
    interval = Application.get_env(:tiannara, :dets_sweep_interval_ms, 60_000)
    Process.send_after(self(), :sweep, interval)
  end

  defp schedule_prune do
    interval = Application.get_env(:tiannara, :dets_prune_interval_ms, 6 * 60 * 60 * 1000)
    Process.send_after(self(), :prune, interval)
  end

  defp do_sweep(state) do
    warn_bytes = Application.get_env(:tiannara, :dets_warn_bytes, 1_500_000_000)
    rotate_bytes = Tiannara.Storage.Rotator.rotate_bytes()

    Enum.reduce(state.stores, state, fn {id, store}, acc ->
      case File.stat(store.path) do
        {:ok, %{size: size}} ->
          :telemetry.execute(
            [:tiannara, :storage, :dets, :size],
            %{size: size},
            %{store: id}
          )

          cond do
            size >= rotate_bytes ->
              Logger.warning(
                "DetsLifecycle: #{id} at #{size} bytes (>= rotate #{rotate_bytes}) — rotating"
              )

              rotate_store(store)
              %{acc | warned: Map.delete(acc.warned, id)}

            size >= warn_bytes and not Map.get(acc.warned, id, false) ->
              Logger.warning("DetsLifecycle: #{id} at #{size} bytes (>= warn #{warn_bytes})")
              %{acc | warned: Map.put(acc.warned, id, true)}

            true ->
              %{acc | warned: Map.delete(acc.warned, id)}
          end

        _ ->
          acc
      end
    end)
  end

  defp do_prune(state) do
    Enum.each(state.stores, fn {id, store} ->
      case call(store.module, :prune, 30_000) do
        {:ok, pruned} ->
          if pruned > 0 do
            Logger.info("DetsLifecycle: pruned #{pruned} records from #{id}")

            :telemetry.execute(
              [:tiannara, :storage, :dets, :pruned],
              %{count: pruned},
              %{store: id}
            )
          end

        {:error, :storage_degraded} ->
          :ok

        {:error, reason} ->
          Logger.warning("DetsLifecycle: prune failed for #{id}: #{inspect(reason)}")

        other ->
          Logger.warning("DetsLifecycle: unexpected prune result for #{id}: #{inspect(other)}")
      end
    end)

    %{state | last_pruned: DateTime.utc_now()}
  end

  defp rotate_store(%{module: module, id: id}) do
    case call(module, :rotate, 60_000) do
      {:ok, archive} ->
        Logger.info("DetsLifecycle: rotated #{id} — archive at #{archive}")

        :telemetry.execute(
          [:tiannara, :storage, :dets, :rotated],
          %{count: 1},
          %{store: id}
        )

        :ok

      {:error, reason} ->
        Logger.error("DetsLifecycle: rotation failed for #{id}: #{inspect(reason)}")
        :ok
    end
  end

  defp call(module, msg, timeout) do
    GenServer.call(module, msg, timeout)
  rescue
    e -> {:error, {:lifecycle_call_failed, e}}
  catch
    :exit, reason -> {:error, {:lifecycle_call_exit, reason}}
  end
end
