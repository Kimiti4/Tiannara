defmodule TiannaraRuntime.Mathematics.SymbolicEngine do
  @moduledoc """
  Phase 16.X.3 — Deterministic Symbolic Computation Engine

  A mathematical compiler that transforms expressions while preserving
  correctness. Every transformation is deterministic.

  Expression model: immutable trees with nodes Constant, Variable, Operator,
  Function, Matrix, Vector, Polynomial, Expression.

  No numerical approximations unless explicitly requested.
  No theorem discovery. No certification of mathematics.

  Operations: simplify, expand, factor, substitute, differentiate,
  integrate, solve, matrix operations, polynomial operations.

  Metadata is frozen and stored with every expression: origin, purpose,
  owner, domain, lineage, dependencies.

  Replay: uses only ontology + rewrite rules + canonical ordering +
  deterministic context. Produces identical symbolic outputs.
  """

  alias TiannaraRuntime.Mathematics.Ontology.SymbolicExpression

  @type expression :: TiannaraRuntime.Mathematics.Ontology.SymbolicExpression.t()
  @type expression_type :: :constant | :variable | :function | :operator

  # ---------------------------------------------------------------------------
  # Expression Construction
  # ---------------------------------------------------------------------------

  @doc "Create a constant expression."
  @spec constant(term(), keyword()) :: {:ok, expression()} | {:error, String.t()}
  def constant(value, opts \\ []) do
    SymbolicExpression.new(:constant, value, opts)
  end

  @doc "Create a variable expression."
  @spec variable(String.t(), keyword()) :: {:ok, expression()} | {:error, String.t()}
  def variable(name, opts \\ []) do
    SymbolicExpression.new(:variable, name, opts)
  end

  @doc "Create an operator expression with children."
  @spec operator(atom(), [expression()], keyword()) :: {:ok, expression()} | {:error, String.t()}
  def operator(op, children, opts \\ []) when is_atom(op) and is_list(children) do
    SymbolicExpression.new(:operator, op, Keyword.put(opts, :children, children))
  end

  @doc "Create a function expression with arguments."
  @spec function(String.t(), [expression()], keyword()) :: {:ok, expression()} | {:error, String.t()}
  def function(name, args, opts \\ []) when is_binary(name) and is_list(args) do
    SymbolicExpression.new(:function, name, Keyword.put(opts, :children, args))
  end

  # ---------------------------------------------------------------------------
  # Expression ID / Hash
  # ---------------------------------------------------------------------------

  @doc "Compute the deterministic content-addressed hash of an expression."
  @spec expression_hash(expression()) :: String.t()
  def expression_hash(%SymbolicExpression{} = expr) do
    SymbolicExpression.id(expr)
  end

  @doc "Check if two expressions have the same content hash."
  @spec equivalent?(expression(), expression()) :: boolean()
  def equivalent?(%SymbolicExpression{} = a, %SymbolicExpression{} = b) do
    expression_hash(a) == expression_hash(b)
  end

  # ---------------------------------------------------------------------------
  # Simplify
  # ---------------------------------------------------------------------------

  @doc "Simplify an expression using built-in algebraic rules."
  @spec simplify(expression()) :: {:ok, expression()} | {:error, String.t()}
  def simplify(%SymbolicExpression{type: :constant} = expr), do: {:ok, expr}

  def simplify(%SymbolicExpression{type: :variable} = expr), do: {:ok, expr}

  def simplify(%SymbolicExpression{type: :operator, value: :+, children: children} = expr) do
    {:ok, simplified} = simplify_all(children)
    result = simplify_add(simplified)
    {:ok, attach_metadata(result, expr)}
  end

  def simplify(%SymbolicExpression{type: :operator, value: :*, children: children} = expr) do
    {:ok, simplified} = simplify_all(children)
    result = simplify_multiply(simplified)
    {:ok, attach_metadata(result, expr)}
  end

  def simplify(%SymbolicExpression{type: :operator, value: op, children: children} = expr) do
    {:ok, simplified} = simplify_all(children)
    expr_meta = SymbolicExpression.new(:operator, op, children: simplified, metadata: expr.metadata)
    case expr_meta do
      {:ok, e} -> {:ok, e}
      {:error, _} -> {:ok, %{expr | children: simplified}}
    end
  end

  def simplify(%SymbolicExpression{type: :function, children: args} = expr) do
    {:ok, simplified_args} = simplify_all(args)
    expr_meta = SymbolicExpression.new(:function, expr.value, children: simplified_args, metadata: expr.metadata)
    case expr_meta do
      {:ok, e} -> {:ok, e}
      {:error, _} -> {:ok, %{expr | children: simplified_args}}
    end
  end

  # ---------------------------------------------------------------------------
  # Expand
  # ---------------------------------------------------------------------------

  @doc "Expand products of sums (distributive law)."
  @spec expand(expression()) :: {:ok, expression()} | {:error, String.t()}
  def expand(%SymbolicExpression{type: :constant} = expr), do: {:ok, expr}
  def expand(%SymbolicExpression{type: :variable} = expr), do: {:ok, expr}

  def expand(%SymbolicExpression{type: :operator, value: :*, children: [left, right]} = expr) do
    with {:ok, left_exp} <- expand(left),
         {:ok, right_exp} <- expand(right) do
      do_expand_product(left_exp, right_exp, expr.metadata)
    end
  end

  def expand(%SymbolicExpression{type: :operator, value: op, children: children} = expr) do
    {:ok, expanded_children} = expand_all(children)

    SymbolicExpression.new(:operator, op, children: expanded_children, metadata: expr.metadata)
    |> case do
      {:ok, e} -> {:ok, e}
      _ -> {:ok, %{expr | children: expanded_children}}
    end
  end

  def expand(%SymbolicExpression{type: :function, children: args} = expr) do
    {:ok, expanded_args} = expand_all(args)
    SymbolicExpression.new(:function, expr.value, children: expanded_args, metadata: expr.metadata)
  end

  # ---------------------------------------------------------------------------
  # Factor
  # ---------------------------------------------------------------------------

  @doc "Factor common terms from sums."
  @spec factor(expression()) :: {:ok, expression()} | {:error, String.t()}
  def factor(%SymbolicExpression{type: :operator, value: :+, children: children} = expr) do
    factors =
      children
      |> Enum.map(fn child -> extract_factors(child) end)
      |> Enum.filter(fn fl -> fl != [] end)

    common = find_common_factors(factors)
    factor_out(expr, common)
  end

  def factor(%SymbolicExpression{} = expr), do: {:ok, expr}

  # ---------------------------------------------------------------------------
  # Substitute
  # ---------------------------------------------------------------------------

  @doc "Substitute a variable with an expression throughout."
  @spec substitute(expression(), String.t(), expression()) :: {:ok, expression()} | {:error, String.t()}
  def substitute(%SymbolicExpression{type: :variable, value: varname} = expr, target, replacement)
      when is_binary(target) do
    if varname == target do
      {:ok, replacement}
    else
      {:ok, expr}
    end
  end

  def substitute(%SymbolicExpression{type: :operator, children: children} = expr, target, replacement)
      when is_binary(target) do
    results =
      Enum.map(children, fn child ->
        case substitute(child, target, replacement) do
          {:ok, e} -> e
          _ -> child
        end
      end)

    SymbolicExpression.new(:operator, expr.value, children: results, metadata: expr.metadata)
  end

  def substitute(%SymbolicExpression{type: :function, children: args} = expr, target, replacement)
      when is_binary(target) do
    results =
      Enum.map(args, fn arg ->
        case substitute(arg, target, replacement) do
          {:ok, e} -> e
          _ -> arg
        end
      end)

    SymbolicExpression.new(:function, expr.value, children: results, metadata: expr.metadata)
  end

  def substitute(%SymbolicExpression{} = expr, _target, _replacement), do: {:ok, expr}

  # ---------------------------------------------------------------------------
  # Differentiate
  # ---------------------------------------------------------------------------

  @doc "Symbolically differentiate an expression with respect to a variable."
  @spec differentiate(expression(), String.t()) :: {:ok, expression()} | {:error, String.t()}
  def differentiate(%SymbolicExpression{type: :constant} = _expr, _var) do
    SymbolicExpression.new(:constant, 0)
  end

  def differentiate(%SymbolicExpression{type: :variable, value: varname} = _expr, var)
      when is_binary(var) do
    if varname == var do
      SymbolicExpression.new(:constant, 1)
    else
      SymbolicExpression.new(:constant, 0)
    end
  end

  def differentiate(%SymbolicExpression{type: :function, value: "sin", children: [arg]} = expr, var)
      when is_binary(var) do
    with {:ok, darg} <- differentiate(arg, var) do
      SymbolicExpression.new(:function, "cos", children: [arg], metadata: expr.metadata)
      |> elem(1)
      |> then(fn cos_expr ->
        SymbolicExpression.new(:operator, :*, children: [cos_expr, darg], metadata: expr.metadata)
      end)
    end
  end

  def differentiate(%SymbolicExpression{type: :function, value: "cos", children: [arg]} = expr, var)
      when is_binary(var) do
    with {:ok, darg} <- differentiate(arg, var) do
      SymbolicExpression.new(:function, "sin", children: [arg], metadata: expr.metadata)
      |> elem(1)
      |> then(fn sin_expr ->
        SymbolicExpression.new(:operator, :*, children: [
          SymbolicExpression.new(:constant, -1) |> elem(1),
          sin_expr,
          darg
        ], metadata: expr.metadata)
      end)
    end
  end

  def differentiate(%SymbolicExpression{type: :operator, value: :+, children: children} = expr, var)
      when is_binary(var) do
    results =
      Enum.map(children, fn child ->
        case differentiate(child, var) do
          {:ok, e} -> e
          _ -> child
        end
      end)

    SymbolicExpression.new(:operator, :+, children: results, metadata: expr.metadata)
  end

  def differentiate(%SymbolicExpression{type: :operator, value: :*, children: [left, right]} = expr, var)
      when is_binary(var) do
    with {:ok, dl} <- differentiate(left, var),
         {:ok, dr} <- differentiate(right, var) do
      left_expr = SymbolicExpression.new(:operator, :*, children: [dl, right], metadata: expr.metadata) |> elem(1)
      right_expr = SymbolicExpression.new(:operator, :*, children: [left, dr], metadata: expr.metadata) |> elem(1)
      SymbolicExpression.new(:operator, :+, children: [left_expr, right_expr], metadata: expr.metadata)
    end
  end

  def differentiate(%SymbolicExpression{} = expr, _var) do
    SymbolicExpression.new(:constant, 0, metadata: expr.metadata)
  end

  # ---------------------------------------------------------------------------
  # Integrate (basic antiderivatives)
  # ---------------------------------------------------------------------------

  @doc """
  Symbolically integrate an expression.

  Supports basic polynomial antiderivatives. Integration is bounded:
  fails closed for unsupported forms.
  """
  @spec integrate(expression(), String.t()) :: {:ok, expression()} | {:error, String.t()}
  def integrate(%SymbolicExpression{type: :constant, value: c} = _expr, var) when is_binary(var) do
    SymbolicExpression.new(:operator, :*, children: [
      SymbolicExpression.new(:constant, c) |> elem(1),
      SymbolicExpression.new(:variable, var) |> elem(1)
    ])
  end

  def integrate(%SymbolicExpression{type: :variable, value: varname} = expr, var) when is_binary(var) do
    if varname == var do
      power = SymbolicExpression.new(:constant, 2) |> elem(1)
      SymbolicExpression.new(:operator, :/, children: [
        SymbolicExpression.new(:operator, :^, children: [expr, power]) |> elem(1),
        power
      ])
    else
      SymbolicExpression.new(:operator, :*, children: [
        expr,
        SymbolicExpression.new(:variable, var) |> elem(1)
      ])
    end
  end

  def integrate(%SymbolicExpression{} = _expr, _var) do
    {:error, "integration of non-polynomial form not supported in Iteration 1"}
  end

  # ---------------------------------------------------------------------------
  # Solve (basic linear equations)
  # ---------------------------------------------------------------------------

  @doc """
  Solve a simple linear equation for a variable.

  Supports linear equations of the form: ax + b = 0
  Returns the solution expression or {:error, :unsupported}.
  """
  @spec solve(expression(), String.t()) :: {:ok, expression()} | {:error, String.t()}
  def solve(%SymbolicExpression{} = expr, var) when is_binary(var) do
    do_solve(expr, var, [])
  end

  # ---------------------------------------------------------------------------
  # Matrix Operations
  # ---------------------------------------------------------------------------

  @doc "Create a matrix from nested lists."
  @spec matrix([[expression()]], keyword()) :: {:ok, expression()} | {:error, String.t()}
  def matrix(rows, opts \\ []) when is_list(rows) do
    SymbolicExpression.new(:function, "matrix", Keyword.put(opts, :children, Enum.map(rows, fn row ->
      SymbolicExpression.new(:function, "row", children: row) |> elem(1)
    end)))
  end

  @doc "Add two matrices element-wise."
  @spec matrix_add(expression(), expression()) :: {:ok, expression()} | {:error, String.t()}
  def matrix_add(%SymbolicExpression{value: "matrix", children: rows_a} = a,
                 %SymbolicExpression{value: "matrix", children: rows_b} = _b) do
    pairs = Enum.zip(rows_a, rows_b)
    result_rows =
      Enum.map(pairs, fn {row_a, row_b} ->
        cells_a = row_a.children || []
        cells_b = row_b.children || []
        sums = Enum.zip(cells_a, cells_b) |> Enum.map(fn {ca, cb} ->
          SymbolicExpression.new(:operator, :+, children: [ca, cb]) |> elem(1)
        end)
        SymbolicExpression.new(:function, "row", children: sums) |> elem(1)
      end)

    SymbolicExpression.new(:function, "matrix", children: result_rows, metadata: a.metadata)
  end

  # ---------------------------------------------------------------------------
  # Polynomial Operations
  # ---------------------------------------------------------------------------

  @doc "Extract polynomial coefficients for a variable."
  @spec polynomial_coeffs(expression(), String.t()) :: [number()]
  def polynomial_coeffs(%SymbolicExpression{} = expr, var) when is_binary(var) do
    collect_coeffs(expr, var, 0)
  end

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  @doc """
  Replay symbolic computation from a sequence of rewrite steps.

  Replay uses only:
    - ontology (expression schemas, rule definitions)
    - rewrite rules (canonical ordering)
    - deterministic context

  Produces identical symbolic outputs.
  """
  @spec replay_computation(expression(), [map()]) :: {:ok, expression()} | {:error, String.t()}
  def replay_computation(initial_expr, steps) when is_list(steps) do
    Enum.reduce_while(steps, {:ok, initial_expr}, fn step, {:ok, expr} ->
      rule = Map.get(step, "rule", "")
      args = Map.get(step, "args", [])

      result =
        case rule do
          "simplify" -> simplify(expr)
          "expand" -> expand(expr)
          "factor" -> factor(expr)
          "differentiate" ->
            [var | _] = args
            differentiate(expr, var)
          "integrate" ->
            [var | _] = args
            integrate(expr, var)
          _ ->
            {:error, "unknown replay rule: #{rule}"}
        end

      case result do
        {:ok, e} -> {:cont, {:ok, e}}
        error -> {:halt, error}
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Expression Metadata
  # ---------------------------------------------------------------------------

  @doc "Attach frozen metadata to an expression."
  @spec with_metadata(expression(), map()) :: expression()
  def with_metadata(%SymbolicExpression{} = expr, metadata) when is_map(metadata) do
    merged = Map.merge(expr.metadata, metadata)
    %{expr | metadata: merged}
  end

  # ---------------------------------------------------------------------------
  # Internal: Simplify helpers
  # ---------------------------------------------------------------------------

  defp simplify_all(children) do
    results =
      Enum.map(children, fn child ->
        case simplify(child) do
          {:ok, e} -> e
          _ -> child
        end
      end)

    {:ok, results}
  end

  defp simplify_add(children) do
    {consts, rest} = Enum.split_with(children, fn c -> c.type == :constant end)

    const_sum =
      case consts do
        [] -> nil
        [c] -> c
        cs ->
          total = Enum.reduce(cs, 0, fn c, acc -> acc + (c.value || 0) end)
          if total == 0, do: nil, else: %SymbolicExpression{type: :constant, value: total, children: [], metadata: %{}}
      end

    combined = if const_sum, do: [const_sum | rest], else: rest
    non_zero = Enum.reject(combined, fn c -> c.type == :constant and c.value == 0 end)

    case non_zero do
      [] -> %SymbolicExpression{type: :constant, value: 0, children: [], metadata: %{}}
      [single] -> single
      result -> %SymbolicExpression{type: :operator, value: :+, children: result, metadata: %{}}
    end
  end

  defp simplify_multiply(children) do
    {consts, rest} = Enum.split_with(children, fn c -> c.type == :constant end)

    const_prod =
      case consts do
        [] -> 1
        cs -> Enum.reduce(cs, 1, fn c, acc -> acc * (c.value || 1) end)
      end

    cond do
      const_prod == 0 ->
        %SymbolicExpression{type: :constant, value: 0, children: [], metadata: %{}}
      const_prod == 1 and rest == [] ->
        %SymbolicExpression{type: :constant, value: 1, children: [], metadata: %{}}
      const_prod == 1 ->
        case rest do
          [single] -> single
          result -> %SymbolicExpression{type: :operator, value: :*, children: result, metadata: %{}}
        end
      true ->
        const_expr = %SymbolicExpression{type: :constant, value: const_prod, children: [], metadata: %{}}
        case rest do
          [] -> const_expr
          non_const -> %SymbolicExpression{type: :operator, value: :*, children: [const_expr | non_const], metadata: %{}}
        end
    end
  end

  # ---------------------------------------------------------------------------
  # Internal: Expand helpers
  # ---------------------------------------------------------------------------

  defp expand_all(children) do
    results =
      Enum.map(children, fn child ->
        case expand(child) do
          {:ok, e} -> e
          _ -> child
        end
      end)

    {:ok, results}
  end

  defp do_expand_product(left, right, metadata) do
    cond do
      left.type == :operator and left.value == :+ and right.type == :operator and right.value == :+ ->
        terms =
          for lc <- (left.children || []),
              rc <- (right.children || []) do
            SymbolicExpression.new(:operator, :*, children: [lc, rc]) |> elem(1)
          end

        SymbolicExpression.new(:operator, :+, children: terms, metadata: metadata)

      left.type == :operator and left.value == :+ ->
        terms =
          Enum.map(left.children || [], fn lc ->
            SymbolicExpression.new(:operator, :*, children: [lc, right]) |> elem(1)
          end)

        SymbolicExpression.new(:operator, :+, children: terms, metadata: metadata)

      right.type == :operator and right.value == :+ ->
        terms =
          Enum.map(right.children || [], fn rc ->
            SymbolicExpression.new(:operator, :*, children: [left, rc]) |> elem(1)
          end)

        SymbolicExpression.new(:operator, :+, children: terms, metadata: metadata)

      true ->
        SymbolicExpression.new(:operator, :*, children: [left, right], metadata: metadata)
    end
  end

  # ---------------------------------------------------------------------------
  # Internal: Factor helpers
  # ---------------------------------------------------------------------------

  defp extract_factors(%SymbolicExpression{type: :operator, value: :*, children: children}) do
    children || []
  end

  defp extract_factors(%SymbolicExpression{type: :constant, value: c}) when c != 0, do: [c]
  defp extract_factors(%SymbolicExpression{type: :variable} = v), do: [v.value]
  defp extract_factors(%{type: :constant, value: 0}), do: []
  defp extract_factors(_), do: []

  defp find_common_factors(factors_list) do
    case factors_list do
      [] -> []
      [first | rest] ->
        Enum.reduce(rest, first, fn factors, common ->
          Enum.filter(common, fn f -> Enum.any?(factors, fn ff -> ff == f end) end)
        end)
    end
  end

  defp factor_out(expr, []), do: {:ok, expr}

  defp factor_out(%SymbolicExpression{children: children} = _expr, common_factors) do
    common_expr = build_factor_product(common_factors)
    remaining =
      Enum.map(children, fn child ->
        remove_factors(child, common_factors)
      end)

    remaining_expr = SymbolicExpression.new(:operator, :+, children: remaining) |> elem(1)

    SymbolicExpression.new(:operator, :*, children: [common_expr, remaining_expr])
  end

  defp build_factor_product([]), do: %SymbolicExpression{type: :constant, value: 1, children: [], metadata: %{}}

  defp build_factor_product([single]), do: %SymbolicExpression{type: :variable, value: single, children: [], metadata: %{}}

  defp build_factor_product(factors) do
    children = Enum.map(factors, fn f ->
      if is_number(f) do
        %SymbolicExpression{type: :constant, value: f, children: [], metadata: %{}}
      else
        %SymbolicExpression{type: :variable, value: f, children: [], metadata: %{}}
      end
    end)

    %SymbolicExpression{type: :operator, value: :*, children: children, metadata: %{}}
  end

  defp remove_factors(%SymbolicExpression{type: :operator, value: :*, children: children}, factors) do
    remaining = Enum.reject(children || [], fn child ->
      child.type == :constant and child.value in factors
    end)

    case remaining do
      [] -> %SymbolicExpression{type: :constant, value: 1, children: [], metadata: %{}}
      [single] -> single
      result -> %SymbolicExpression{type: :operator, value: :*, children: result, metadata: %{}}
    end
  end

  defp remove_factors(%SymbolicExpression{type: :constant, value: v} = _expr, factors) do
    if v in factors do
      %SymbolicExpression{type: :constant, value: 1, children: [], metadata: %{}}
    else
      %SymbolicExpression{type: :constant, value: v, children: [], metadata: %{}}
    end
  end

  defp remove_factors(%SymbolicExpression{type: :variable, value: v} = _expr, factors) do
    if v in factors do
      %SymbolicExpression{type: :constant, value: 1, children: [], metadata: %{}}
    else
      %SymbolicExpression{type: :variable, value: v, children: [], metadata: %{}}
    end
  end

  # ---------------------------------------------------------------------------
  # Internal: Solve helpers
  # ---------------------------------------------------------------------------

  defp do_solve(%SymbolicExpression{type: :operator, value: :=, children: [left, right]}, var, _path) do
    eq = SymbolicExpression.new(:operator, :+, children: [
      left,
      SymbolicExpression.new(:operator, :*, children: [
        SymbolicExpression.new(:constant, -1) |> elem(1), right
      ]) |> elem(1)
    ]) |> elem(1)

    solve_linear(eq, var)
  end

  defp do_solve(%SymbolicExpression{type: :operator, value: :+, children: children} = _expr, var, _path) do
    solve_linear(%SymbolicExpression{type: :operator, value: :+, children: children}, var)
  end

  defp do_solve(%SymbolicExpression{type: :constant, value: 0} = _expr, _var, _path) do
    SymbolicExpression.new(:constant, 0)
  end

  defp do_solve(_expr, var, _path) do
    {:error, "unsupported equation form for variable #{var}"}
  end

  defp solve_linear(expr, var) do
    coeffs = classify_linear_terms(expr, var, 0, 0)

    case coeffs do
      {a, b} when a != 0 ->
        neg_b = SymbolicExpression.new(:operator, :*, children: [
          SymbolicExpression.new(:constant, -1) |> elem(1),
          SymbolicExpression.new(:constant, b) |> elem(1)
        ]) |> elem(1)

        SymbolicExpression.new(:operator, :/, children: [
          neg_b,
          SymbolicExpression.new(:constant, a) |> elem(1)
        ])

      {0, 0} ->
        {:error, "trivial equation (0 = 0)"}

      {0, _b} ->
        {:error, "contradiction: nonzero constant equals zero"}
    end
  end

  defp classify_linear_terms(%SymbolicExpression{type: :operator, value: :+, children: children}, var, a, b) do
    Enum.reduce(children, {a, b}, fn child, {acc_a, acc_b} ->
      classify_linear_terms(child, var, acc_a, acc_b)
    end)
  end

  defp classify_linear_terms(%SymbolicExpression{type: :operator, value: :*, children: [const, var_expr]}, var, a, b)
       when const.type == :constant and var_expr.type == :variable do
    if var_expr.value == var do
      {a + (const.value || 1), b}
    else
      {a, b}
    end
  end

  defp classify_linear_terms(%SymbolicExpression{type: :variable, value: v}, var, a, b) do
    if v == var, do: {a + 1, b}, else: {a, b}
  end

  defp classify_linear_terms(%SymbolicExpression{type: :constant, value: c}, _var, a, b) do
    {a, b + (c || 0)}
  end

  defp classify_linear_terms(_expr, _var, a, b), do: {a, b}

  # ---------------------------------------------------------------------------
  # Internal: Polynomial coefficient helpers
  # ---------------------------------------------------------------------------

  defp collect_coeffs(%SymbolicExpression{type: :operator, value: :+, children: children}, var, degree) do
    Enum.flat_map(children, fn child -> collect_coeffs(child, var, degree) end)
  end

  defp collect_coeffs(%SymbolicExpression{type: :operator, value: :^, children: [base, exp]}, var, _degree)
       when base.type == :variable and base.value == var and exp.type == :constant do
    [{exp.value, 1}]
  end

  defp collect_coeffs(%SymbolicExpression{type: :variable, value: v}, var, _degree) when v == var do
    [{1, 1}]
  end

  defp collect_coeffs(%SymbolicExpression{type: :constant}, _var, _degree), do: [{0, 0}]
  defp collect_coeffs(_expr, _var, _degree), do: []

  # ---------------------------------------------------------------------------
  # Internal: Metadata attachment
  # ---------------------------------------------------------------------------

  defp attach_metadata(%SymbolicExpression{} = expr, %SymbolicExpression{metadata: meta}) do
    %{expr | metadata: Map.merge(expr.metadata, meta)}
  end

  defp attach_metadata(expr, _original), do: expr
end
