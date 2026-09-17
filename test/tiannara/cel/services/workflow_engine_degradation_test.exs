defmodule Tiannara.CEL.Services.WorkflowEngineDegradationTest do
  @moduledoc """
  Hard gate (3): the executor must survive a storage fault.

  Consumer-side degradation: a closed/corrupt DETS store never crashes the
  WorkflowEngine — persists fail into an enqueue + retry-with-backoff path
  while the engine keeps serving in-memory, and records are re-persisted once
  the store recovers.
  """

  use ExUnit.Case, async: false

  alias Tiannara.CEL.Services.{
    WorkflowEngine,
    ResourceManager,
    CapabilityGraph,
    IdentityTrustManager
  }

  alias Tiannara.CEL.Workflow.{Workflow, Step}
  alias Tiannara.CEL.Workflow.Steps.Observation
  alias Tiannara.Storage.DetsLifecycle

  setup do
    # The CEL kernel boot can skip services in the test env (dependency gate
    # failures), so bring up what the executor needs to serve workflows.
    started =
      for mod <- [ResourceManager, CapabilityGraph, IdentityTrustManager, WorkflowEngine],
          pid = ensure_running(mod, []) do
        {mod, pid}
      end

    # wire one observation provider so workflows can actually complete
    _ = CapabilityGraph.register_capability(:observation_gathering, %{})
    _ = CapabilityGraph.declare_provides(:test_observer, :observation_gathering)

    on_exit(fn ->
      for {mod, pid} <- started, Process.alive?(pid), do: GenServer.stop(pid)
      DetsLifecycle.unregister(:workflow_engine)
    end)

    # make sure the store is healthy before each test
    if Process.whereis(WorkflowEngine) != nil and :dets.info(:workflow_engine) == :undefined do
      send(WorkflowEngine, :attempt_store_recovery)
      Process.sleep(300)
    end

    :ok
  end

  defp ensure_running(mod, args) do
    cond do
      Process.whereis(mod) ->
        nil

      true ->
        {:ok, pid} = mod.start_link(args)
        pid
    end
  end

  defp survival_workflow(wf_id) do
    %Workflow{
      id: wf_id,
      name: "storage_fault_survival",
      steps: [
        %Step{
          id: "obs_1",
          type: :observation,
          module: Observation,
          input: %{target: "test_target", observation_type: :lab_measurement}
        }
      ],
      context: %{},
      mission_id: nil,
      version: "1.0.0"
    }
  end

  test "executor survives a closed store: start/failure keep working in-memory, failure re-persists" do
    assert Process.alive?(Process.whereis(WorkflowEngine))

    send(WorkflowEngine, :simulate_store_failure)
    Process.sleep(200)
    assert :dets.info(:workflow_engine) == :undefined, "store must be closed after simulation"

    wf_id = "wf_survive_#{System.unique_integer([:positive])}"
    wf = survival_workflow(wf_id)

    # start must succeed (engine serves from memory while store is down)
    assert {:ok, ^wf_id} = WorkflowEngine.start_workflow(wf)
    assert Process.alive?(Process.whereis(WorkflowEngine)), "engine must not crash on store fault"
    assert %{healthy: true} = WorkflowEngine.stats(), "engine reports healthy in-memory service"

    # the Observation step's provider is intentionally unwired in this config,
    # so the workflow must fail gracefully — while transitions still work
    # in-memory during the store fault.
    assert eventually(fn -> WorkflowEngine.get_status(wf_id) == {:ok, :failed} end, 5_000)
    assert %{healthy: true} = WorkflowEngine.stats(), "engine still reports healthy after step failure"

    # restore the store, then the retry-with-backoff must re-persist the record
    send(WorkflowEngine, :attempt_store_recovery)
    assert eventually(fn -> :dets.info(:workflow_engine) != :undefined end, 3_000)

    assert eventually(
             fn ->
               case :dets.lookup(:workflow_engine, wf_id) do
                 [{_, %Workflow{status: :failed}}] -> true
                 _ -> false
               end
             end,
             6_000
           ),
           "retry-with-backoff must re-persist the workflow once the store recovers"
  end

  test "rotate is refused while degraded and accepted after recovery" do
    send(WorkflowEngine, :simulate_store_failure)
    Process.sleep(200)

    assert {:error, :storage_degraded} = WorkflowEngine.rotate()
    assert Process.alive?(Process.whereis(WorkflowEngine))

    send(WorkflowEngine, :attempt_store_recovery)
    assert eventually(fn -> :dets.info(:workflow_engine) != :undefined end, 3_000)
    assert {:ok, archive} = WorkflowEngine.rotate()
    assert File.exists?(archive)
    File.rm(archive)
  end

  defp eventually(fun, timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout

    do_eventually(fun, deadline)
  end

  defp do_eventually(fun, deadline) do
    cond do
      fun.() ->
        true

      System.monotonic_time(:millisecond) >= deadline ->
        false

      true ->
        Process.sleep(100)
        do_eventually(fun, deadline)
    end
  end
end
