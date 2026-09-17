defmodule Tiannara.OPC.Supervisor do
  @moduledoc """
  Phase 5F.6 — OPC Supervisor
  
  Top-level supervisor for the Observer Physics Compiler subsystem.
  Manages compilation pipeline, runtime execution, and telemetry.
  """
  
  use Supervisor

  def start_link(arg \\ []) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Compilation Pipeline Components
      {Tiannara.OPC.Parser.Lexer, []},
      {Tiannara.OPC.Parser.Parser, []},
      
      # AOR Regularization
      {Tiannara.OPC.AOR.Regularizer, []},
      
      # OIR Generation
      {Tiannara.OPC.OIR.IRBuilder, []},
      
      # GPU Compilation
      {Tiannara.OPC.Compiler.GPUCompiler, []},
      {Tiannara.OPC.Compiler.ShaderCache, []},  # NEW: Shader caching
      
      # Runtime Execution
      {Tiannara.OPC.Runtime.ExecutionRuntime, []},
      {Tiannara.OPC.Runtime.ChronogramBridge, []},  # NEW: Holographic memory integration

      # Rule Storage
      {Tiannara.OPC.RuleStore, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
