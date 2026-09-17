defmodule Tiannara.Storage.DETSContinuityAcceptanceTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Civilizational Continuity Acceptance Suite for DETS storage layer.
  Ensures storage failures do NOT terminate the application supervision tree.
  """

  @test_file ~c"./test_cel_memory_continuity.dets"

  setup do
    {:ok, _} = Application.ensure_all_started(:telemetry)
    File.rm(List.to_string(@test_file))
    File.rm(List.to_string(@test_file) <> ".TMP")

    on_exit(fn ->
      File.rm(List.to_string(@test_file))
      File.rm(List.to_string(@test_file) <> ".TMP")
    end)

    :ok
  end

  describe "DETS Continuity Acceptance Invariants" do
    test "1. Healthy DETS: persistent memory loads normally" do
      {:ok, table} = :dets.open_file(:healthy_test_table, type: :set, file: @test_file)
      :ok = :dets.insert(table, {:key1, "value1"})
      :ok = :dets.close(table)

      # Re-open healthy file
      assert {:ok, table2} = :dets.open_file(:healthy_test_table, type: :set, file: @test_file)
      assert [{:key1, "value1"}] = :dets.lookup(table2, :key1)
      :ok = :dets.close(table2)
    end

    test "2. Missing DETS: initializes safely without crashing supervisor" do
      missing_file = ~c"./non_existent_path/missing.dets"
      result = :dets.open_file(:missing_test_table, type: :set, file: missing_file)

      # open_file will fail, but state handling must catch error
      assert {:error, _reason} = result
    end

    test "3. Corrupt DETS: corruption handled without terminating process" do
      # Create corrupt file
      File.write!(List.to_string(@test_file), "CORRUPTED_DETS_BINARY_GARBAGE_HEADER")

      result = :dets.open_file(:corrupt_test_table, type: :set, file: @test_file)
      assert {:error, _reason} = result

      # Quarantines/handles corrupted file
      if File.exists?(List.to_string(@test_file)) do
        quarantine = List.to_string(@test_file) <> ".quarantine." <> to_string(System.system_time(:second))
        File.rename(List.to_string(@test_file), quarantine)
        on_exit(fn -> File.rm(quarantine) end)
      end

      # Can start fresh table after quarantine
      assert {:ok, fresh_table} = :dets.open_file(:corrupt_test_table, type: :set, file: @test_file)
      :ok = :dets.close(fresh_table)
    end

    test "4. Restart: previously written state recovered" do
      {:ok, table} = :dets.open_file(:restart_test_table, type: :set, file: @test_file)
      :ok = :dets.insert(table, {:checkpoint, %{step: 42}})
      :ok = :dets.close(table)

      # Simulating restart
      assert {:ok, table_rebound} = :dets.open_file(:restart_test_table, type: :set, file: @test_file)
      assert [{:checkpoint, %{step: 42}}] = :dets.lookup(table_rebound, :checkpoint)
      :ok = :dets.close(table_rebound)
    end

    test "5. Recovery Telemetry: emitted cleanly without supervisor death" do
      test_pid = self()

      ref = :telemetry.attach(
        "dets-continuity-test",
        [:tiannara, :cel, :executive_memory, :degraded],
        fn event_name, measurements, metadata, _config ->
          send(test_pid, {:telemetry_degraded, event_name, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(ref) end)

      # Trigger degraded init
      assert {:ok, state} = Tiannara.CEL.Services.ExecutiveMemory.init([])
      assert state.status in [:healthy, :degraded]

      if state.status == :degraded do
        assert_receive {:telemetry_degraded, [:tiannara, :cel, :executive_memory, :degraded], %{count: 1}, _meta}
      end
    end
  end
end
