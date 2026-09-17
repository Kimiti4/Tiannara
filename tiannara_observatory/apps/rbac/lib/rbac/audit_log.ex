defmodule Rbac.AuditLog do
  @moduledoc """
  Constitutional Audit Logger.

  Wraps the immutable Audit Ledger with RFC 6902 state-delta support.
  Every log call creates a cryptographically linked audit entry.
  """

  alias Rbac.Audit.Ledger

  def record(action, operator_id, resource, details \\ %{}) do
    attrs = %{action: action, actor: operator_id, resource: resource}
    attrs = Map.merge(attrs, details)
    Ledger.record(attrs)
  end

  def record_with_delta(action, operator_id, resource, old_state, new_state, opts \\ []) do
    delta = generate_delta(old_state, new_state)
    evidence = if opts[:evidence], do: opts[:evidence], else: "State change"

    Ledger.record(%{
      action: action,
      actor: operator_id,
      resource: resource,
      intent: opts[:intent] || "unspecified",
      evidence: evidence,
      decision: opts[:decision] || "granted",
      result: opts[:result] || "success",
      delta: delta,
      metadata: opts[:metadata] || %{}
    })
  end

  def list(opts \\ []) do
    limit = opts[:limit] || 100
    Ledger.tail(limit)
  end

  defp generate_delta(nil, new), do: [%{op: "add", path: "/", value: new}]
  defp generate_delta(old, nil), do: [%{op: "remove", path: "/", old_value: old}]

  defp generate_delta(old, new) when is_map(old) and is_map(new) do
    deep_diff(old, new, "")
  end

  defp generate_delta(old, new) when old != new,
    do: [%{op: "replace", path: "/", value: new, old_value: old}]

  defp generate_delta(_, _), do: []

  defp deep_diff(old, new, path) do
    all_keys = MapSet.new(Map.keys(old) ++ Map.keys(new))

    Enum.reduce(all_keys, [], fn key, acc ->
      cur_path = if path == "", do: "/#{key}", else: "#{path}/#{key}"
      old_val = Map.get(old, key)
      new_val = Map.get(new, key)

      cond do
        not Map.has_key?(old, key) ->
          [%{op: "add", path: cur_path, value: new_val} | acc]

        not Map.has_key?(new, key) ->
          [%{op: "remove", path: cur_path, old_value: old_val} | acc]

        is_map(old_val) and is_map(new_val) ->
          deep_diff(old_val, new_val, cur_path) ++ acc

        old_val != new_val ->
          [%{op: "replace", path: cur_path, value: new_val, old_value: old_val} | acc]

        true ->
          acc
      end
    end)
  end
end
