defmodule TiannaraRuntime.Mathematics.FormalAST do
  @moduledoc """
  Typed mathematical AST for machine-checkable problem statements.

  This is intentionally smaller than a complete theorem prover language. It
  provides explicit domains, quantifiers, predicates, relations and logical
  connectives so later proof engines can reason over structure instead of text.
  """

  @types [:real, :integer, :natural, :rational, :complex, :boolean, :set, :function]

  def variable(name, domain) when is_binary(name) and domain in @types,
    do: {:var, name, domain}

  def constant(value, domain) when domain in @types, do: {:const, value, domain}

  def add(a, b), do: {:op, :add, [a, b]}
  def subtract(a, b), do: {:op, :subtract, [a, b]}
  def multiply(a, b), do: {:op, :multiply, [a, b]}
  def divide(a, b), do: {:op, :divide, [a, b]}
  def power(a, b), do: {:op, :power, [a, b]}

  def equal(a, b), do: {:rel, :equal, a, b}
  def not_equal(a, b), do: {:rel, :not_equal, a, b}
  def less_than(a, b), do: {:rel, :less_than, a, b}
  def less_equal(a, b), do: {:rel, :less_equal, a, b}
  def greater_than(a, b), do: {:rel, :greater_than, a, b}
  def greater_equal(a, b), do: {:rel, :greater_equal, a, b}

  def and_(a, b), do: {:logic, :and, [a, b]}
  def or_(a, b), do: {:logic, :or, [a, b]}
  def implies(a, b), do: {:logic, :implies, [a, b]}
  def iff(a, b), do: {:logic, :iff, [a, b]}
  def not_(a), do: {:logic, :not, [a]}

  def forall(variable, proposition), do: {:quantifier, :forall, variable, proposition}
  def exists(variable, proposition), do: {:quantifier, :exists, variable, proposition}

  def validate(ast), do: validate_node(ast)

  defp validate_node({:var, name, domain}) when is_binary(name) and domain in @types, do: :ok
  defp validate_node({:const, _, domain}) when domain in @types, do: :ok

  defp validate_node({:op, op, children}) when op in [:add, :subtract, :multiply, :divide, :power] and length(children) == 2,
    do: validate_children(children)

  defp validate_node({:rel, rel, left, right}) when rel in [:equal, :not_equal, :less_than, :less_equal, :greater_than, :greater_equal],
    do: validate_children([left, right])

  defp validate_node({:logic, op, children}) when op in [:and, :or, :implies, :iff] and length(children) == 2,
    do: validate_children(children)

  defp validate_node({:logic, :not, [child]}), do: validate_node(child)

  defp validate_node({:quantifier, q, variable, proposition}) when q in [:forall, :exists],
    do: if(validate_node(variable) == :ok, do: validate_node(proposition), else: {:error, :invalid_quantifier_variable})

  defp validate_node(_), do: {:error, :invalid_formal_ast}

  defp validate_children(children) do
    case Enum.find(children, &(validate_node(&1) != :ok)) do
      nil -> :ok
      bad -> {:error, {:invalid_child, bad}}
    end
  end
end
