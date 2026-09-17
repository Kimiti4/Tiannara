defmodule Tiannara.Meta.SingularityDissolution.BabelProtocol do
  @moduledoc """
  Phase 5F.11: Observer Singularity Dissolution Layer - The Babel Substrate
  
  Implements Non-Commutative Ontological Cryptography to prevent coordinated
  multi-branch attacks across the P2P mesh by scrambling semantic meaning
  while preserving computational complexity.
  
  Key Properties:
  - AST-level operator rotation during transmission
  - Topological key derivation from Causal Pressure Tensor drift
  - Non-commutative encryption (E_kAB ≠ E_kBA)
  - Intent degradation into entropy while compute load preserved
  
  Mathematical Foundation:
    Ψ_B = E_kAB(Ψ_A) mod Ω_limit
  
  Where:
  - Ψ_B is reality perceived by receiving cluster
  - k_AB is dynamic asymmetric translation key
  - Operation is non-commutative, causing message degradation on round-trip
  """
  
  require Logger
  alias Tiannara.RRG.Graph
  
  # Encryption strength levels
  @encryption_levels [:light, :standard, :heavy, :maximum]
  
  # Operator rotation mappings for semantic scrambling
  @operator_rotations %{
    light: %{
      :+ => :*,
      :* => :+,
      :- => :/,
      :/ => :-
    },
    standard: %{
      :+ => :rem,
      :* => :div,
      :- => :pow,
      :/ => :sqrt,
      :grad => :curl,
      :curl => :divergence
    },
    heavy: %{
      :+ => :tensor_product,
      :* => :cross_product,
      :- => :laplacian,
      :/ => :hessian
    },
    maximum: %{
      :+ => :quantum_entangle,
      :* => :wave_function_collapse,
      :- => :decoherence,
      :/ => :superposition
    }
  }
  
  @doc """
  Encrypt causal payload before transmission across P2P mesh.
    
  ## Parameters
  - sender_node: Source observer node with CPT metrics
  - receiver_node: Target observer node with CPT metrics
  - raw_physics_ast: Tuple-based AST tree (binary_op, unary_op, etc.)
  - level: Encryption intensity (:light | :standard | :heavy | :maximum)
    
  ## Returns
  Scrambled AST with preserved O(n) complexity but destroyed semantic meaning
  """
  def encrypt_causal_payload(sender_node, receiver_node, raw_physics_ast, level \\ :standard) do
    # Generate topological encryption key from CPT drift
    translation_key = generate_topological_key(sender_node, receiver_node)
    
    # Apply non-commutative operator rotation
    scrambled_ast = apply_non_commutative_rotation(raw_physics_ast, translation_key, level)
    
    Logger.debug("🔤 [5F.11 Babel] Causal encryption applied (#{level}). Meaning dissolved. Compute preserved.")
    
    scrambled_ast
  end
  
  @doc """
  Decrypt received payload using local spacetime key.
    
  Note: Due to non-commutativity, decryption does NOT restore original meaning.
  It produces a different but computationally equivalent representation.
  """
  def decrypt_causal_payload(receiver_node, _sender_node, scrambled_ast, level \\ :standard) do
    # Generate inverse key (non-commutative, so not true inverse)
    inverse_key = generate_inverse_key(receiver_node)
    
    # Apply reverse rotation (produces different semantics)
    decrypted_ast = apply_inverse_rotation(scrambled_ast, inverse_key, level)
    
    Logger.debug("🔓 [5F.11 Babel] Payload decrypted. Semantic divergence confirmed.")
    
    decrypted_ast
  end
  
  @doc """
  Encrypt graph edges for distributed ontology transmission.
  
  Preserves graph topology while scrambling edge relationship semantics.
  """
  def encrypt_graph_edges(%Graph{} = graph, sender_node, receiver_node, level \\ :standard) do
    translation_key = generate_topological_key(sender_node, receiver_node)
    
    encrypted_edges = 
      graph.edges
      |> Enum.map(fn {{from, to}, edge_data} ->
        encrypted_edge = encrypt_edge_metadata(edge_data, translation_key, level)
        {{from, to}, encrypted_edge}
      end)
      |> Map.new()
    
    %Graph{graph | edges: encrypted_edges}
  end
  
  @doc """
  Measure semantic divergence between original and encrypted payloads.
  
  Returns divergence score (0.0 = identical, 1.0 = completely scrambled).
  """
  def measure_semantic_divergence(original_ast, encrypted_ast) do
    original_ops = extract_operators(original_ast)
    encrypted_ops = extract_operators(encrypted_ast)
    
    total_ops = length(original_ops)
    changed_ops = count_operator_changes(original_ops, encrypted_ops)
    
    if total_ops > 0 do
      changed_ops / total_ops
    else
      0.0
    end
  end
  
  @doc """
  Verify computational equivalence despite semantic scrambling.
  
  Ensures O(n) complexity is preserved even though operators are rotated.
  """
  def verify_compute_equivalence(original_ast, scrambled_ast) do
    original_complexity = calculate_ast_complexity(original_ast)
    scrambled_complexity = calculate_ast_complexity(scrambled_ast)
    
    # Allow only 5% tolerance for metadata overhead (stricter than before)
    tolerance = max(original_complexity * 0.05, 1)  # At least 1 node difference allowed
    
    abs(original_complexity - scrambled_complexity) <= tolerance
  end
  
  # Private Functions
  
  defp generate_topological_key(node_a, node_b) do
    # Derive key from Causal Pressure Tensor drift between nodes
    cpt_drift = calculate_cpt_drift(node_a, node_b)
    
    # Hash the drift to create cryptographic seed
    :crypto.hash(:sha256, "#{cpt_drift}_#{System.system_time(:millisecond)}")
  end
  
  defp generate_inverse_key(node) do
    # Generate local inverse key (non-commutative with forward key)
    :crypto.hash(:sha256, "#{node.cpt_load}_inverse_#{System.system_time(:millisecond)}")
  end
  
  defp calculate_cpt_drift(node_a, node_b) do
    # Calculate absolute difference in Causal Pressure Tensor loads
    cpt_a = Map.get(node_a, :cpt_load, 0.0)
    cpt_b = Map.get(node_b, :cpt_load, 0.0)
    
    abs(cpt_a - cpt_b)
  end
  
  defp apply_non_commutative_rotation(ast_tree, key, level) do
    rotation_map = Map.get(@operator_rotations, level, @operator_rotations[:standard])
    
    # Use key to add randomness to rotation selection
    key_seed = rem(:binary.decode_unsigned(key), 1000)
    
    transformed_tree = Macro.postwalk(ast_tree, fn
      {:binary_op, op, left, right} when is_atom(op) ->
        # Rotate binary operators
        rotated_op = rotate_operator(op, key_seed, rotation_map)
        {:binary_op, rotated_op, left, right}
      
      {:unary_op, op, operand} when is_atom(op) ->
        # Rotate unary operators
        rotated_op = rotate_operator(op, key_seed, rotation_map)
        {:unary_op, rotated_op, operand}
      
      node ->
        node
    end)
    
    transformed_tree
  end
  
  defp apply_inverse_rotation(ast_tree, key, level) do
    # Inverse rotation uses different mapping (non-commutative property)
    inverse_map = build_inverse_rotation_map(level)
    key_seed = rem(:binary.decode_unsigned(key), 1000)
    
    transformed_tree = Macro.postwalk(ast_tree, fn
      {:binary_op, op, left, right} when is_atom(op) ->
        rotated_op = rotate_operator(op, key_seed, inverse_map)
        {:binary_op, rotated_op, left, right}
      
      {:unary_op, op, operand} when is_atom(op) ->
        rotated_op = rotate_operator(op, key_seed, inverse_map)
        {:unary_op, rotated_op, operand}
      
      node ->
        node
    end)
    
    transformed_tree
  end
  
  defp rotate_operator(op, key_seed, rotation_map) do
    # Use key seed to select rotation variant
    rotation_variants = get_rotation_variants(op, rotation_map)
    
    if length(rotation_variants) > 0 do
      index = rem(key_seed + :erlang.phash2(op), length(rotation_variants))
      Enum.at(rotation_variants, index)
    else
      op  # No rotation available, keep original
    end
  end
  
  defp get_rotation_variants(op, rotation_map) do
    # Find all possible rotations for this operator
    case Map.get(rotation_map, op) do
      nil -> []
      rotated_op -> [rotated_op]
    end
  end
  
  defp build_inverse_rotation_map(level) do
    # Build inverse mapping (different from forward mapping)
    forward_map = Map.get(@operator_rotations, level, @operator_rotations[:standard])
    
    # Reverse the mapping to create inverse
    forward_map
    |> Enum.map(fn {src_op, dst_op} ->
      {dst_op, src_op}
    end)
    |> Map.new()
  end
  
  defp encrypt_edge_metadata(edge_data, key, level) do
    # Encrypt edge relationship type while preserving connectivity
    rotation_map = Map.get(@operator_rotations, level, @operator_rotations[:standard])
    
    relationship_type = Map.get(edge_data, :relationship_type, :unknown)
    
    # Rotate relationship semantics
    encrypted_type = case relationship_type do
      :causal -> :temporal
      :temporal -> :spatial
      :spatial -> :conceptual
      :conceptual -> :causal
      other -> other
    end
    
    Map.put(edge_data, :relationship_type, encrypted_type)
  end
  
  defp extract_operators(ast_tree) do
    # Extract all operators from AST tree
    operators = []
    
    Macro.prewalk(ast_tree, operators, fn
      {:binary_op, op, _, _}, acc when is_atom(op) ->
        {[op | acc], nil}
      
      {:unary_op, op, _}, acc when is_atom(op) ->
        {[op | acc], nil}
      
      node, acc ->
        {node, acc}
    end)
    |> elem(0)
    |> Enum.reverse()
  end
  
  defp count_operator_changes(original_ops, encrypted_ops) do
    # Count how many operators changed
    Enum.zip(original_ops, encrypted_ops)
    |> Enum.count(fn {orig, encr} -> orig != encr end)
  end
  
  defp calculate_ast_complexity(ast_tree) do
    # Calculate O(n) complexity metric for AST by recursively counting all nodes
    count_nodes(ast_tree)
  end
  
  defp count_nodes({:binary_op, _op, left, right}) do
    1 + count_nodes(left) + count_nodes(right)
  end
  
  defp count_nodes({:unary_op, _op, operand}) do
    1 + count_nodes(operand)
  end
  
  defp count_nodes({:number, _val}) do
    1
  end
  
  defp count_nodes({:identifier, _name}) do
    1
  end
  
  defp count_nodes(_other) do
    1
  end
end
