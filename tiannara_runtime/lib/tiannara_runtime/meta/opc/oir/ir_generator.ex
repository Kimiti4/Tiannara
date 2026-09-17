defmodule Tiannara.Meta.OPC.OIR.IRGenerator do
  @moduledoc """
  Phase 5F.6 — OIR Instruction Generator

  Converts a regularized observer physics AST into a flat list of
  `Tiannara.Meta.OPC.OIR.Instruction` structs. The resulting instruction
  list is the input to the GLSL generator and the GCK ShaderComplexityGuard.

  ## Pipeline position

      AORRegularizer → IRGenerator → OPCGate → GLSLGenerator → GPUDispatcher

  ## Usage

      ast = {:op, :+, [{:const, 1.0}, {:var, :x}]}
      {:ok, instructions} = IRGenerator.generate(ast)
  """

  require Logger

  alias Tiannara.Meta.OPC.OIR.Instruction

  @doc """
  Generates an OIR instruction list from a regularized AST.

  ## Returns
  - `{:ok, [%Instruction{}]}` — Flat instruction list
  - `{:error, reason}` — Generation failed
  """
  def generate(ast) do
    Logger.debug("🔧 [IRGenerator] Generating OIR instructions from AST")

    {instructions, _counter} = emit(ast, [], 0)
    flat = List.flatten(instructions)

    Logger.debug("✅ [IRGenerator] Generated #{length(flat)} instructions")
    {:ok, flat}
  end

  # ── Private Emitters ──────────────────────────────────────────────────────

  # Binary operations
  defp emit({:op, op, [a, b]}, acc, counter) when op in [:+, :-, :*, :/, :pow] do
    {a_instrs, c1} = emit(a, [], counter)
    {b_instrs, c2} = emit(b, [], c1)

    dest = "r#{c2}"

    instr = %Instruction{
      opcode: op,
      dest: dest,
      src_a: last_dest(a_instrs, a),
      src_b: last_dest(b_instrs, b),
      metadata: %{epsilon_regularized: op == :/}
    }

    {acc ++ a_instrs ++ b_instrs ++ [instr], c2 + 1}
  end

  # Unary operations
  defp emit({:op, op, [arg]}, acc, counter) when op in [:sqrt, :abs, :log, :exp, :neg] do
    {arg_instrs, c1} = emit(arg, [], counter)

    dest = "r#{c1}"

    instr = %Instruction{
      opcode: op,
      dest: dest,
      src_a: last_dest(arg_instrs, arg),
      metadata: %{}
    }

    {acc ++ arg_instrs ++ [instr], c1 + 1}
  end

  # MSCL live pointer — emits a special load instruction
  defp emit({:mscl_pointer, name}, acc, counter) do
    dest = "mscl_#{name}"

    instr = %Instruction{
      opcode: :load_mscl,
      dest: dest,
      src_a: name,
      metadata: %{live_pointer: true}
    }

    {acc ++ [instr], counter + 1}
  end

  # Constant
  defp emit({:const, value}, acc, counter) do
    dest = "c#{counter}"

    instr = %Instruction{
      opcode: :load_const,
      dest: dest,
      src_a: value,
      metadata: %{}
    }

    {acc ++ [instr], counter + 1}
  end

  # Variable
  defp emit({:var, name}, acc, counter) do
    dest = "v_#{name}"

    instr = %Instruction{
      opcode: :load_var,
      dest: dest,
      src_a: name,
      metadata: %{}
    }

    {acc ++ [instr], counter + 1}
  end

  # Generic multi-arg op fallback
  defp emit({:op, op, args}, acc, counter) when is_list(args) do
    {all_instrs, final_counter} =
      Enum.reduce(args, {[], counter}, fn arg, {instrs, c} ->
        {new_instrs, new_c} = emit(arg, [], c)
        {instrs ++ new_instrs, new_c}
      end)

    dest = "r#{final_counter}"

    instr = %Instruction{
      opcode: op,
      dest: dest,
      src_a: :variadic,
      metadata: %{arg_count: length(args)}
    }

    {acc ++ all_instrs ++ [instr], final_counter + 1}
  end

  # Leaf passthrough
  defp emit(leaf, acc, counter) do
    instr = %Instruction{
      opcode: :noop,
      dest: "leaf_#{counter}",
      src_a: leaf,
      metadata: %{}
    }

    {acc ++ [instr], counter + 1}
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  # Returns the destination register of the last instruction, or a fallback
  defp last_dest([], fallback), do: inspect(fallback)

  defp last_dest(instrs, _fallback) do
    case List.last(instrs) do
      %Instruction{dest: dest} when not is_nil(dest) -> dest
      _ -> "unknown"
    end
  end
end
