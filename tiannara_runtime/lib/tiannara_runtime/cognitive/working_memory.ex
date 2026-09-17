defmodule TiannaraRuntime.Cognitive.WorkingMemory do
  @moduledoc "Phase 18.1 — Immutable working memory struct"
  defstruct [:id, :context, :active_tasks, :active_goals, :attention, :capacity, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.1"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      context: fields.context,
      active_tasks: fields.active_tasks || [],
      active_goals: fields.active_goals || [],
      attention: fields.attention,
      capacity: fields.capacity,
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: fields.migration_version || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields.context}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "wm_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = wm) do
    canonical =
      wm
      |> Map.drop([:id, :fingerprint, :created_at])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = wm) do
    errors = []
    errors = if is_nil(wm.context), do: [{:context, :required} | errors], else: errors
    errors = if wm.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
