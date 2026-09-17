defmodule TiannaraRuntime.Cognitive.ExecutionRequest do
  @moduledoc "Phase 18.1 — Immutable execution request struct"
  defstruct [:id, :task_reference, :requested_resources, :constraints, :deadline, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.1"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      task_reference: fields.task_reference,
      requested_resources: fields.requested_resources || %{},
      constraints: fields.constraints || [],
      deadline: fields.deadline,
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: fields.migration_version || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields.task_reference}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "er_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = req) do
    canonical =
      req
      |> Map.drop([:id, :fingerprint, :created_at])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = req) do
    errors = []
    errors = if is_nil(req.task_reference), do: [{:task_reference, :required} | errors], else: errors
    errors = if req.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
