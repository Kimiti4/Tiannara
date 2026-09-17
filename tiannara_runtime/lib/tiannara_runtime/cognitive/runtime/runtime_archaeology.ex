defmodule TiannaraRuntime.Cognitive.Runtime.RuntimeArchaeology do
  @moduledoc "Phase 18.9 — Runtime Archaeology struct"
  defstruct [:id, :mission_id, :origin, :mission_narrative, :subsystem_summaries, :evidence_lineage, :replay_verification, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.9"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      mission_id: Map.get(fields, :mission_id),
      origin: Map.get(fields, :origin),
      mission_narrative: Map.get(fields, :mission_narrative),
      subsystem_summaries: Map.get(fields, :subsystem_summaries) || [],
      evidence_lineage: Map.get(fields, :evidence_lineage) || [],
      replay_verification: Map.get(fields, :replay_verification),
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
    "ra_#{hash}"
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
