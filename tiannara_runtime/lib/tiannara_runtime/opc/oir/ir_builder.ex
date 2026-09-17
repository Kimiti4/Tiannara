defmodule Tiannara.OPC.OIR.IRBuilder do
  @moduledoc """
  Phase 5F.6 — OIR (Ontological Intermediate Representation) Builder
  
  Converts regularized AST into stack-based intermediate representation
  suitable for GPU compilation.
  """
  
  use GenServer

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Build OIR from AST.
  
  Returns list of instructions in reverse polish notation style.
  """
  def build(ast) do
    compile(ast, [])
    |> Enum.reverse()
  end

  defp compile({:number, n}, acc) do
    [{:load_const, n} | acc]
  end

  defp compile({:identifier, id}, acc) do
    [{:load_var, id} | acc]
  end

  defp compile({:binary_op, op, left, right}, acc) do
    acc1 = compile(left, acc)
    acc2 = compile(right, acc1)
    [{:binary_exec, op} | acc2]
  end

  defp compile({:unary_op, op, operand}, acc) do
    acc1 = compile(operand, acc)
    [{:unary_exec, op} | acc1]
  end

  defp compile({:function, name, args}, acc) do
    acc1 = Enum.reduce(args, acc, fn arg, acc_acc ->
      compile(arg, acc_acc)
    end)
    
    [{:call_func, name} | acc1]
  end

  defp compile({:tensor, elements}, acc) do
    acc1 = Enum.reduce(elements, acc, fn elem, acc_acc ->
      compile(elem, acc_acc)
    end)
    
    [{:emit_tensor, length(elements)} | acc1]
  end

  defp compile({:conditional, condition, true_branch, false_branch}, acc) do
    acc1 = compile(false_branch, acc)
    acc2 = compile(true_branch, acc1)
    acc3 = compile(condition, acc2)
    [{:branch} | acc3]
  end

  @impl true
  def init(state), do: {:ok, state}
end
