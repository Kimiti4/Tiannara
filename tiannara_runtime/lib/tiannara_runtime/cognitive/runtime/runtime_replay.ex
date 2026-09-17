defmodule TiannaraRuntime.Cognitive.Runtime.RuntimeReplay do
  @moduledoc "Phase 18.9 — Runtime Replay struct"
  defstruct [:id, :mission_id, :mission_root, :kernel_root, :working_memory_root, :attention_root, :planning_root, :decision_root, :reflection_root, :metacognition_root, :evidence_root, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.9"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      mission_id: Map.get(fields, :mission_id),
      mission_root: Map.get(fields, :mission_root),
      kernel_root: Map.get(fields, :kernel_root),
      working_memory_root: Map.get(fields, :working_memory_root),
      attention_root: Map.get(fields, :attention_root),
      planning_root: Map.get(fields, :planning_root),
      decision_root: Map.get(fields, :decision_root),
      reflection_root: Map.get(fields, :reflection_root),
      metacognition_root: Map.get(fields, :metacognition_root),
      evidence_root: Map.get(fields, :evidence_root),
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
    "rr_#{hash}"
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
