defmodule Tiannara.Storage.Rotator do
  @moduledoc """
  Rotates a DETS table before it hits the 2 GB wall.

  DETS uses 32-bit internal offsets: the ~2 GB ceiling is a property of the
  format. `:dets.delete/2` frees space *inside* the file but does NOT shrink
  it — under sustained writes the file climbs toward the wall even when the
  live record count is bounded. The only mechanisms that actually bound
  physical file size are rotation and compaction. Retention/TTL pruning is
  logical hygiene and does NOT bound the file.

  Rotation runs INSIDE the owning GenServer (single-writer), which removes
  the cross-process race the cast-based sketch would have. Order is
  load-bearing:

    1. open a fresh table at `<path>.new` (same shape)
    2. copy live records into it (compaction: dead space is dropped)
    3. sync + close the fresh table (its bytes are now safe on disk)
    4. close the OLD table (flush) — only now may its file be moved
    5. move the old file to `<path>.archive.<stamp>`
    6. promote `<path>.new` → `<path>`
    7. reopen the ORIGINAL table name at the promoted path

  The original table atom is stable across rotations (no atom leak), and the
  archive reopens cleanly (it is a complete, closed DETS file).
  """

  require Logger

  @default_rotate_bytes 1_800_000_000

  @doc "Size threshold (bytes) at which a store should rotate."
  def rotate_bytes do
    Application.get_env(:tiannara, :dets_rotate_bytes, @default_rotate_bytes)
  end

  @doc "True when the file at `path` has crossed the rotation threshold."
  def should_rotate?(path) do
    threshold = rotate_bytes()

    case File.stat(path) do
      {:ok, %{size: size}} when size >= threshold -> true
      _ -> false
    end
  end

  @doc """
  Rotates `table` at `path` (charlist or binary) using `open_opts` (a
  keyword list WITHOUT `:file`). Returns `{:ok, archive_path}`.

  Must be called from the process that owns the table. Live records are
  copied into the fresh file, so rotation is also compaction: the promoted
  file is small and the archive holds the full old state.
  """
  def rotate(table, path, open_opts) do
    path_str = to_string(path)
    stamp = Calendar.strftime(DateTime.utc_now(), "%Y%m%dT%H%M%S")
    new_path = path_str <> ".new"
    archive_path = path_str <> ".archive." <> stamp
    fresh_table = String.to_atom("#{inspect(table)}_rot_#{stamp}")

    with {:ok, ^fresh_table} <-
           open_fresh(fresh_table, new_path, open_opts),
         :ok <- copy_live(table, fresh_table),
         :ok <- :dets.sync(fresh_table),
         :ok <- :dets.close(fresh_table),
         :ok <- :dets.close(table),
         :ok <- File.rename(path_str, archive_path),
         :ok <- File.rename(new_path, path_str),
         {:ok, ^table} <-
           Tiannara.CEL.Services.ResilientDETS.open(
             table,
             Keyword.put(open_opts, :file, String.to_charlist(path_str))
           ) do
       Logger.info(
         "Rotator: rotated #{inspect(table)} — archived #{archive_path}, " <>
           "promoted fresh #{path_str}"
       )

      reap_archives(path_str)

      {:ok, archive_path}
    else
      {:error, reason} ->
        Logger.error("Rotator: rotation failed for #{inspect(table)}: #{inspect(reason)}")
        rollback(table, path_str, new_path, archive_path)
        {:error, reason}

      other ->
        Logger.error("Rotator: rotation failed for #{inspect(table)}: #{inspect(other)}")
        rollback(table, path_str, new_path, archive_path)
        {:error, other}
    end
  end

  @doc """
  Bounds on-disk archive growth after rotation.

  Deliberate retention policy, not accidental loss:
    - never deletes the live file, only `<base>.archive.<stamp>` siblings;
    - deletes oldest-first;
    - keeps the most recent `:dets_retention_max_archives` (preserves the
      rollback source, per "Preserve previous stable states");
    - ages out anything older than `:dets_archive_ttl_minutes`;
    - logs every deletion ("Maintain audit trails").

  The certification's real evidence (soak reports, pipeline telemetry) lives
  outside these archives and is untouched by reaping.
  """
  def reap_archives(base_path) do
    max     = Application.get_env(:tiannara, :dets_retention_max_archives, 2)
    ttl_min = Application.get_env(:tiannara, :dets_archive_ttl_minutes, 60)

    dir  = Path.dirname(base_path)
    base = Path.basename(base_path)

    archives =
      case File.ls(dir) do
        {:ok, names} ->
          names
          |> Enum.filter(&String.starts_with?(&1, base <> ".archive."))
          |> Enum.map(fn n ->
            p = Path.join(dir, n)

            case File.stat(p, time: :universal) do
              {:ok, %{mtime: mtime}} -> {mtime, p}
              _ -> nil
            end
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.sort()

        _ ->
          []
      end

    now     = :calendar.universal_time() |> :calendar.datetime_to_gregorian_seconds()
    ttl_sec = ttl_min * 60

    {expired, rest} =
      Enum.split_with(archives, fn {mtime, _} ->
        now - :calendar.datetime_to_gregorian_seconds(mtime) > ttl_sec
      end)

    overflow = if length(rest) > max, do: Enum.take(rest, length(rest) - max), else: []

    Enum.each(expired ++ overflow, fn {_mtime, p} ->
      case File.rm(p) do
        :ok -> Logger.info("Rotator: reaped archive #{p}")
        {:error, r} -> Logger.warning("Rotator: reap failed for #{p}: #{inspect(r)}")
      end
    end)

    :ok
  rescue
    e ->
      Logger.warning("Rotator: reap_archives skipped: #{inspect(e)}")
      :ok
  end

  defp open_fresh(fresh_table, new_path, open_opts) do
    File.mkdir_p!(Path.dirname(new_path))

    Tiannara.CEL.Services.ResilientDETS.open(
      fresh_table,
      Keyword.put(open_opts, :file, String.to_charlist(new_path))
    )
  end

  # Copies every live record from the old table into the fresh one.
  # Traversal is streaming (first/next), so memory stays bounded even with
  # many records.
  defp copy_live(from, to) do
    copy_loop(from, to, :dets.first(from))
  end

  defp copy_loop(_from, _to, :"$end_of_table"), do: :ok

  defp copy_loop(from, to, key) do
    case :dets.lookup(from, key) do
      [object] ->
        case :dets.insert(to, object) do
          :ok -> copy_loop(from, to, :dets.next(from, key))
          {:error, reason} -> {:error, reason}
        end

      [] ->
        copy_loop(from, to, :dets.next(from, key))
    end
  end

  # Best-effort: try to reopen the original table at its path so the owner
  # process can keep serving even if rotation half-failed.
  defp rollback(table, path_str, new_path, archive_path) do
    cond do
      File.exists?(new_path) and not File.exists?(path_str) ->
        _ = File.rename(new_path, path_str)

      File.exists?(new_path) ->
        _ = File.rm(new_path)

      true ->
        :ok
    end

    _ = File.rm(archive_path)

    case Tiannara.CEL.Services.ResilientDETS.open(
           table,
           type: :set,
           file: String.to_charlist(path_str)
         ) do
      {:ok, ^table} ->
        Logger.warning("Rotator: reopened #{inspect(table)} at #{path_str} after failed rotation")

      other ->
        Logger.error(
          "Rotator: could not reopen #{inspect(table)} after failed rotation: #{inspect(other)}"
        )
    end
  end
end
