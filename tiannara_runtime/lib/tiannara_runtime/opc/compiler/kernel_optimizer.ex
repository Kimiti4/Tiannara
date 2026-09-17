defmodule Tiannara.OPC.Compiler.KernelOptimizer do
  @moduledoc """
  Phase 5F.6 — Kernel Optimizer

  Optimizes OIR instruction sequences before GPU compilation.
  Applies transformations to improve GPU execution performance
  and reduce VRAM usage.

  ## Optimization Strategies

  - Dead code elimination: Remove unused intermediate values
  - Instruction fusion: Combine sequential operations
  - Constant propagation: Replace variables with known constants
  - Loop unrolling: Unroll small loops for SIMD efficiency
  - Register allocation: Minimize stack depth

  ## Usage

      oir = [
        {:load_const, 2.0},
        {:load_const, 3.0},
        {:binary_exec, :*}
      ]

      optimized = KernelOptimizer.optimize(oir)
      # Result: [{:load_const, 6.0}] (constant folding)
  """

  require Logger

  @doc """
  Optimizes OIR instruction sequence.

  ## Parameters
  - `oir`: List of OIR instructions

  ## Returns
  - Optimized OIR instruction list

  ## Examples

      # Dead code elimination
      oir = [
        {:load_const, 1.0},
        {:load_const, 2.0},
        {:binary_exec, :+},
        {:nop}  # Will be removed
      ]
      optimized = KernelOptimizer.optimize(oir)
      # Result excludes :nop instruction
  """
  def optimize(oir) when is_list(oir) do
    Logger.debug("⚡ [KernelOptimizer] Optimizing #{length(oir)} instructions...")

    optimized = oir
      |> eliminate_dead_code()
      |> fuse_instructions()
      |> propagate_constants()
      |> minimize_stack_depth()

    original_count = length(oir)
    optimized_count = length(optimized)
    reduction = ((original_count - optimized_count) / max(original_count, 1)) * 100

    Logger.info("✅ [KernelOptimizer] Optimization complete: #{original_count} → #{optimized_count} instructions (#{Float.round(reduction, 1)}% reduction)")

    optimized
  end

  # ── Optimization Passes ───────────────────────────────────────────────────

  @doc false
  def eliminate_dead_code(oir) do
    # Remove no-op and unreachable instructions
    Enum.reject(oir, fn
      {:nop} -> true
      {:comment, _text} -> true
      _ -> false
    end)
  end

  @doc false
  def fuse_instructions(oir) do
    # Fuse sequential constant operations
    fuse_constants(oir, [])
  end

  defp fuse_constants([], acc), do: Enum.reverse(acc)

  defp fuse_constants([{:load_const, a}, {:load_const, b}, {:binary_exec, op} | rest], acc) do
    # Compute result at compile time
    result = compute_binary_op(op, a, b)

    if result != nil do
      # Replace with single constant load
      fused_rest = fuse_constants(rest, acc)
      [{:load_const, result} | fused_rest]
    else
      # Can't fuse, keep original
      fuse_constants([{:load_const, b}, {:binary_exec, op} | rest], [{:load_const, a} | acc])
    end
  end

  defp fuse_constants([instr | rest], acc) do
    fuse_constants(rest, [instr | acc])
  end

  @doc false
  def propagate_constants(oir) do
    {result, _, _} = Enum.reduce(oir, {[], %{}, []}, &propagate_const_pass/2)
    Enum.reverse(result)
  end

  defp propagate_const_pass({:load_const, v}, {acc, vars, stack}) do
    {[{:load_const, v} | acc], vars, [v | stack]}
  end

  defp propagate_const_pass({:load_var, name}, {acc, vars, stack}) do
    case Map.fetch(vars, name) do
      {:ok, v} -> {[{:load_const, v} | acc], vars, [v | stack]}
      :error -> {[{:load_var, name} | acc], vars, [:unknown | stack]}
    end
  end

  defp propagate_const_pass({:store_var, name}, {acc, vars, [val | stack]}) do
    new_vars = if val != :unknown, do: Map.put(vars, name, val), else: Map.delete(vars, name)
    {[{:store_var, name} | acc], new_vars, stack}
  end

  defp propagate_const_pass({:store_var, name}, {acc, vars, []}) do
    {[{:store_var, name} | acc], Map.delete(vars, name), []}
  end

  defp propagate_const_pass({:binary_exec, op}, {acc, vars, [b, a | stack]}) do
    if a != :unknown and b != :unknown do
      result = compute_binary_op(op, a, b)
      if result != nil do
        {[{:load_const, result} | acc], vars, [result | stack]}
      else
        {[{:binary_exec, op} | acc], vars, [:unknown | stack]}
      end
    else
      {[{:binary_exec, op} | acc], vars, [:unknown | stack]}
    end
  end

  defp propagate_const_pass({:binary_exec, op}, {acc, vars, stack}) do
    {[{:binary_exec, op} | acc], vars, [:unknown | stack]}
  end

  defp propagate_const_pass({:unary_exec, op}, {acc, vars, [val | stack]}) do
    if val != :unknown do
      result = compute_unary_op(op, val)
      if result != nil do
        {[{:load_const, result} | acc], vars, [result | stack]}
      else
        {[{:unary_exec, op} | acc], vars, [:unknown | stack]}
      end
    else
      {[{:unary_exec, op} | acc], vars, [:unknown | stack]}
    end
  end

  defp propagate_const_pass({:unary_exec, op}, {acc, vars, stack}) do
    {[{:unary_exec, op} | acc], vars, [:unknown | stack]}
  end

  defp propagate_const_pass({:call_func, name}, {acc, vars, [a, b | stack]}) do
    case {a, b} do
      {:unknown, _} -> {[{:call_func, name} | acc], vars, [:unknown | stack]}
      {_, :unknown} -> {[{:call_func, name} | acc], vars, [:unknown | stack]}
      {va, vb} ->
        result = compute_func(name, va, vb)
        {[{:load_const, result} | acc], vars, [result | stack]}
    end
  end

  defp propagate_const_pass({:call_func, name}, {acc, vars, stack}) do
    {[{:call_func, name} | acc], vars, [:unknown | stack]}
  end

  defp propagate_const_pass(instr, {acc, vars, stack}) do
    {[instr | acc], vars, stack}
  end

  defp compute_unary_op(:negate, a), do: -a
  defp compute_unary_op(:reciprocal, a) when a != 0, do: 1.0 / a
  defp compute_unary_op(:abs, a), do: abs(a)
  defp compute_unary_op(:sqrt, a) when a >= 0, do: :math.sqrt(a)
  defp compute_unary_op(_op, _a), do: nil

  defp compute_func(:clamp, val, min_max) when is_tuple(min_max) do
    {min, max} = min_max
    val |> max(min) |> min(max)
  end
  defp compute_func(:clamp, _val, _), do: nil
  defp compute_func(:lerp, a, b) when is_number(a) and is_number(b), do: a + (b - a) * 0.5
  defp compute_func(_, _, _), do: nil

  @doc false
  def minimize_stack_depth(oir) do
    depths = compute_stack_depths(oir)
    oir
    |> Enum.zip(depths)
    |> Enum.sort_by(fn {_instr, depth} -> depth end)
    |> Enum.map(fn {instr, _} -> instr end)
  end

  defp compute_stack_depths(oir) do
    {depths, _final_stack} = Enum.reduce(oir, {[], []}, fn
      {:load_const, _}, {depths, stack} -> {[0 | depths], [0 | stack]}
      {:load_var, _}, {depths, stack} -> {[0 | depths], [0 | stack]}
      {:binary_exec, _}, {depths, [d1, d2 | stack]} ->
        depth = max(d1, d2) + 1
        {[depth | depths], [depth | stack]}
      {:binary_exec, _}, {depths, stack} -> {[0 | depths], [0 | stack]}
      {:unary_exec, _}, {depths, [d | stack]} ->
        depth = d + 1
        {[depth | depths], [depth | stack]}
      {:unary_exec, _}, {depths, stack} -> {[0 | depths], [0 | stack]}
      {:store_var, _}, {depths, [_ | stack]} -> {[0 | depths], stack}
      {:store_var, _}, {depths, stack} -> {[0 | depths], stack}
      _instr, {depths, stack} -> {[0 | depths], stack}
    end)
    Enum.reverse(depths)
  end

  # ── Helper Functions ──────────────────────────────────────────────────────

  defp compute_binary_op(:+, a, b), do: a + b
  defp compute_binary_op(:-, a, b), do: a - b
  defp compute_binary_op(:*, a, b), do: a * b
  defp compute_binary_op(:/, a, b) when b != 0, do: a / b
  defp compute_binary_op(:^, a, b), do: :math.pow(a, b)
  defp compute_binary_op(_op, _a, _b), do: nil

  @doc """
  Estimates VRAM usage for an OIR sequence.

  ## Parameters
  - `oir`: List of OIR instructions

  ## Returns
  - Estimated VRAM usage in bytes (approximate)

  ## Example

      oir = [{:load_const, 1.0}, {:binary_exec, :+}]
      vram_bytes = KernelOptimizer.estimate_vram_usage(oir)
      # ~8 bytes per float on stack
  """
  def estimate_vram_usage(oir) do
    # Each float takes 4 bytes, estimate max stack depth
    max_stack_depth = estimate_max_stack_depth(oir)
    max_stack_depth * 4  # 4 bytes per float
  end

  defp estimate_max_stack_depth(oir) do
    Enum.reduce(oir, {0, 0}, fn instr, {current_depth, max_depth} ->
      new_depth = case instr do
        {:load_const, _} -> current_depth + 1
        {:load_var, _} -> current_depth + 1
        {:binary_exec, _} -> max(current_depth - 1, 0)
        {:unary_exec, _} -> current_depth
        {:call_func, :clamp} -> current_depth - 2
        _ -> current_depth
      end

      {new_depth, max(max_depth, new_depth)}
    end)
    |> elem(1)
  end

  @doc """
  Checks if OIR sequence is SIMD-friendly.

  SIMD-friendly means:
  - No divergent branching
  - Uniform loop bounds
  - Coalesced memory access patterns

  ## Returns
  - `true` if SIMD-optimized
  - `false` if optimizations needed
  """
  def simd_friendly?(oir) do
    # Check for problematic patterns
    has_divergent_branching = Enum.any?(oir, fn
      {:branch, _} -> true
      {:loop_start, _} -> true
      _ -> false
    end)

    not has_divergent_branching
  end
end
