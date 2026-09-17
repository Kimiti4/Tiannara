defmodule TiannaraRuntime.Cognitive.Runtime.CognitiveContext do
  @moduledoc "Phase 18.9 — Cognitive Context struct"
  defstruct [:id, :mission_id, :working_memory_snapshot, :attention_state, :planning_state, :decision_state, :reflection_state, :meta_state, :pipeline_version, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.9"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      mission_id: Map.get(fields, :mission_id),
      working_memory_snapshot: Map.get(fields, :working_memory_snapshot) || %{},
      attention_state: Map.get(fields, :attention_state) || %{},
      planning_state: Map.get(fields, :planning_state) || %{},
      decision_state: Map.get(fields, :decision_state) || %{},
      reflection_state: Map.get(fields, :reflection_state) || %{},
      meta_state: Map.get(fields, :meta_state) || %{},
      pipeline_version: Map.get(fields, :pipeline_version),
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
    "cc_#{hash}"
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
