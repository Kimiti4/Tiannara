defmodule TiannaraRuntime.Cognitive.Decision.RiskAssessment do
  defstruct [:id, :candidate_id, :execution_risk, :scientific_risk, :governance_risk, :resource_risk, :uncertainty, :constitutional_complexity, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.6"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id, candidate_id: fields[:candidate_id],
      execution_risk: fields[:execution_risk], scientific_risk: fields[:scientific_risk],
      governance_risk: fields[:governance_risk], resource_risk: fields[:resource_risk],
      uncertainty: fields[:uncertainty], constitutional_complexity: fields[:constitutional_complexity],
      schema_version: @schema_version, ontology_version: @ontology_version,
      created_with_phase: @created_with_phase, migration_version: fields[:migration_version] || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields[:candidate_id]}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "ra_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = s) do
    s |> Map.drop([:id, :fingerprint]) |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end) |> Enum.join("|")
      |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = s) do
    errors = if is_nil(s.id), do: [{:id, :required}], else: []
    errors = if s.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
