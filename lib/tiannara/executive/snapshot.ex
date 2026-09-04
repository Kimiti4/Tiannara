defmodule Tiannara.Executive.Snapshot do
  @moduledoc """
  Immutable point-in-time snapshots of Executive Memory.

  Creates and restores snapshots with SHA-256 checksums and
  metadata sidecars.
  """

  require Logger

  @doc "Creates a snapshot of the DETS store."
  def create(name, dets_ref, snapshot_dir) do
    File.mkdir_p!(snapshot_dir)

    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    snapshot_file = Path.join(snapshot_dir, "snapshot_#{timestamp}.dets")
    metadata_file = snapshot_file <> ".meta"

    # Malformed records (e.g. non-2-tuple journal artifacts) are skipped so a
    # snapshot pass can never crash maintenance on an already-corrupt store.
    sparse =
      :dets.foldl(
        fn
          {k, v}, acc -> [{k, v} | acc]
          _, acc -> acc
        end,
        [],
        dets_ref
      )

    data_bin = :erlang.term_to_binary(sparse)
    checksum = :crypto.hash(:sha256, data_bin)

    File.write!(snapshot_file, data_bin)

    metadata = %{
      timestamp: DateTime.utc_now(),
      source: name,
      record_count: length(sparse),
      checksum: Base.encode16(checksum),
      checksum_algorithm: "SHA-256"
    }

    File.write!(metadata_file, Jason.encode!(metadata, pretty: true))

    Logger.info(
      "[ExecutiveMemory] Snapshot created: #{snapshot_file} (#{length(sparse)} records)"
    )

    snapshot_file
  end

  @doc "Restores state from a snapshot file."
  def restore(snapshot_file, dets_ref) do
    with {:ok, data_bin} <- File.read(snapshot_file),
         {:ok, metadata} <- load_metadata(snapshot_file <> ".meta") do
      expected = Base.decode16!(metadata.checksum, case: :mixed)
      actual = :crypto.hash(:sha256, data_bin)

      if actual == expected do
        records = :erlang.binary_to_term(data_bin)
        :dets.delete_all_objects(dets_ref)
        Enum.each(records, fn {k, v} -> :dets.insert(dets_ref, {k, v}) end)

        Logger.info(
          "[ExecutiveMemory] Snapshot restored: #{snapshot_file} (#{length(records)} records)"
        )

        {:ok, length(records)}
      else
        {:error, :checksum_mismatch}
      end
    else
      error -> error
    end
  end

  @doc "Lists all available snapshots in the snapshot directory."
  def list(snapshot_dir) do
    case File.ls(snapshot_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".dets"))
        |> Enum.map(fn f ->
          meta_path = Path.join(snapshot_dir, f <> ".meta")

          metadata =
            case load_metadata(meta_path) do
              {:ok, m} -> m
              _ -> %{}
            end

          %{file: Path.join(snapshot_dir, f), metadata: metadata}
        end)
        |> Enum.sort_by(fn s -> safe_datetime(s.metadata[:timestamp]) end, {:desc, DateTime})

      _ ->
        []
    end
  end

  @doc "Prunes snapshots, keeping only the N most recent."
  def prune(snapshot_dir, keep \\ 5) do
    snapshots = list(snapshot_dir)

    if length(snapshots) > keep do
      to_delete = Enum.drop(snapshots, keep)

      Enum.each(to_delete, fn %{file: file} ->
        File.rm_rf(file)
        File.rm_rf(file <> ".meta")
      end)

      length(to_delete)
    else
      0
    end
  end

  @doc "Verifies a snapshot file checksum."
  def verify(snapshot_file) do
    meta_file = snapshot_file <> ".meta"

    with {:ok, data} <- File.read(snapshot_file),
         {:ok, meta} <- load_metadata(meta_file) do
      expected = Base.decode16!(meta.checksum, case: :mixed)
      actual = :crypto.hash(:sha256, data)
      actual == expected
    else
      _ -> false
    end
  end

  defp safe_datetime(%DateTime{} = dt), do: dt

  defp safe_datetime(ts) when is_binary(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, dt, _} -> dt
      _ -> DateTime.from_unix!(0)
    end
  end

  defp safe_datetime(_), do: DateTime.from_unix!(0)

  defp load_metadata(path) do
    case File.read(path) do
      {:ok, content} -> Jason.decode(content, keys: :atoms!)
      _ -> {:error, :not_found}
    end
  end
end
