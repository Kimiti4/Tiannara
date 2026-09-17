defmodule TiannaraRuntime.Cognitive.Runtime.CognitiveMission do
  @moduledoc "Phase 18.9 — Cognitive Mission struct"
  defstruct [:id, :trajectory_id, :status, :stages, :current_stage, :plan_id, :decision_id, :reflection_id, :meta_id, :evidence_chain, :artifacts, :created_at, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.9"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      trajectory_id: Map.get(fields, :trajectory_id),
      status: Map.get(fields, :status),
      stages: Map.get(fields, :stages) || [],
      current_stage: Map.get(fields, :current_stage),
      plan_id: Map.get(fields, :plan_id),
      decision_id: Map.get(fields, :decision_id),
      reflection_id: Map.get(fields, :reflection_id),
      meta_id: Map.get(fields, :meta_id),
      evidence_chain: Map.get(fields, :evidence_chain) || [],
      artifacts: Map.get(fields, :artifacts) || %{},
      created_at: Map.get(fields, :created_at),
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: Map.get(fields, :migration_version) || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :trajectory_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "cm_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = struct) do
    canonical =
      struct
      |> Map.drop([:id, :fingerprint])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = struct) do
    errors = []
    errors = if struct.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
