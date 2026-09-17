defmodule TiannaraRuntime.Mathematics.Canonicalization do
  @moduledoc """
  Phase 16.X.3 — Expression Canonicalization

  Every expression has exactly one canonical representation.
  Equivalent expressions produce identical hashes.

  Canonical forms:
    - Sorted operands (commutative normalization: a+b → b+a sorted)
    - Constant folding (3+5 → 8, 2*3 → 6)
    - Identity elimination (x+0 → x, x*1 → x, x*0 → 0)
    - Deterministic tree structure (depth-first, left-to-right)
  """

  alias TiannaraRuntime.Mathematics.Ontology.SymbolicExpression

  @doc "Canonicalize an expression to its unique canonical form."
  @spec canonicalize(SymbolicExpression.t()) :: SymbolicExpression.t()
  def canonicalize(%SymbolicExpression{type: :constant} = expr), do: expr

  def canonicalize(%SymbolicExpression{type: :variable} = expr), do: expr

  def canonicalize(%SymbolicExpression{type: :operator, value: op, children: children} = expr) do
    canonical_children = Enum.map(children || [], &canonicalize/1)

    sorted = sort_commutative_children(expr, op, canonical_children)
    folded = fold_constants(sorted)
    result = eliminate_identities(folded)

    %{result | metadata: expr.metadata}
  end

  def canonicalize(%SymbolicExpression{type: :function, children: args} = expr) do
    canonical_args = Enum.map(args || [], &canonicalize/1)
    %{expr | children: canonical_args}
  end

  # ---------------------------------------------------------------------------
  # Commutative Normalization
  # ---------------------------------------------------------------------------

  @doc """
  Sort children of commutative operators (+, *) deterministically.

  Equivalent expressions like a+b and b+a produce identical
  canonical forms after sorting.
  """
  @spec sort_commutative(SymbolicExpression.t()) :: SymbolicExpression.t()
  def sort_commutative(%SymbolicExpression{type: :operator, value: op} = expr) when op in [:+, :*] do
    sorted = Enum.sort_by(expr.children || [], &expression_sort_key/1)
    %{expr | children: sorted}
  end

  def sort_commutative(%SymbolicExpression{} = expr), do: expr

  # ---------------------------------------------------------------------------
  # Canonical Hash
  # ---------------------------------------------------------------------------

  @doc "Compute the canonical hash of an expression (equivalent expressions → identical hashes)."
  @spec canonical_hash(SymbolicExpression.t()) :: String.t()
  def canonical_hash(%SymbolicExpression{} = expr) do
    canonical = canonicalize(expr)
    SymbolicExpression.id(canonical)
  end

  @doc "Check if two expressions are canonically equivalent (same hash)."
  @spec canonically_equivalent?(SymbolicExpression.t(), SymbolicExpression.t()) :: boolean()
  def canonically_equivalent?(%SymbolicExpression{} = a, %SymbolicExpression{} = b) do
    canonical_hash(a) == canonical_hash(b)
  end

  # ---------------------------------------------------------------------------
  # Internal: Commutative Sorting
  # ---------------------------------------------------------------------------

  defp sort_commutative_children(%SymbolicExpression{type: :operator} = expr, op, children)
       when op in [:+, :*] do
    sorted = Enum.sort_by(children, &expression_sort_key/1)
    %{expr | children: sorted}
  end

  defp sort_commutative_children(%SymbolicExpression{} = expr, _op, children) do
    %{expr | children: children}
  end

  defp expression_sort_key(%SymbolicExpression{type: :constant, value: v}), do: {:constant, v, ""}
  defp expression_sort_key(%SymbolicExpression{type: :variable, value: v}), do: {:variable, 0, v}
  defp expression_sort_key(%SymbolicExpression{type: :function, value: f}), do: {:function, 0, f}
  defp expression_sort_key(%SymbolicExpression{type: :operator, value: op}), do: {:operator, 0, to_string(op)}

  # ---------------------------------------------------------------------------
  # Internal: Constant Folding
  # ---------------------------------------------------------------------------

  defp fold_constants(%SymbolicExpression{type: :operator, value: :+, children: children} = expr) do
    {consts, vars} = Enum.split_with(children, fn c -> c.type == :constant end)

    case consts do
      [] -> expr
      [single] ->
        %{expr | children: [single | vars]}
      multiple ->
        total = Enum.reduce(multiple, 0, fn c, acc -> acc + (c.value || 0) end)
        if total == 0 do
          %{expr | children: vars}
        else
          const_expr = %SymbolicExpression{type: :constant, value: total, children: [], metadata: %{}}
          rest =
            case vars do
              [] -> [const_expr]
              _ -> [const_expr | vars]
            end
          %{expr | children: rest}
        end
    end
  end

  defp fold_constants(%SymbolicExpression{type: :operator, value: :*, children: children} = expr) do
    {consts, vars} = Enum.split_with(children, fn c -> c.type == :constant end)

    case consts do
      [] -> expr
      [single] ->
        if single.value == 0 do
          %{expr | children: [single]}
        else
          %{expr | children: [single | vars]}
        end
      multiple ->
        product = Enum.reduce(multiple, 1, fn c, acc -> acc * (c.value || 1) end)
        const_expr = %SymbolicExpression{type: :constant, value: product, children: [], metadata: %{}}

        if product == 0 do
          %{expr | children: [const_expr]}
        else
          rest =
            case vars do
              [] -> [const_expr]
              _ -> [const_expr | vars]
            end
          %{expr | children: rest}
        end
    end
  end

  defp fold_constants(%SymbolicExpression{} = expr), do: expr

  # ---------------------------------------------------------------------------
  # Internal: Identity Elimination
  # ---------------------------------------------------------------------------

  defp eliminate_identities(%SymbolicExpression{type: :operator, value: :+, children: children} = expr) do
    non_zero = Enum.reject(children, fn c -> c.type == :constant and c.value == 0 end)

    case non_zero do
      [] -> %SymbolicExpression{type: :constant, value: 0, children: [], metadata: %{}}
      [single] -> single
      result -> %{expr | children: result}
    end
  end

  defp eliminate_identities(%SymbolicExpression{type: :operator, value: :*, children: children} = expr) do
    has_zero = Enum.any?(children, fn c -> c.type == :constant and c.value == 0 end)

    if has_zero do
      %SymbolicExpression{type: :constant, value: 0, children: [], metadata: %{}}
    else
      non_one = Enum.reject(children, fn c -> c.type == :constant and c.value == 1 end)

      case non_one do
        [] -> %SymbolicExpression{type: :constant, value: 1, children: [], metadata: %{}}
        [single] -> single
        result -> %{expr | children: result}
      end
    end
  end

  defp eliminate_identities(%SymbolicExpression{} = expr), do: expr
end
