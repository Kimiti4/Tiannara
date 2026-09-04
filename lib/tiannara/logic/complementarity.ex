defmodule Tiannara.Logic.Complementarity do
  @moduledoc """
  Canonical complementarity kernel (MC-002 L4).

  Two claims are complementary when they can coexist in a shared context:
  neither contradicts the other and both are consistent with the facts present.
  This replaces the duplicated tensegrity/CIS mutual-constraint checks with one
  structural primitive.

  Constitutional basis: "Uncertainty should never be hidden".
  """

  alias Tiannara.Logic.Contradiction

  @doc """
  True when the pair `{claim_a, claim_b}` (or `%{a: _, b: _}`) is complementary
  in `context`.

  Implementation: the two claims must not contradict each other (`detect/2`
  returns `:consistent` or `:unknown`) AND neither claim may be falsified by a
  present context fact of the same subject.
  """
  @spec holds?(term(), map()) :: boolean()
  def holds?({a, b}, context) when is_map(context), do: complementary?(a, b, context)

  def holds?(%{a: a, b: b}, context) when is_map(context), do: complementary?(a, b, context)

  def holds?(_pair, _context), do: false

  defp complementary?(a, b, context) do
    verdict = Contradiction.detect(a, b)

    verdict in [:consistent, :unknown] and
      not falsified?(a, context) and
      not falsified?(b, context)
  end

  defp falsified?(%{subject: subject, value: value}, context) when not is_nil(subject) do
    case Map.get(context, subject) do
      nil -> false
      present -> present != value
    end
  end

  defp falsified?(_claim, _context), do: false
end