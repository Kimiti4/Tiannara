defmodule TiannaraRuntime.Cognitive.Reflection.ReflectionReplay do
  defstruct [:id, :session_id, :reflection_root, :outcome_root, :pattern_root, :bias_root, :lesson_root, :meta_root, :fingerprint, :schema_version, :ontology_version, :created_with_phase]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.7"

  def new(fields) do
    required = [:session_id, :reflection_root, :outcome_root, :pattern_root, :bias_root, :lesson_root, :meta_root]
    missing = Enum.filter(required, &is_nil(Map.get(fields, &1)))
    if missing != [] do
      {:error, {:missing_fields, missing}}
    else
      id = generate_id(fields)
      struct = %__MODULE__{
        id: id,
        session_id: Map.get(fields, :session_id),
        reflection_root: Map.get(fields, :reflection_root),
        outcome_root: Map.get(fields, :outcome_root),
        pattern_root: Map.get(fields, :pattern_root),
        bias_root: Map.get(fields, :bias_root),
        lesson_root: Map.get(fields, :lesson_root),
        meta_root: Map.get(fields, :meta_root),
        schema_version: @schema_version,
        ontology_version: @ontology_version,
        created_with_phase: @created_with_phase
      }
      fingerprint = compute_fingerprint(struct)
      {:ok, %{struct | fingerprint: fingerprint}}
    end
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :session_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "rr_#{hash}"
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
