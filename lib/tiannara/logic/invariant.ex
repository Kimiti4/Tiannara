defmodule Tiannara.Logic.Invariant do
  @moduledoc """
  Canonical invariant-evaluation kernel (MC-002 L4).

  A single execution path for evaluating invariant predicates against a world
  snapshot, standardized on **collect-all** failure semantics with structured
  violation terms. Existing aggregators (constitutional registry, CEL gates,
  sentinel) reduce to this one semantics instead of each defining its own.

  Constitutional basis: "Capability must never outpace verification",
  "No feature is complete until it is validated".
  """

  @type snapshot :: term()
  @type predicate ::
          (snapshot() -> boolean())
          | (()-> boolean())
          | (snapshot() -> {:ok, term()} | {:violation, term()})
          | (-> {:ok, term()} | {:violation, term()})
  @type invariant :: predicate() | %{check: predicate()} | %{predicate: predicate()}

  @doc """
  Evaluate one invariant against a snapshot.

  Supported forms:

    - a 1-arity function receiving the snapshot, returning a boolean,
      `:ok`/`true`, or `{:violation, detail}` / `{:error, detail}`;
    - a 0-arity probe (independent of the snapshot — the constitutional
      `Tiannara.Constitution.Invariant` shape), returning `:ok` or
      `{:error, detail}`;
    - a map with a `:check` or `:predicate` function of either arity.

  Returns `:ok` or `{:violation, detail}` where `detail` is the structured term
  produced by the predicate (or a normalized term when the predicate returns a
  bare boolean).
  """
  @spec check(invariant(), snapshot()) :: :ok | {:violation, term()}
  def check(%{check: fun}, snapshot) when is_function(fun, 1), do: normalize(fun.(snapshot))

  def check(%{check: fun}, _snapshot) when is_function(fun, 0), do: normalize(fun.())

  def check(%{predicate: fun}, snapshot) when is_function(fun, 1), do: normalize(fun.(snapshot))

  def check(%{predicate: fun}, _snapshot) when is_function(fun, 0), do: normalize(fun.())

  def check(fun, snapshot) when is_function(fun, 1), do: normalize(fun.(snapshot))
  def check(fun, _snapshot) when is_function(fun, 0), do: normalize(fun.())

  def check(other, _snapshot), do: {:violation, {:invalid_invariant, other}}

  @doc """
  Evaluate a list of invariants, collecting every violation.

  Returns `:ok` when all pass, or `{:violations, [detail]}` with one structured
  detail per failing invariant — collect-all, never first-fail.
  """
  @spec check_all([invariant()], snapshot()) :: :ok | {:violations, [term()]}
  def check_all(invariants, snapshot) when is_list(invariants) do
    details =
      Enum.reduce(invariants, [], fn invariant, acc ->
        case check(invariant, snapshot) do
          :ok -> acc
          {:violation, detail} -> [detail | acc]
        end
      end)

    case details do
      [] -> :ok
      list -> {:violations, Enum.reverse(list)}
    end
  end

  defp normalize(true), do: :ok
  defp normalize(:ok), do: :ok
  defp normalize(false), do: {:violation, :assertion_failed}
  defp normalize({:error, detail}), do: {:violation, detail}
  defp normalize({:violation, detail}), do: {:violation, detail}
  defp normalize({:fail, detail}), do: {:violation, detail}
  defp normalize(other), do: {:violation, {:unsupported_result, other}}
end