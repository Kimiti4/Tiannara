defmodule Tiannara.CEL.Services.WorkflowEngineRetryTest do
  @moduledoc """
  Regression: WorkflowEngine must survive a step failure when the workflow's
  context has no :retry_counts entry yet.

  Soak finding: handle_step_failure crashed with
      ArgumentError: could not put/update key "step_execute" on a nil value
  because put_in(workflow, [:context, :retry_counts, step.id], ...) cannot
  create the intermediate :retry_counts map. The engine died every ~6 minutes
  and never recovered the interrupted workflow ("Recovered 0 interrupted
  workflows"). The retry path must build retry_counts defensively.
  """

  use ExUnit.Case, async: false

  alias Tiannara.CEL.Services.{
    WorkflowEngine,
    ResourceManager,
    CapabilityGraph,
    IdentityTrustManager
  }

  alias Tiannara.CEL.Workflow.{Workflow, Step}
  alias Tiannara.Storage.DetsLifecycle

  defmodule FailingStep do
    @behaviour Tiannara.CEL.Workflow.Step

    @impl true
    def step_type, do: :failing_probe

    @impl true
    def required_capability, do: :probe_failure_capability

    @impl true
    def validate_input(_input), do: :ok

    @impl true
    def execute(_input, _context), do: raise("probe failure")

    @impl true
    def compensate(_input, _result, _context), do: :ok

    @impl true
    def metadata, do: %{description: "always-failing probe"}
  end

  setup do
    started =
      for mod <- [ResourceManager, CapabilityGraph, IdentityTrustManager, WorkflowEngine],
          pid = ensure_running(mod, []) do
        {mod, pid}
      end

    _ = CapabilityGraph.register_capability(:probe_failure_capability, %{})
    _ = CapabilityGraph.declare_provides(:failing_provider, :probe_failure_capability)

    on_exit(fn ->
      for {mod, pid} <- started, Process.alive?(pid), do: GenServer.stop(pid)
      DetsLifecycle.unregister(:workflow_engine)
    end)

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

  defp failing_workflow(wf_id) do
    %Workflow{
      id: wf_id,
      name: "retry_counts_regression",
      steps: [
        %Step{
          id: "step_execute",
          type: :failing_probe,
          module: FailingStep,
          input: %{}
        }
      ],
      context: %{},
      mission_id: nil,
      version: "1.0.0"
    }
  end

  test "engine survives step failure with no retry_counts in context; retries then fails permanently" do
    assert Process.alive?(Process.whereis(WorkflowEngine))

    wf_id = "wf_retry_probe_#{System.unique_integer([:positive])}"
    wf = failing_workflow(wf_id)

    assert {:ok, ^wf_id} = WorkflowEngine.start_workflow(wf)

    # the engine must NOT crash on the retry bookkeeping
    assert Process.alive?(Process.whereis(WorkflowEngine)), "engine must not crash on retry bookkeeping"

    # 3 retries (retry_counts 1..3) then permanent failure with compensation
    assert eventually(
             fn -> WorkflowEngine.get_status(wf_id) == {:ok, :failed} end,
             8_000
           ),
           "workflow must end :failed after retries are exhausted"

    assert Process.alive?(Process.whereis(WorkflowEngine)), "engine must survive the full retry path"
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