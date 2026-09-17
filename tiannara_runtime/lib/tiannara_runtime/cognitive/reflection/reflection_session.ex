defmodule TiannaraRuntime.Cognitive.ReflectionSession do
  defstruct [:id, :mission_id, :decision_id, :outcomes, :patterns, :lessons, :bias_profile, :meta_state, :status, :fingerprint, :schema_version, :ontology_version, :created_with_phase]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.7"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      mission_id: Map.get(fields, :mission_id),
      decision_id: Map.get(fields, :decision_id),
      outcomes: Map.get(fields, :outcomes, []),
      patterns: Map.get(fields, :patterns, []),
      lessons: Map.get(fields, :lessons, []),
      bias_profile: Map.get(fields, :bias_profile, []),
      meta_state: Map.get(fields, :meta_state),
      status: Map.get(fields, :status, :pending),
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :session_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "rs_#{hash}"
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
