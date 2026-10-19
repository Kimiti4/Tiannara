defmodule Tiannara.OPC.GPUExecutionQuarantineTest do
  @moduledoc """
  5F-P1c quarantine contract: fabricated OPC execution results must never
  be presented as real physics execution.

  The GPUExecutionBridge dispatch path references APIs that do not exist
  and its tensor generator fabricates `sin`/`cos` placeholder data, so both
  execution entry points must fail closed with
  `:simulated_execution_quarantined` while the bridge itself stays healthy.
  """

  use ExUnit.Case, async: false

  alias Tiannara.OPC.Runtime.GPUExecutionBridge

  @quarantine :simulated_execution_quarantined

  @oir %{
    operations: %{noop: 1},
    tensors: [%{dimensions: [4]}],
    metadata: %{}
  }

  setup do
    case Process.whereis(GPUExecutionBridge) do
      nil -> start_supervised!(GPUExecutionBridge)
      pid when is_pid(pid) -> :ok
    end

    :ok
  end

  describe "synchronous execute_oir" do
    test "fails closed with the quarantine reason instead of executing" do
      assert {:error, @quarantine} =
               GPUExecutionBridge.execute_oir(@oir, "obs_quarantine_sync")
    end

    test "leaves the bridge alive and with no fabricated job state" do
      assert {:error, @quarantine} = GPUExecutionBridge.execute_oir(@oir, "obs_quarantine_a")

      bridge = Process.whereis(GPUExecutionBridge)
      assert Process.alive?(bridge)
      assert :sys.get_state(bridge).active_kernels == %{}
      assert :sys.get_state(bridge).execution_queue == {[], []}
    end

    test "repeated refusals never crash the bridge" do
      for i <- 1..3 do
        assert {:error, @quarantine} =
                 GPUExecutionBridge.execute_oir(@oir, "obs_quarantine_repeat_#{i}")
      end

      assert Process.alive?(Process.whereis(GPUExecutionBridge))
      assert {:ok, %{active_kernels: 0}} = GPUExecutionBridge.get_utilization()
    end
  end

  describe "asynchronous submit_async/get_result" do
    test "queued job fails with the quarantine reason instead of hanging" do
      :ok = GPUExecutionBridge.submit_async(@oir, "obs_quarantine_async", nil)

      job_id = await_failed_job()

      assert %{status: :failed, error: @quarantine} =
               :sys.get_state(GPUExecutionBridge).active_kernels[job_id]

      assert {:error, @quarantine} = GPUExecutionBridge.get_result(job_id)

      refute Map.has_key?(:sys.get_state(GPUExecutionBridge).active_kernels, job_id)
    end
  end

  test "cache control remains operable under quarantine" do
    assert :ok = GPUExecutionBridge.clear_cache()
    assert {:ok, %{cache_hit_rate: 0.0}} = GPUExecutionBridge.get_utilization()
  end

  defp await_failed_job(attempts \\ 50)

  defp await_failed_job(0), do: flunk("no quarantined async job recorded before timeout")

  defp await_failed_job(attempts) do
    Process.sleep(20)

    case :sys.get_state(GPUExecutionBridge).active_kernels do
      kernels when map_size(kernels) > 0 ->
        {job_id, job} = Enum.find(kernels, fn {_id, job} -> job.status == :failed end) || {nil, nil}

        if job_id do
          job_id
        else
          await_failed_job(attempts - 1)
        end

      _ ->
        await_failed_job(attempts - 1)
    end
  end
end
