defmodule TiannaraRuntime.Cognitive.EvidenceReference do
  @moduledoc "Phase 18.1 — Immutable evidence reference struct"
  defstruct [:id, :ledger, :hash, :origin, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.1"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      ledger: fields.ledger,
      hash: fields.hash,
      origin: fields.origin,
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase,
      migration_version: fields.migration_version || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields.ledger}_#{fields.hash}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "evr_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = ref) do
    canonical =
      ref
      |> Map.drop([:id, :fingerprint, :created_at])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = ref) do
    errors = []
    errors = if is_nil(ref.ledger), do: [{:ledger, :required} | errors], else: errors
    errors = if is_nil(ref.hash), do: [{:hash, :required} | errors], else: errors
    errors = if ref.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end
end
