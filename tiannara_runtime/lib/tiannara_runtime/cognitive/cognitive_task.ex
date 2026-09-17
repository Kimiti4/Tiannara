defmodule TiannaraRuntime.Cognitive.CognitiveTask do
  @moduledoc "Phase 18.1 — Immutable cognitive task struct"
  defstruct [:id, :task_type, :priority, :status, :owner, :inputs, :outputs, :dependencies, :created_at, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.1"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      task_type: fields.task_type,
      priority: fields.priority,
      status: fields.status || :pending,
      owner: fields.owner,
      inputs: fields.inputs || [],
      outputs: fields.outputs || [],
      dependencies: fields.dependencies || [],
      created_at: :erlang.unique_integer([:positive]),
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: fields.migration_version || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields.task_type}_#{fields.owner}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "ct_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = task) do
    canonical =
      task
      |> Map.drop([:id, :fingerprint, :created_at])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = task) do
    errors = []
    errors = if is_nil(task.task_type), do: [{:task_type, :required} | errors], else: errors
    errors = if is_nil(task.owner), do: [{:owner, :required} | errors], else: errors
    errors = if task.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
