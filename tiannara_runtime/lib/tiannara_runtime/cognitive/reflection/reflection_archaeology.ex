defmodule TiannaraRuntime.Cognitive.Reflection.ReflectionArchaeology do
  defstruct [:id, :session_id, :origin, :reflection_reason, :outcome_summary, :pattern_insights, :bias_profile, :lessons_learned, :meta_state_change, :fingerprint, :schema_version, :ontology_version, :created_with_phase]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.7"

  def new(fields) do
    required = [:session_id, :origin, :reflection_reason]
    missing = Enum.filter(required, &is_nil(Map.get(fields, &1)))
    if missing != [] do
      {:error, {:missing_fields, missing}}
    else
      id = generate_id(fields)
      struct = %__MODULE__{
        id: id,
        session_id: Map.get(fields, :session_id),
        origin: Map.get(fields, :origin),
        reflection_reason: Map.get(fields, :reflection_reason),
        outcome_summary: Map.get(fields, :outcome_summary, %{}),
        pattern_insights: Map.get(fields, :pattern_insights, []),
        bias_profile: Map.get(fields, :bias_profile, []),
        lessons_learned: Map.get(fields, :lessons_learned, []),
        meta_state_change: Map.get(fields, :meta_state_change, %{}),
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
