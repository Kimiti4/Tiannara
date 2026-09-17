defmodule TiannaraRuntime.CausalDiscovery.CausalCertificate do
  @moduledoc """
  Phase 17.3 — CausalCertificate: a signed certificate for a validated causal graph.
  Content-addressed ID prefix: cc_
  """
  @enforce_keys [:graph_fingerprint, :checks]
  defstruct [:certificate_id, :graph_fingerprint, :checks, :overall, :issued_at, :issued_by, :version, :evidence_root]

  @type t :: %__MODULE__{
    certificate_id: String.t(),
    graph_fingerprint: String.t(),
    checks: [TiannaraRuntime.CausalDiscovery.ValidationCheck.t()],
    overall: :pass | :fail | :inconclusive,
    issued_at: String.t(),
    issued_by: String.t(),
    version: non_neg_integer(),
    evidence_root: String.t() | nil
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    cc = %__MODULE__{
      certificate_id: Keyword.get(opts, :certificate_id),
      graph_fingerprint: Keyword.get(opts, :graph_fingerprint),
      checks: Keyword.get(opts, :checks, []),
      overall: Keyword.get(opts, :overall, :inconclusive),
      issued_at: Keyword.get(opts, :issued_at, now),
      issued_by: Keyword.get(opts, :issued_by, :causal_discovery),
      version: Keyword.get(opts, :version, 1),
      evidence_root: Keyword.get(opts, :evidence_root)
    }
    with {:ok, cc} <- validate(cc),
         do: {:ok, ensure_id(cc)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{graph_fingerprint: gf}) when is_nil(gf) or gf == "",
    do: {:error, "CausalCertificate graph_fingerprint must not be empty"}
  def validate(%__MODULE__{checks: c}) when not is_list(c),
    do: {:error, "CausalCertificate checks must be a list"}
  def validate(%__MODULE__{overall: o}) when o not in ~w(pass fail inconclusive)a,
    do: {:error, "CausalCertificate overall must be :pass, :fail, or :inconclusive"}
  def validate(%__MODULE__{} = cc), do: {:ok, cc}
  def validate(_), do: {:error, "invalid CausalCertificate"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = cc) do
    Map.from_struct(cc)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.map(v, fn
    %{__struct__: _} = e -> TiannaraRuntime.CausalDiscovery.ValidationCheck.canonicalize(e)
    other -> other
  end)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = cc) do
    check_fps = cc.checks |> Enum.map(& &1.fingerprint) |> Enum.sort() |> Enum.join("|")
    raw = cc.graph_fingerprint <> check_fps
    "cc_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{certificate_id: nil} = cc), do: %{cc | certificate_id: compute_id(cc)}
  defp ensure_id(%__MODULE__{} = cc), do: cc
end
