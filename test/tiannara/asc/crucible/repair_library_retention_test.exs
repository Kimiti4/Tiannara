defmodule Tiannara.ASC.Crucible.RepairLibraryRetentionTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Crucible.{RepairLibrary, RepairPattern}

  @tables [:repair_library, :repair_library_seq, :repair_library_meta]

  setup do
    archive =
      Path.join(
        System.tmp_dir!(),
        "repair_library_retention_#{System.unique_integer([:positive])}.ndjson"
      )

    File.rm(archive)

    asc_env = Application.get_env(:tiannara, :asc, [])

    Application.put_env(
      :tiannara,
      :asc,
      Keyword.merge(asc_env,
        repair_library_max_patterns: 100,
        repair_library_persistence_file: archive
      )
    )

    stop_supervised_library()
    stop_library()
    drop_tables()

    on_exit(fn ->
      stop_library()
      drop_tables()
      File.rm(archive)
      Application.put_env(:tiannara, :asc, asc_env)
      restart_supervised_library()
    end)

    {:ok, _pid} = RepairLibrary.start_link()

    %{archive: archive}
  end

  defp stop_supervised_library do
    case Process.whereis(Tiannara.ASC.Supervisor) do
      nil ->
        :ok

      _pid ->
        case Supervisor.terminate_child(Tiannara.ASC.Supervisor, RepairLibrary) do
          :ok -> :ok
          {:error, :not_found} -> :ok
        end
    end
  end

  defp restart_supervised_library do
    case Process.whereis(Tiannara.ASC.Supervisor) do
      nil ->
        :ok

      _pid ->
        case Supervisor.restart_child(Tiannara.ASC.Supervisor, RepairLibrary) do
          {:ok, _pid} -> :ok
          {:error, :running} -> :ok
          {:error, :not_found} -> :ok
        end
    end
  end

  defp stop_library do
    case Process.whereis(RepairLibrary) do
      nil ->
        :ok

      pid ->
        try do
          GenServer.stop(pid, :normal)
        catch
          :exit, {reason, _} when reason in [:noproc, :normal, :shutdown] -> :ok
        end
    end
  end

  defp drop_tables do
    for t <- @tables, :ets.whereis(t) != :undefined, do: :ets.delete(t)
  end

  defp pattern(id) do
    %RepairPattern{
      id: id,
      failure_signature: "sig_#{id}",
      repair_category: :validation,
      failure_classification: %{
        domain: :validation,
        category: :validation,
        subcategory: :missing
      },
      confidence: 0.8,
      transferability: 0.6,
      success_rate: 0.9
    }
  end

  test "inserts beyond the configured bound evict the oldest patterns deterministically" do
    for i <- 1..150 do
      RepairLibrary.add_pattern(pattern("p_#{String.pad_leading("#{i}", 3, "0")}"))
    end

    assert RepairLibrary.pattern_count() == 100
    assert RepairLibrary.query_by_signature("sig_p_001") == []
    assert RepairLibrary.query_by_signature("sig_p_050") == []
    assert length(RepairLibrary.query_by_signature("sig_p_100")) == 1
    assert length(RepairLibrary.query_by_signature("sig_p_150")) == 1
  end

  test "boot ingestion streams the archive into a bounded working set", %{archive: archive} do
    stop_library()
    drop_tables()

    for i <- 1..150 do
      p = pattern("boot_#{String.pad_leading("#{i}", 3, "0")}")
      File.write!(archive, Jason.encode!(Map.from_struct(p)) <> "\n", [:append])
    end

    {:ok, _pid} = RepairLibrary.start_link()

    assert RepairLibrary.pattern_count() == 100
    assert RepairLibrary.query_by_signature("sig_boot_001") == []
    assert RepairLibrary.query_by_signature("sig_boot_050") == []
    assert length(RepairLibrary.query_by_signature("sig_boot_150")) == 1
  end

  test "queries and samples stay bounded; match specs work on struct maps" do
    for i <- 1..50 do
      RepairLibrary.add_pattern(pattern("q_#{String.pad_leading("#{i}", 3, "0")}"))
    end

    assert RepairLibrary.pattern_count() == 50
    assert length(RepairLibrary.get_patterns_sample(50)) == 50
    assert length(RepairLibrary.get_patterns_sample(10)) == 10
    assert length(RepairLibrary.query_by_category(:validation)) == 50
    assert RepairLibrary.verify_integrity()
  end
end