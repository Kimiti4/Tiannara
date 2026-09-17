defmodule TiannaraRuntime.CausalDiscovery.Skeleton do
  @moduledoc """
  Phase 17.3 — Skeleton: an undirected graph skeleton from constraint-based discovery.
  Content-addressed ID prefix: sk_
  """
  @enforce_keys [:nodes]
  defstruct [:skeleton_id, :nodes, :adjacency, :separating_sets, :fingerprint]

  @type t :: %__MODULE__{
    skeleton_id: String.t(),
    nodes: [String.t()],
    adjacency: %{String.t() => [String.t()]},
    separating_sets: %{{String.t(), String.t()} => [String.t()]},
    fingerprint: String.t() | nil
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    s = %__MODULE__{
      skeleton_id: Keyword.get(opts, :skeleton_id),
      nodes: Keyword.get(opts, :nodes, []),
      adjacency: Keyword.get(opts, :adjacency, %{}),
      separating_sets: Keyword.get(opts, :separating_sets, %{}),
      fingerprint: Keyword.get(opts, :fingerprint)
    }
    with {:ok, s} <- validate(s),
         do: {:ok, ensure_id(s)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{nodes: ns}) when not is_list(ns) or ns == [],
    do: {:error, "Skeleton nodes must be a non-empty list"}
  def validate(%__MODULE__{adjacency: a}) when not is_map(a),
    do: {:error, "Skeleton adjacency must be a map"}
  def validate(%__MODULE__{} = s) do
    node_set = MapSet.new(s.nodes)
    bad_keys = Map.keys(s.adjacency) |> Enum.reject(&MapSet.member?(node_set, &1))
    if bad_keys != [] do
      {:error, "Skeleton adjacency keys not in nodes: #{inspect(bad_keys)}"}
    else
      {:ok, s}
    end
  end
  def validate(_), do: {:error, "invalid Skeleton"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = s) do
    Map.from_struct(s)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = s) do
    adj_str = s.adjacency |> Enum.sort_by(fn {k, _} -> k end) |> inspect()
    "sk_" <> (:crypto.hash(:sha256, adj_str) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{skeleton_id: nil} = s), do: %{s | skeleton_id: compute_id(s)}
  defp ensure_id(%__MODULE__{} = s), do: s
end
