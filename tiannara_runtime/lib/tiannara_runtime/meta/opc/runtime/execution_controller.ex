defmodule Tiannara.Meta.OPC.Runtime.ExecutionController do
  @moduledoc """
  Phase 5F.6 — OPC Execution Controller

  Orchestrates the full observer physics compilation pipeline:

      Source → Parser → AORRegularizer → IRGenerator → OPCGate
            → GLSLGenerator → GPUDispatcher

  This module is the single entry point for executing observer-defined
  physics. It is supervised by `Tiannara.Meta.OPC.Supervisor`.

  ## Usage

      {:ok, result} = ExecutionController.execute("obs_001", physics_source)
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.OPC.Stabilization.AORRegularizer
  alias Tiannara.Meta.OPC.OIR.IRGenerator
  alias Tiannara.Meta.OPC.GCK.OPCGate
  alias Tiannara.Meta.OPC.Compiler.GLSLGenerator
  alias Tiannara.Meta.OPC.Runtime.GPUDispatcher
  alias Tiannara.Meta.OPC.Runtime.ExecutionAuditor

  # ── Public API ────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Executes observer physics through the full OPC pipeline.

  ## Parameters
  - `observer_id`: Unique observer identifier
  - `source`: Raw physics AST (already parsed; parser integration is a
    separate concern handled upstream)

  ## Returns
  - `{:ok, result}` — Execution succeeded
  - `{:error, reason}` — Pipeline stage failed
  """
  def execute(observer_id, source) do
    GenServer.call(__MODULE__, {:execute, observer_id, source}, :infinity)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(opts) do
    Logger.info("🚀 [ExecutionController] OPC Execution Controller started")
    {:ok, %{opts: opts}}
  end

  @impl true
  def handle_call({:execute, observer_id, source}, _from, state) do
    Logger.info("📝 [ExecutionController] Executing physics for #{observer_id}")

    result =
      with regularized <- AORRegularizer.regularize(source),
           {:ok, instructions} <- IRGenerator.generate(regularized),
           :ok <- OPCGate.validate(regularized, instructions),
           shader <- GLSLGenerator.generate(instructions),
           {:ok, dispatch_result} <- GPUDispatcher.dispatch(observer_id, shader, %{}) do
        GenServer.cast(ExecutionAuditor, {:execution, observer_id})
        {:ok, dispatch_result}
      end

    {:reply, result, state}
  end
end
