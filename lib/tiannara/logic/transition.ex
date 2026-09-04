defmodule Tiannara.Logic.Transition do
  @moduledoc """
  Canonical state-transition validity kernel (MC-002 L4).

  Unifies the divergent transition-validator rule syntaxes used across the
  codebase into one structural predicate:

    - a single-edge map `%{from: from_state, allowed: [to_state, ...]}`; or
    - a transition-table map `%{from_state => [to_state, ...]}`.

  Constitutional basis: "Capability must never outpace verification".
  """

  @doc """
  True when `post_state` is a legal successor of `pre_state` under `transition`.

  Accepts either a single-edge map with `:from` and `:allowed` keys, or a
  transition table (a map of `from => [to, ...]`).
  """
  @spec valid?(term(), term(), term()) :: boolean()
  def valid?(%{from: from_state, allowed: allowed}, pre, post) when is_list(allowed) do
    from_state == pre and post in allowed
  end

  def valid?(%{from: from_state, to: to_state}, pre, post) do
    from_state == pre and to_state == post
  end

  def valid?(table, pre, post) when is_map(table) and not is_map_key(table, :from) do
    case Map.get(table, pre) do
      allowed when is_list(allowed) -> post in allowed
      single when not is_nil(single) -> single == post
      _ -> false
    end
  end

  def valid?(_other, _pre, _post), do: false
end