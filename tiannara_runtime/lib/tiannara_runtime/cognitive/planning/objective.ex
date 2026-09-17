defmodule TiannaraRuntime.Cognitive.Planning.Objective do
  defstruct [:id, :description, :goal_id, :priority, :success_criteria, :status, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.5"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      description: fields.description,
      goal_id: fields.goal_id,
      priority: fields.priority || 0,
      success_criteria: fields.success_criteria || [],
      status: fields.status || :pending,
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: fields.migration_version || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields.description}_#{fields.goal_id}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "obj_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = s) do
    s |> Map.drop([:id, :fingerprint]) |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end) |> Enum.join("|")
      |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = s) do
    errors = []
    errors = if is_nil(s.id), do: [{:id, :required} | errors], else: errors
    errors = if is_nil(s.description), do: [{:description, :required} | errors], else: errors
    errors = if is_nil(s.goal_id), do: [{:goal_id, :required} | errors], else: errors
    errors = if s.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
