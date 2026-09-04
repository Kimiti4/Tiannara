defmodule Tiannara.Storage.SoakFootprintGuard do
  @moduledoc """
  Bounds the soak's *own* on-disk footprint; turns an overrun into a graceful,
  interpretable abort instead of an opaque ENOSPC mid-run.

  The soak is bounded by rotation + the Rotator's archive reaper on a
  *per-store* basis, but the live+archive set across all stores is not a fixed
  function of time. This guard closes the loop on the modeled tail risk: if the
  soak's DETS tree ever exceeds `ceiling_bytes`, it writes an abort report and
  invokes `on_breach`, so the run stops with state intact and a readable
  diagnosis instead of dying at, say, hour 70 with no disk.

  A guard must never crash the tree it protects, so every path degrades to
  "reschedule and continue."
  """

  use GenServer
  require Logger

  @default_ceiling 14 * 1024 * 1024 * 1024

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def footprint do
    GenServer.call(__MODULE__, :footprint)
  end

  @impl true
  def init(opts) do
    state = %{
      dir: Keyword.fetch!(opts, :dir),
      ceiling: Keyword.get(opts, :ceiling_bytes, @default_ceiling),
      interval: Keyword.get(opts, :interval_ms, 5 * 60_000),
      on_breach: Keyword.get(opts, :on_breach, fn -> :ok end)
    }

    schedule(state.interval)
    {:ok, state}
  end

  @impl true
  def handle_call(:footprint, _from, state) do
    {:reply, {dir_bytes(state.dir), state.ceiling}, state}
  end

  @impl true
  def handle_info(:check, state) do
    case dir_bytes(state.dir) do
      {:ok, bytes} when bytes > state.ceiling ->
        Logger.error(
          "SoakFootprintGuard: #{bytes}B > ceiling #{state.ceiling}B — aborting soak"
        )

        write_abort_report(state, bytes)
        state.on_breach.()
        {:noreply, state}

      _ ->
        schedule(state.interval)
        {:noreply, state}
    end
  rescue
    e ->
      Logger.warning("SoakFootprintGuard: check skipped: #{inspect(e)}")
      schedule(state.interval)
      {:noreply, state}
  end

  defp schedule(ms), do: Process.send_after(self(), :check, ms)

  defp dir_bytes(dir) do
    files =
      dir
      |> Path.join("**")
      |> Path.wildcard()
      |> Enum.filter(&File.regular?/1)

    {:ok,
     Enum.reduce(files, 0, fn f, acc ->
       case File.stat(f) do
         {:ok, %{size: s}} -> acc + s
         _ -> acc
       end
     end)}
  end

  defp write_abort_report(state, bytes) do
    report_dir =
      if Code.ensure_loaded?(Tiannara.Storage.Paths) do
        try do
          Tiannara.Storage.Paths.path("reports")
        rescue
          _ -> "priv/soak_reports"
        catch
          :exit, _ -> "priv/soak_reports"
        end
      else
        "priv/soak_reports"
      end

    File.mkdir_p!(report_dir)

    ts =
      DateTime.utc_now()
      |> DateTime.to_iso8601()
      |> String.replace(":", "-")

    File.write!(Path.join(report_dir, "disk_abort_#{ts}.md"), """
    # Soak aborted by footprint guard

    At: #{ts}
    Footprint: #{bytes} bytes (ceiling #{state.ceiling})
    Dir: #{state.dir}

    Read as: the storage model's tail risk fired; the run stopped gracefully
    with state intact, not via ENOSPC. Soak reports and pipeline telemetry
    (kept outside the DETS archives) remain readable for post-mortem.
    """)

    Logger.info("SoakFootprintGuard: abort report written to #{report_dir}")
    :ok
  rescue
    e ->
      Logger.warning("SoakFootprintGuard: could not write abort report: #{inspect(e)}")
      :ok
  end
end
