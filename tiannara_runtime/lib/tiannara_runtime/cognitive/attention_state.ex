defmodule TiannaraRuntime.Cognitive.AttentionState do
  @moduledoc "Phase 18.1 — Immutable attention state struct"
  defstruct [:id, :allocation, :priority_queue, :resource_usage, :constraints, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.1"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      allocation: fields.allocation || %{},
      priority_queue: fields.priority_queue || [],
      resource_usage: fields.resource_usage || %{},
      constraints: fields.constraints || [],
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: fields.migration_version || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(_fields) do
    hash = :crypto.hash(:sha256, "#{:erlang.unique_integer([:positive])}") |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "as_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = state) do
    canonical =
      state
      |> Map.drop([:id, :fingerprint, :created_at])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = state) do
    errors = []
    errors = if state.allocation == %{}, do: [{:allocation, :empty} | errors], else: errors
    errors = if state.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
