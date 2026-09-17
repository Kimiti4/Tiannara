defmodule Tiannara.OPC.AOR.Regularizer do
  @moduledoc """
  Phase 5F.6 — Automated Ontological Regularizer (AOR)
  
  Injects stability shims into AST to prevent singularities and numerical instability.
  Implements epsilon regularization for division operations.
  """
  
  use GenServer
  require Logger

  @epsilon_mscl 1.0e-10

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Regularize an AST by injecting stability safeguards.
  """
  def regularize(ast) do
    regularize_node(ast)
  end

  defp regularize_node({:binary_op, :/, left, right}) do
    Logger.debug("AOR: Injecting epsilon shim for division")
    
    {:binary_op, :/, 
      regularize_node(left),
      {:function, :sqrt, [
        {:binary_op, :+,
          {:binary_op, :^, regularize_node(right), {:number, 2.0}},
          {:number, @epsilon_mscl}
        }
      ]}
    }
  end

  defp regularize_node({:binary_op, op, left, right}) do
    {:binary_op, op, regularize_node(left), regularize_node(right)}
  end

  defp regularize_node({:unary_op, op, operand}) do
    {:unary_op, op, regularize_node(operand)}
  end

  defp regularize_node({:function, name, args}) do
    {:function, name, Enum.map(args, &regularize_node/1)}
  end

  defp regularize_node({:tensor, elements}) do
    {:tensor, Enum.map(elements, &regularize_node/1)}
  end

  defp regularize_node({:conditional, condition, true_branch, false_branch}) do
    {:conditional, 
      regularize_node(condition),
      regularize_node(true_branch),
      regularize_node(false_branch)
    }
  end

  defp regularize_node(node), do: node

  @impl true
  def init(state), do: {:ok, state}
end
