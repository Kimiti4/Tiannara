defmodule Tiannara.OPC do
  @moduledoc """
  Ontological Physics Compiler (OPC) - Privileged Compiler Layer
  
  Converts observer cognition, semantic ontology, causal structures,
  and ecological pressures into executable spacetime laws.
  """
  require Logger

  @doc "Builds an AST and attempts to compile it into executable physics."
  def compile_world_for_deployment(observer_model) do
    ast = Tiannara.OPC.ASTBuilder.build(observer_model)
    
    # 1. EMIT OBSERVABILITY TELEMETRY BEFORE EXECUTION
    :telemetry.execute(
      [:tiannara, :opc, :ast_generated],
      %{
        compute_pressure: ast.stability.compute_pressure,
        entropy_cost: ast.stability.entropy_cost
      },
      %{
        ast: ast,
        observer_tier: ast.observer.tier
      }
    )
    
    Logger.info("🌌 [OPC] AST generated and exposed to telemetry. Pending compilation...")

    # 2. Compile via validation gates
    case Tiannara.OPC.Compiler.compile(ast) do
      {:ok, rule} ->
        Logger.info("✅ [OPC] Physics rule successfully compiled.")
        {:ready_for_deployment, %{rule: rule, compiled_at: DateTime.utc_now()}}
      {:rejected, reason} ->
        Logger.warning("❌ [OPC] Physics compilation rejected by governance: #{inspect(reason)}")
        {:error, reason}
    end
  end
end

defmodule Tiannara.OPC.ASTBuilder do
  def build(observer_model) do
    %{
      ontology: %{
        concept: Map.get(observer_model, :concept, :generic),
        divergence_score: 0.12
      },
      causality: %{
        timeline_constraints: [],
        branch_scope: :local,
        causal_stress: 0.21
      },
      observer: %{
        tier: Map.get(observer_model, :tier, :tier2),
        consensus_weight: 0.64
      },
      stability: %{
        entropy_cost: 0.32,
        compute_pressure: 0.28,
        novelty_impact: 0.17
      },
      execution: %{
        opcode: Map.get(observer_model, :opcode, :curvature_field),
        parameters: Map.get(observer_model, :parameters, %{}),
        runtime_budget: 0.3
      }
    }
  end
end

defmodule Tiannara.OPC.Compiler do
  def compile(ast) do
    with :ok <- validate_ctl(ast),
         :ok <- validate_ocm(ast),
         :ok <- validate_osl(ast) do
      emit_runtime_rule(ast)
    else
      error -> {:rejected, error}
    end
  end

  defp emit_runtime_rule(ast) do
    {:ok, %{
      opcode: ast.execution.opcode,
      parameters: ast.execution.parameters,
      runtime_budget: ast.execution.runtime_budget
    }}
  end

  defp validate_ctl(_ast), do: :ok
  defp validate_ocm(_ast), do: :ok
  defp validate_osl(ast) do
    if ast.observer.tier in [:tier0, :tier1] do
      {:error, :insufficient_sandbox_tier}
    else
      :ok
    end
  end
end
