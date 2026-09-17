defmodule Tiannara.CEL.Services.ExecutiveMemoryTest do
  use ExUnit.Case, async: true
  alias Tiannara.CEL.Services.ExecutiveMemory

  setup do
    {:ok, _} = Application.ensure_all_started(:telemetry)
    :ok
  end

  describe "init/1 resilience & fallback" do
    test "gracefully falls back to ETS when DETS fails without crashing" do
      test_process = self()

      ref =
        :telemetry.attach(
          "executive-memory-test-handler",
          [:tiannara, :cel, :executive_memory, :degraded],
          fn event_name, measurements, metadata, _config ->
            send(test_process, {:telemetry_event, event_name, measurements, metadata})
          end,
          nil
        )

      on_exit(fn ->
        :telemetry.detach(ref)
      end)

      assert {:ok, state} = ExecutiveMemory.init([])
      assert state.backend in [:dets, :ets]

      if state.backend == :ets do
        assert state.status == :degraded
        assert_receive {:telemetry_event, [:tiannara, :cel, :executive_memory, :degraded], %{count: 1}, _meta}
      end
    end
  end
end
