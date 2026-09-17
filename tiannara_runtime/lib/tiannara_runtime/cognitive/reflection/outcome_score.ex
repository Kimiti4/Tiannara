defmodule TiannaraRuntime.Cognitive.Reflection.OutcomeScore do
  defstruct [:id, :outcome_id, :mission_success, :efficiency, :accuracy, :timeliness, :resource_utilization, :constitutional_fidelity, :overall, :fingerprint, :schema_version, :ontology_version, :created_with_phase]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.7"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      outcome_id: Map.get(fields, :outcome_id),
      mission_success: Map.get(fields, :mission_success, 0.0),
      efficiency: Map.get(fields, :efficiency, 0.0),
      accuracy: Map.get(fields, :accuracy, 0.0),
      timeliness: Map.get(fields, :timeliness, 0.0),
      resource_utilization: Map.get(fields, :resource_utilization, 0.0),
      constitutional_fidelity: Map.get(fields, :constitutional_fidelity, 0.0),
      overall: Map.get(fields, :overall, 0.0),
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :outcome_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "os_#{hash}"
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
