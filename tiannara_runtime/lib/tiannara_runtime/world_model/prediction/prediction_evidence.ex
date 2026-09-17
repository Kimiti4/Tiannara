defmodule TiannaraRuntime.WorldModel.Prediction.PredictionEvidence do
  @moduledoc """
  Phase 17.4 — PredictionEvidence: evidential grounding for a prediction.
  Content-addressed ID prefix: pe_
  """
  @enforce_keys [:prediction_id]
  defstruct [
    :evidence_id, :prediction_id, :model_evidence, :assumption_hashes,
    :equation_hashes, :causal_roots, :metadata
  ]

  @type t :: %__MODULE__{
    evidence_id: String.t(),
    prediction_id: String.t(),
    model_evidence: [String.t()],
    assumption_hashes: [String.t()],
    equation_hashes: [String.t()],
    causal_roots: [String.t()],
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    pe = %__MODULE__{
      evidence_id: Keyword.get(opts, :evidence_id),
      prediction_id: Keyword.get(opts, :prediction_id),
      model_evidence: Keyword.get(opts, :model_evidence, []),
      assumption_hashes: Keyword.get(opts, :assumption_hashes, []),
      equation_hashes: Keyword.get(opts, :equation_hashes, []),
      causal_roots: Keyword.get(opts, :causal_roots, []),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, pe} <- validate(pe),
         do: {:ok, ensure_id(pe)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{prediction_id: p}) when is_nil(p) or p == "",
    do: {:error, "PredictionEvidence prediction_id must not be empty"}
  def validate(%__MODULE__{model_evidence: me}) when not is_list(me),
    do: {:error, "PredictionEvidence model_evidence must be a list"}
  def validate(%__MODULE__{assumption_hashes: ah}) when not is_list(ah),
    do: {:error, "PredictionEvidence assumption_hashes must be a list"}
  def validate(%__MODULE__{equation_hashes: eh}) when not is_list(eh),
    do: {:error, "PredictionEvidence equation_hashes must be a list"}
  def validate(%__MODULE__{causal_roots: cr}) when not is_list(cr),
    do: {:error, "PredictionEvidence causal_roots must be a list"}
  def validate(%__MODULE__{} = pe), do: {:ok, pe}
  def validate(_), do: {:error, "invalid PredictionEvidence"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = pe) do
    Map.from_struct(pe)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.sort(v)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = pe) do
    "pe_" <> (:crypto.hash(:sha256, pe.prediction_id) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{evidence_id: nil} = pe), do: %{pe | evidence_id: compute_id(pe)}
  defp ensure_id(%__MODULE__{} = pe), do: pe
end
