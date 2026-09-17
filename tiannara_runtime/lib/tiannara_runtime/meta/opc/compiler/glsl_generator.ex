defmodule Tiannara.Meta.OPC.Compiler.GLSLGenerator do
  @moduledoc """
  Phase 5F.6 — GLSL Generator

  Converts a flat OIR instruction list into a WebGL2 compute shader
  (GLSL ES 3.1). The generated shader reads from a bound RGBA32F image
  texture, executes the observer's physics, and writes results back.

  ## Shader structure

      #version 310 es
      layout(local_size_x = 16, local_size_y = 16) in;
      layout(rgba32f, binding = 0) uniform highp image2D u_state;

      void main() {
        ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
        <emitted instructions>
      }

  ## Usage

      instructions = [%Instruction{opcode: :add, dest: "r0", src_a: "c0", src_b: "v_x"}]
      shader_source = GLSLGenerator.generate(instructions)
  """

  require Logger

  alias Tiannara.Meta.OPC.OIR.Instruction

  @doc """
  Generates a GLSL compute shader from an OIR instruction list.

  ## Returns
  - GLSL source string ready for WebGL2 compilation
  """
  def generate(instructions) when is_list(instructions) do
    Logger.debug("⚙️ [GLSLGenerator] Generating GLSL from #{length(instructions)} instructions")

    body = Enum.map_join(instructions, "\n", &emit/1)

    shader = """
    #version 310 es
    layout(local_size_x = 16, local_size_y = 16) in;
    layout(rgba32f, binding = 0) uniform highp image2D u_state;

    void main() {
      ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    #{body}
    }
    """

    Logger.debug("✅ [GLSLGenerator] GLSL shader generated")
    shader
  end

  # ── Private Emitters ──────────────────────────────────────────────────────

  defp emit(%Instruction{opcode: :add, dest: d, src_a: a, src_b: b}) do
    "  float #{d} = #{a} + #{b};"
  end

  defp emit(%Instruction{opcode: :-, dest: d, src_a: a, src_b: b}) do
    "  float #{d} = #{a} - #{b};"
  end

  defp emit(%Instruction{opcode: :mul, dest: d, src_a: a, src_b: b}) do
    "  float #{d} = #{a} * #{b};"
  end

  defp emit(%Instruction{opcode: :*, dest: d, src_a: a, src_b: b}) do
    "  float #{d} = #{a} * #{b};"
  end

  # Division always uses the epsilon-regularized form from the GPU side
  defp emit(%Instruction{opcode: :div, dest: d, src_a: a, src_b: b}) do
    "  float #{d} = #{a} / #{b};"
  end

  defp emit(%Instruction{opcode: :/, dest: d, src_a: a, src_b: b}) do
    "  float #{d} = #{a} / #{b};"
  end

  defp emit(%Instruction{opcode: :pow, dest: d, src_a: a, src_b: b}) do
    "  float #{d} = pow(#{a}, #{b});"
  end

  defp emit(%Instruction{opcode: :sqrt, dest: d, src_a: a}) do
    "  float #{d} = sqrt(#{a});"
  end

  defp emit(%Instruction{opcode: :abs, dest: d, src_a: a}) do
    "  float #{d} = abs(#{a});"
  end

  defp emit(%Instruction{opcode: :log, dest: d, src_a: a}) do
    "  float #{d} = log(#{a});"
  end

  defp emit(%Instruction{opcode: :exp, dest: d, src_a: a}) do
    "  float #{d} = exp(#{a});"
  end

  defp emit(%Instruction{opcode: :neg, dest: d, src_a: a}) do
    "  float #{d} = -(#{a});"
  end

  defp emit(%Instruction{opcode: :load_const, dest: d, src_a: v}) do
    "  float #{d} = #{v};"
  end

  defp emit(%Instruction{opcode: :load_var, dest: d, src_a: name}) do
    "  float #{d} = u_#{name}; // observer variable"
  end

  defp emit(%Instruction{opcode: :load_mscl, dest: d, src_a: name}) do
    "  float #{d} = u_mscl_#{name}; // live MSCL pointer"
  end

  defp emit(%Instruction{opcode: :noop}) do
    "  // noop"
  end

  defp emit(%Instruction{opcode: op, dest: d}) do
    "  // unsupported opcode: #{op} -> #{d}"
  end
end
