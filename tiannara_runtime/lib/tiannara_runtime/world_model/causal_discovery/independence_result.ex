defmodule TiannaraRuntime.CausalDiscovery.IndependenceResult do
  @moduledoc """
  Phase 17.3 — IndependenceResult: result of a conditional or marginal independence test.
  Content-addressed ID prefix: ir_
  """
  @enforce_keys [:variable_a, :variable_b, :test_type]
  defstruct [
    :result_id, :variable_a, :variable_b, :conditioning_set,
    :test_type, :statistic, :p_value, :confidence, :dof,
    :sample_size, :evidence_root, :metadata
  ]

  @type test_type :: :conditional | :marginal

  @type t :: %__MODULE__{
    result_id: String.t(),
    variable_a: String.t(),
    variable_b: String.t(),
    conditioning_set: [String.t()],
    test_type: test_type(),
    statistic: float(),
    p_value: float(),
    confidence: float(),
    dof: non_neg_integer(),
    sample_size: non_neg_integer(),
    evidence_root: String.t() | nil,
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    r = %__MODULE__{
      result_id: Keyword.get(opts, :result_id),
      variable_a: Keyword.get(opts, :variable_a),
      variable_b: Keyword.get(opts, :variable_b),
      conditioning_set: Keyword.get(opts, :conditioning_set, []),
      test_type: Keyword.get(opts, :test_type),
      statistic: Keyword.get(opts, :statistic, 0.0),
      p_value: Keyword.get(opts, :p_value, 1.0),
      confidence: Keyword.get(opts, :confidence, 0.95),
      dof: Keyword.get(opts, :dof, 0),
      sample_size: Keyword.get(opts, :sample_size, 0),
      evidence_root: Keyword.get(opts, :evidence_root),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, r} <- validate(r),
         do: {:ok, ensure_id(r)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{variable_a: a}) when is_nil(a) or a == "",
    do: {:error, "IndependenceResult variable_a must not be empty"}
  def validate(%__MODULE__{variable_b: b}) when is_nil(b) or b == "",
    do: {:error, "IndependenceResult variable_b must not be empty"}
  def validate(%__MODULE__{variable_a: a, variable_b: b}) when a == b,
    do: {:error, "IndependenceResult variable_a and variable_b must differ"}
  def validate(%__MODULE__{test_type: t}) when t not in ~w(conditional marginal)a,
    do: {:error, "IndependenceResult test_type must be :conditional or :marginal"}
  def validate(%__MODULE__{p_value: p}) when p < 0.0 or p > 1.0,
    do: {:error, "IndependenceResult p_value must be in [0.0, 1.0]"}
  def validate(%__MODULE__{confidence: c}) when c < 0.0 or c > 1.0,
    do: {:error, "IndependenceResult confidence must be in [0.0, 1.0]"}
  def validate(%__MODULE__{evidence_root: r}) when r != nil and (not is_binary(r) or r == ""),
    do: {:error, "IndependenceResult evidence_root must be a valid string when provided"}
  def validate(%__MODULE__{} = r), do: {:ok, r}
  def validate(_), do: {:error, "invalid IndependenceResult"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = r) do
    Map.from_struct(r)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value({a, b}), do: [a, b]
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = r) do
    raw = r.variable_a <> r.variable_b <>
          (Enum.sort(r.conditioning_set) |> Enum.join("|")) <>
          Atom.to_string(r.test_type)
    "ir_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{result_id: nil} = r), do: %{r | result_id: compute_id(r)}
  defp ensure_id(%__MODULE__{} = r), do: r
end
