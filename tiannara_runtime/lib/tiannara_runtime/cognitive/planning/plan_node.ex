defmodule TiannaraRuntime.Cognitive.Planning.PlanNode do
  defstruct [:id, :plan_id, :step, :subsystem, :estimated_cost, :estimated_duration, :dependencies, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.5"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      plan_id: fields.plan_id,
      step: fields.step,
      subsystem: fields.subsystem,
      estimated_cost: fields.estimated_cost || 0,
      estimated_duration: fields.estimated_duration || 0,
      dependencies: fields.dependencies || [],
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: fields.migration_version || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields.plan_id}_#{fields.step}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "pn_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = s) do
    s |> Map.drop([:id, :fingerprint]) |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end) |> Enum.join("|")
      |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = s) do
    errors = []
    errors = if is_nil(s.id), do: [{:id, :required} | errors], else: errors
    errors = if is_nil(s.plan_id), do: [{:plan_id, :required} | errors], else: errors
    errors = if s.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
