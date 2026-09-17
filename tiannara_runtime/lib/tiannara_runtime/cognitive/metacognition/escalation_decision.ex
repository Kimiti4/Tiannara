defmodule TiannaraRuntime.Cognitive.Metacognition.EscalationDecision do
  @moduledoc "Phase 18.8 — EscalationDecision struct"
  defstruct [:id, :session_id, :level, :reason, :trigger, :context, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.8"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      session_id: Map.get(fields, :session_id),
      level: Map.get(fields, :level),
      reason: Map.get(fields, :reason),
      trigger: Map.get(fields, :trigger),
      context: Map.get(fields, :context, %{}),
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: Map.get(fields, :migration_version, 0)
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :session_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "ed_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = decision) do
    canonical =
      decision
      |> Map.drop([:id, :fingerprint, :created_at])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = decision) do
    errors = []
    errors = if is_nil(Map.get(decision, :session_id)), do: [{:session_id, :required} | errors], else: errors
    errors = if is_nil(Map.get(decision, :level)), do: [{:level, :required} | errors], else: errors
    errors = if Map.get(decision, :schema_version) != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
