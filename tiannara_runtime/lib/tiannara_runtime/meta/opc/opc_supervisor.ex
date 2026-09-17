defmodule Tiannara.Meta.OPC.Supervisor do
  @moduledoc """
  Phase 5F.6 — OPC Stabilization Layer Supervisor

  Top-level supervisor for the Observer Physics Compiler stabilization
  control plane. Manages the full pipeline:

      ExecutionController  — orchestrates the compile pipeline
      ExecutionAuditor     — logs every execution
      RollbackManager      — snapshot/rollback for unstable manifolds
      EntropyMonitor       — rolling entropy telemetry
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Runtime
      Tiannara.Meta.OPC.Runtime.ExecutionAuditor,
      Tiannara.Meta.OPC.Runtime.RollbackManager,
      Tiannara.Meta.OPC.Runtime.ExecutionController,

      # Telemetry
      Tiannara.Meta.OPC.Telemetry.EntropyMonitor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
