defmodule TiannaraRuntime.Cognitive.Plan do
  @moduledoc "Phase 18.1 — Immutable plan struct"
  defstruct [:id, :mission, :steps, :dependencies, :estimated_cost, :estimated_duration, :status, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.1"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      mission: fields.mission,
      steps: fields.steps || [],
      dependencies: fields.dependencies || [],
      estimated_cost: fields.estimated_cost,
      estimated_duration: fields.estimated_duration,
      status: fields.status || :draft,
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: fields.migration_version || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields.mission}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "pl_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = plan) do
    canonical =
      plan
      |> Map.drop([:id, :fingerprint, :created_at])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = plan) do
    errors = []
    errors = if is_nil(plan.mission), do: [{:mission, :required} | errors], else: errors
    errors = if is_nil(plan.status), do: [{:status, :required} | errors], else: errors
    errors = if plan.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
