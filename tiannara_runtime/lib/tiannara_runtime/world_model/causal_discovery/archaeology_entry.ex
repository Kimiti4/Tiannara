defmodule TiannaraRuntime.CausalDiscovery.ArchaeologyEntry do
  @moduledoc """
  Phase 17.3 — ArchaeologyEntry: a single recorded step in causal discovery lineage.
  Content-addressed ID prefix: ae_
  """
  @enforce_keys [:stage, :description]
  defstruct [
    :entry_id, :stage, :description, :input_fingerprints,
    :output_fingerprints, :alternatives, :evidence_roots,
    :confidence, :metadata
  ]

  @type t :: %__MODULE__{
    entry_id: String.t(),
    stage: atom(),
    description: String.t(),
    input_fingerprints: [String.t()],
    output_fingerprints: [String.t()],
    alternatives: [String.t()],
    evidence_roots: [String.t()],
    confidence: float() | nil,
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    e = %__MODULE__{
      entry_id: Keyword.get(opts, :entry_id),
      stage: Keyword.get(opts, :stage),
      description: Keyword.get(opts, :description),
      input_fingerprints: Keyword.get(opts, :input_fingerprints, []),
      output_fingerprints: Keyword.get(opts, :output_fingerprints, []),
      alternatives: Keyword.get(opts, :alternatives, []),
      evidence_roots: Keyword.get(opts, :evidence_roots, []),
      confidence: Keyword.get(opts, :confidence),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, e} <- validate(e),
         do: {:ok, ensure_id(e)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{stage: s}) when is_nil(s),
    do: {:error, "ArchaeologyEntry stage must not be nil"}
  def validate(%__MODULE__{description: d}) when is_nil(d) or d == "",
    do: {:error, "ArchaeologyEntry description must not be empty"}
  def validate(%__MODULE__{confidence: c}) when c != nil and (c < 0.0 or c > 1.0),
    do: {:error, "ArchaeologyEntry confidence must be in [0.0, 1.0] when provided"}
  def validate(%__MODULE__{} = e), do: {:ok, e}
  def validate(_), do: {:error, "invalid ArchaeologyEntry"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = e) do
    Map.from_struct(e)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.sort(v)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = e) do
    raw = Atom.to_string(e.stage) <> e.description <>
          (Enum.sort(e.input_fingerprints) |> Enum.join("|")) <>
          (Enum.sort(e.output_fingerprints) |> Enum.join("|"))
    "ae_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{entry_id: nil} = e), do: %{e | entry_id: compute_id(e)}
  defp ensure_id(%__MODULE__{} = e), do: e
end
