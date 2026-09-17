defmodule TiannaraRuntime.Cognitive.Planning.Constraint do
  defstruct [:id, :plan_id, :constraint_type, :value, :scope, :severity, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.5"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      plan_id: fields.plan_id,
      constraint_type: fields.constraint_type,
      value: fields.value,
      scope: fields.scope || :global,
      severity: fields.severity || :medium,
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: fields.migration_version || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields.plan_id}_#{fields.constraint_type}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "c_#{hash}"
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
    errors = if is_nil(s.constraint_type), do: [{:constraint_type, :required} | errors], else: errors
    errors = if s.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
