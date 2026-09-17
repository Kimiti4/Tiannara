defmodule TiannaraRuntime.Cognitive.Metacognition.MetaArchaeology do
  @moduledoc "Phase 18.8 — MetaArchaeology struct"
  defstruct [:id, :session_id, :origin, :meta_state_summary, :confidence_narrative, :uncertainty_narrative, :health_narrative, :escalation_history, :introspection_findings, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.8"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      session_id: Map.get(fields, :session_id),
      origin: Map.get(fields, :origin),
      meta_state_summary: Map.get(fields, :meta_state_summary, %{}),
      confidence_narrative: Map.get(fields, :confidence_narrative),
      uncertainty_narrative: Map.get(fields, :uncertainty_narrative),
      health_narrative: Map.get(fields, :health_narrative),
      escalation_history: Map.get(fields, :escalation_history, []),
      introspection_findings: Map.get(fields, :introspection_findings, []),
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: Map.get(fields, :migration_version, 0)
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :session_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "ma_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = archaeology) do
    canonical =
      archaeology
      |> Map.drop([:id, :fingerprint, :created_at])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = archaeology) do
    errors = []
    errors = if is_nil(Map.get(archaeology, :session_id)), do: [{:session_id, :required} | errors], else: errors
    errors = if Map.get(archaeology, :schema_version) != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
