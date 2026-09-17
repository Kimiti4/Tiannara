defmodule Tiannara.OPC.V3.IR.DepthCalculator do
  @moduledoc """
  Safe depth calculation for OIR nodes
  This prevents crashes from raw atoms being passed to depth functions
  """

  alias Tiannara.OPC.V3.IR.OIR

  @doc """
  Calculates the depth of an OIR node
  Since all nodes are guaranteed to be OIR structs, this is crash-safe
  """
  def depth(%OIR{type: :number}), do: 1
  def depth(%OIR{type: :string}), do: 1
  def depth(%OIR{type: :boolean}), do: 1
  def depth(%OIR{type: :identifier}), do: 1

  def depth(%OIR{type: :binary, children: [l, r]}) do
    1 + max(depth(l), depth(r))
  end

  def depth(%OIR{type: :unary, children: [operand]}) do
    1 + depth(operand)
  end

  def depth(%OIR{type: :function, children: args}) do
    case args do
      [] -> 1
      _ -> 1 + Enum.max(Enum.map(args, &depth/1))
    end
  end

  def depth(%OIR{type: :tensor, children: elements}) do
    case elements do
      [] -> 1
      _ -> 1 + Enum.max(Enum.map(elements, &depth/1))
    end
  end

  def depth(%OIR{type: :conditional, children: [condition, true_branch, false_branch]}) do
    1 + max(max(depth(condition), depth(true_branch)), depth(false_branch))
  end

  def depth(nil), do: 0
end
