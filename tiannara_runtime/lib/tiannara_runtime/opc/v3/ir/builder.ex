defmodule Tiannara.OPC.V3.IR.Builder do
  @moduledoc """
  OIR Builder - The fix for raw atom crashes
  This converts raw syntax trees to strict OIR, eliminating :+ leakage forever
  """

  alias Tiannara.OPC.V3.IR.OIR

  @doc """
  Builds an OIR node from raw syntax tree representation
  """
  def build({:raw_binary, op, l, r}) do
    %OIR{
      type: :binary,
      op: op,
      children: [build(l), build(r)],
      meta: %{},
      value: nil
    }
  end

  def build({:raw_function, name, args}) do
    %OIR{
      type: :function,
      op: name,
      children: Enum.map(args, &build/1),
      meta: %{},
      value: nil
    }
  end

  def build({:raw_unary, op, operand}) do
    %OIR{
      type: :unary,
      op: op,
      children: [build(operand)],
      meta: %{},
      value: nil
    }
  end

  def build({:raw_identifier, name}) do
    %OIR{
      type: :identifier,
      op: nil,
      children: [],
      meta: %{},
      value: name
    }
  end

  def build({:number, v}) do
    %OIR{
      type: :number,
      op: nil,
      children: [],
      meta: %{},
      value: v
    }
  end

  def build({:string, s}) do
    %OIR{
      type: :string,
      op: nil,
      children: [],
      meta: %{},
      value: s
    }
  end

  def build({:boolean, b}) do
    %OIR{
      type: :boolean,
      op: nil,
      children: [],
      meta: %{},
      value: b
    }
  end

  def build({:raw_tensor, elements}) do
    %OIR{
      type: :tensor,
      op: nil,
      children: Enum.map(elements, &build/1),
      meta: %{},
      value: nil
    }
  end

  def build({:raw_conditional, condition, true_branch, false_branch}) do
    %OIR{
      type: :conditional,
      op: nil,
      children: [build(condition), build(true_branch), build(false_branch)],
      meta: %{},
      value: nil
    }
  end

  # Fallback for direct values
  def build(value) when is_number(value) do
    %OIR{
      type: :number,
      op: nil,
      children: [],
      meta: %{},
      value: value
    }
  end

  def build(value) when is_binary(value) do
    %OIR{
      type: :string,
      op: nil,
      children: [],
      meta: %{},
      value: value
    }
  end

  def build(value) when is_boolean(value) do
    %OIR{
      type: :boolean,
      op: nil,
      children: [],
      meta: %{},
      value: value
    }
  end

  def build(atom) when is_atom(atom) do
    %OIR{
      type: :identifier,
      op: nil,
      children: [],
      meta: %{},
      value: atom
    }
  end
end
