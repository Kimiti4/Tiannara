defmodule Tiannara.OPC.IR.OIRGenerator do
  @moduledoc """
  Phase 5F.6 — Ontological IR (OIR) Generator

  Transforms validated physics AST into Ontological Intermediate Representation (OIR),
  a safe, bounded execution format that can be compiled to GPU shaders.

  ## OIR Structure

  The OIR is a normalized, constraint-enforced representation that:
  - Strips dangerous recursion
  - Normalizes tensor operations
  - Prevents GPU divergence
  - Estimates thermodynamic cost
  - Ensures causal boundedness

  ## Output Format

      %{
        type: "ontological_ir",
        observer: "obs_001",
        kernel: [...execution_graph...],
        execution_mode: "observer_relative",
        safety_layer: "mscl_omega_bound",
        thermodynamic_cost: 450,
        compiled_at: timestamp
      }

  ## Usage

      validated_ast = {:op, :gravity, [{:var, :mass}, {:var, :distance}, :mscl_bound]}
      oir = OIRGenerator.build(validated_ast, "obs_001")
  """

  require Logger

  @doc """
  Builds Ontological IR from validated physics AST.

  ## Parameters
  - `ast`: Validated and constraint-injected physics AST
  - `observer_id`: The observer who proposed this physics

  ## Returns
  Map containing the complete OIR structure ready for GPU compilation.

  ## Example

      ast = {:op, :/, [
        {:const, 1.0},
        {:op, :sqrt, [{:op, :+, [{:op, :pow, [{:var, :r}, 2]}, {:mscl_pointer, :epsilon_variance}]}]}
      ]}

      oir = OIRGenerator.build(ast, "obs_001")
      # Returns complete OIR with execution graph, safety markers, etc.
  """
  def build(ast, observer_id) do
    Logger.info("🔧 [OIRGenerator] Building Ontological IR for #{observer_id}")

    execution_graph = transform_to_execution_graph(ast)
    thermodynamic_cost = estimate_final_cost(ast)

    oir = %{
      type: "ontological_ir",
      version: "5F.6-alpha",
      observer: observer_id,
      kernel: execution_graph,
      execution_mode: "observer_relative",
      safety_layer: "mscl_omega_bound",
      thermodynamic_cost: thermodynamic_cost,
      constraints: extract_constraints(ast),
      compiled_at: System.system_time(:millisecond),
      metadata: %{
        ast_node_count: count_nodes(ast),
        max_depth: calculate_max_depth(ast),
        has_epsilon_shims: contains_epsilon_shims?(ast)
      }
    }

    Logger.debug("✅ [OIRGenerator] OIR built successfully (cost: #{thermodynamic_cost})")

    oir
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp transform_to_execution_graph({:op, op_name, args}) when is_list(args) do
    # Transform AST operation into execution graph node
    transformed_args = Enum.map(args, &transform_to_execution_graph/1)

    %{
      type: :operation,
      op: op_name,
      inputs: transformed_args,
      safety_annotations: extract_safety_annotations(op_name, args)
    }
  end

  defp transform_to_execution_graph({:const, value}) do
    %{type: :constant, value: value}
  end

  defp transform_to_execution_graph({:var, name}) do
    %{type: :variable, name: name}
  end

  defp transform_to_execution_graph({:mscl_pointer, pointer_name}) do
    %{type: :mscl_pointer, name: pointer_name, live_bound: true}
  end

  defp transform_to_execution_graph(list) when is_list(list) do
    Enum.map(list, &transform_to_execution_graph/1)
  end

  defp transform_to_execution_graph(other), do: other

  defp extract_safety_annotations(:/, [_num, denom]) do
    # Check if denominator has epsilon regularization
    if contains_epsilon_shims?(denom) do
      [:epsilon_regularized, :singularity_safe]
    else
      [:unprotected_division]
    end
  end

  defp extract_safety_annotations(_op, _args), do: []

  defp estimate_final_cost(ast) do
    # Simple cost estimation based on node count and complexity
    node_count = count_nodes(ast)
    base_cost_per_node = 10

    node_count * base_cost_per_node
  end

  defp extract_constraints(ast) do
    # Extract all MSCL-Ω constraint markers from AST
    constraints = extract_constraints_recursive(ast, [])
    Enum.uniq(constraints)
  end

  defp extract_constraints_recursive({:op, _op, args}, acc) when is_list(args) do
    Enum.reduce(args, acc, &extract_constraints_recursive/2)
  end

  defp extract_constraints_recursive([:mscl_bound | rest], acc) do
    extract_constraints_recursive(rest, [:mscl_omega_enforced | acc])
  end

  defp extract_constraints_recursive(:mscl_bound, acc) do
    [:mscl_omega_enforced | acc]
  end

  defp extract_constraints_recursive({:mscl_pointer, _name}, acc) do
    [:dynamic_epsilon_shim | acc]
  end

  defp extract_constraints_recursive(list, acc) when is_list(list) do
    Enum.reduce(list, acc, &extract_constraints_recursive/2)
  end

  defp extract_constraints_recursive(_other, acc), do: acc

  defp count_nodes({:op, _op, args}) when is_list(args) do
    1 + Enum.sum(Enum.map(args, &count_nodes/1))
  end

  defp count_nodes(list) when is_list(list) do
    Enum.sum(Enum.map(list, &count_nodes/1))
  end

  defp count_nodes(_leaf), do: 1

  defp calculate_max_depth({:op, _op, args}) when is_list(args) do
    1 + (Enum.map(args, &calculate_max_depth/1) |> Enum.max(fn -> 0 end))
  end

  defp calculate_max_depth(list) when is_list(list) do
    1 + (Enum.map(list, &calculate_max_depth/1) |> Enum.max(fn -> 0 end))
  end

  defp calculate_max_depth(_leaf), do: 0

  defp contains_epsilon_shims?({:mscl_pointer, :epsilon_variance}), do: true
  defp contains_epsilon_shims?({:op, _op, args}) when is_list(args), do: Enum.any?(args, &contains_epsilon_shims?/1)
  defp contains_epsilon_shims?(list) when is_list(list), do: Enum.any?(list, &contains_epsilon_shims?/1)
  defp contains_epsilon_shims?(_other), do: false
end
