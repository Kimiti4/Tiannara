defmodule TiannaraRuntime.Cognitive.Runtime.ExecutionState do
  @moduledoc "Phase 18.9 — Execution State struct"
  defstruct [:id, :mission_id, :phase, :step, :substep, :status, :error_count, :evidence_count, :replay_root, :archaeology_root, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.9"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      mission_id: Map.get(fields, :mission_id),
      phase: Map.get(fields, :phase),
      step: Map.get(fields, :step),
      substep: Map.get(fields, :substep),
      status: Map.get(fields, :status),
      error_count: Map.get(fields, :error_count) || 0,
      evidence_count: Map.get(fields, :evidence_count) || 0,
      replay_root: Map.get(fields, :replay_root),
      archaeology_root: Map.get(fields, :archaeology_root),
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: Map.get(fields, :migration_version) || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :mission_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "es_#{hash}"
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
