defmodule TiannaraRuntime.CausalDiscovery.IndependentAuditReport do
  @moduledoc """
  Phase 17.3 — IndependentAuditReport: third-party audit of a causal graph's evidence grounding.
  Content-addressed ID prefix: ar_
  """
  @enforce_keys [:graph_fingerprint, :overall]
  defstruct [
    :audit_id, :graph_fingerprint, :overall, :findings,
    :replay_result, :evidence_coverage, :violations,
    :issued_at, :issued_by
  ]

  @type overall :: :pass | :fail | :inconclusive
  @type replay :: :match | :mismatch | :unavailable

  @type t :: %__MODULE__{
    audit_id: String.t(),
    graph_fingerprint: String.t(),
    overall: overall(),
    findings: [map()],
    replay_result: replay(),
    evidence_coverage: float(),
    violations: [String.t()],
    issued_at: String.t(),
    issued_by: :auditor
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    ar = %__MODULE__{
      audit_id: Keyword.get(opts, :audit_id),
      graph_fingerprint: Keyword.get(opts, :graph_fingerprint),
      overall: Keyword.get(opts, :overall, :inconclusive),
      findings: Keyword.get(opts, :findings, []),
      replay_result: Keyword.get(opts, :replay_result, :unavailable),
      evidence_coverage: Keyword.get(opts, :evidence_coverage, 0.0),
      violations: Keyword.get(opts, :violations, []),
      issued_at: Keyword.get(opts, :issued_at, now),
      issued_by: Keyword.get(opts, :issued_by, :auditor)
    }
    with {:ok, ar} <- validate(ar),
         do: {:ok, ensure_id(ar)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{graph_fingerprint: gf}) when is_nil(gf) or gf == "",
    do: {:error, "IndependentAuditReport graph_fingerprint must not be empty"}
  def validate(%__MODULE__{overall: o}) when o not in ~w(pass fail inconclusive)a,
    do: {:error, "IndependentAuditReport overall must be :pass, :fail, or :inconclusive"}
  def validate(%__MODULE__{replay_result: r}) when r not in ~w(match mismatch unavailable)a,
    do: {:error, "IndependentAuditReport replay_result must be :match, :mismatch, or :unavailable"}
  def validate(%__MODULE__{evidence_coverage: c}) when c < 0.0 or c > 1.0,
    do: {:error, "IndependentAuditReport evidence_coverage must be in [0.0, 1.0]"}
  def validate(%__MODULE__{} = ar), do: {:ok, ar}
  def validate(_), do: {:error, "invalid IndependentAuditReport"}

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = ar) do
    raw = ar.graph_fingerprint <> (ar.findings |> Enum.sort() |> inspect()) <> (ar.issued_at || "")
    "ar_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{audit_id: nil} = ar), do: %{ar | audit_id: compute_id(ar)}
  defp ensure_id(%__MODULE__{} = ar), do: ar
end
